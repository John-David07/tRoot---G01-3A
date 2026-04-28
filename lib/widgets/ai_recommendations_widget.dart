import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/sensor_change_service.dart';
import '../models/sensor_data.dart';
import 'recommendation_carousel.dart';
import '../utils/theme_manager.dart';

class AiRecommendationsWidget extends StatefulWidget {
  const AiRecommendationsWidget({super.key});

  @override
  State<AiRecommendationsWidget> createState() => _AiRecommendationsWidgetState();
}

class _AiRecommendationsWidgetState extends State<AiRecommendationsWidget> {
  final DatabaseService _dbService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  
  int _currentSensorIndex = 0;
  List<String> _nodes = [];
  SensorData? _sensorData;
  
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  
  late StreamSubscription _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _sensorSubscription = SensorChangeService.sensorChanges.listen((index) {
      print('📡 AI WIDGET: Received sensor change: $index');
      if (_currentSensorIndex != index) {
        print('📡 AI WIDGET: Loading new recommendations for sensor $index');
        _currentSensorIndex = index;
        _loadRecommendations();
      }
    });
    _loadSensorData();
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    super.dispose();
  }

  void _loadSensorData() {
    _dbService.getCurrentData().listen((data) {
      if (mounted) {
        setState(() {
          _sensorData = data;
          _nodes = data.getNodes()..sort((a, b) {
            int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
            int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
            return numA.compareTo(numB);
          });
        });
        _loadRecommendations();
      }
    });
  }

  Future<void> _loadRecommendations() async {
    if (_sensorData == null || _nodes.isEmpty) return;
    
    final sensorId = _nodes[_currentSensorIndex];
    final currentMoisture = _sensorData!.getNodeMoisture(sensorId);
    print('📡 AI WIDGET: Loading for $sensorId with moisture $currentMoisture%');
    
    if (_cache.containsKey(sensorId)) {
      print('📡 AI WIDGET: Using CACHED recommendations for $sensorId');
      setState(() {
        _recommendations = _cache[sensorId]!;
        _isLoading = false;
      });
      return;
    }
    
    print('📡 AI WIDGET: Fetching NEW recommendations for $sensorId');
    setState(() => _isLoading = true);
    
    final recommendations = await _geminiService.getRecommendations(
      moisture: currentMoisture,
      temperature: _sensorData!.temperature,
      humidity: _sensorData!.humidity,
    );
    
    if (mounted) {
      _cache[sensorId] = recommendations;
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
          ),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('AI is analyzing conditions...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
          ),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No recommendations available')),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RecommendationCarousel(recommendations: _recommendations),
    );
  }
}