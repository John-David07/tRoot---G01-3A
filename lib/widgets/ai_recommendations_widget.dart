import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/sensor_change_service.dart';
import '../services/cache_service.dart';
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
  final CacheService _cacheService = CacheService();
  
  int _currentSensorIndex = 0;
  List<String> _nodes = [];
  SensorData? _sensorData;
  
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  
  late StreamSubscription _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _sensorSubscription = SensorChangeService.sensorChanges.listen((index) {
      if (_currentSensorIndex != index) {
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
    final currentTemp = _sensorData!.temperature;
    final currentHumidity = _sensorData!.humidity;
    
    // Check condition-based cache first
    if (_cacheService.hasAiCache(currentMoisture, currentTemp, currentHumidity)) {
      setState(() {
        _recommendations = _cacheService.getAiCache(currentMoisture, currentTemp, currentHumidity)!;
        _isLoading = false;
      });
      return;
    }
    
    // Deadband check
    if (_cacheService.shouldSkipDueToDeadband(sensorId, currentMoisture)) {
      print('📡 Deadband ignored: moisture change less than 10%');
      return;
    }
    
    // Update last fetched moisture
    _cacheService.updateLastFetchedMoisture(sensorId, currentMoisture);
    
    setState(() => _isLoading = true);
    
    final recommendations = await _geminiService.getRecommendations(
      moisture: currentMoisture,
      temperature: currentTemp,
      humidity: currentHumidity,
    );
    
    if (mounted) {
      // Store in cache
      _cacheService.setAiCache(currentMoisture, currentTemp, currentHumidity, recommendations);
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