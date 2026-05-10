import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/sensor_change_service.dart';
import '../services/cache_service.dart';
import '../services/recommendation_history_service.dart';
import '../models/sensor_data.dart';
import '../models/recommendation_history.dart';
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
  final RecommendationHistoryService _historyService = RecommendationHistoryService();
  
  int _currentSensorIndex = 0;
  List<String> _nodes = [];
  SensorData? _sensorData;
  
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  
  // Debouncer timer
  Timer? _debounceTimer;
  
  late StreamSubscription _sensorSubscription;
  late StreamSubscription _dataSubscription;

  @override
  void initState() {
    super.initState();
    _sensorSubscription = SensorChangeService.sensorChanges.listen((index) {
      if (_currentSensorIndex != index) {
        _currentSensorIndex = index;
        _debouncedLoadRecommendations();
      }
    });
    _loadSensorData();
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    _dataSubscription.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadSensorData() {
    _dataSubscription = _dbService.getCurrentData().listen((data) {
      if (mounted) {
        setState(() {
          _sensorData = data;
          _nodes = data.getNodes()..sort((a, b) {
            int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
            int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
            return numA.compareTo(numB);
          });
        });
        _debouncedLoadRecommendations();
      }
    });
  }

  void _debouncedLoadRecommendations() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadRecommendations();
    });
  }

  String _getMoistureStatus(int moisture) {
    if (moisture > 80) return 'Saturated';
    if (moisture > 40) return 'Optimal';
    return 'Dry';
  }

  // Helper method to check if recommendations are fallbacks - MUST be declared BEFORE it's used
  bool _isFallbackRecommendation(List<Map<String, dynamic>> recommendations) {
    if (recommendations.isEmpty) return true;
    
    final fallbackNames = ['Snake Plant', 'ZZ Plant', 'Pothos'];
    
    for (var rec in recommendations) {
      final name = rec['name'] ?? '';
      if (!fallbackNames.contains(name)) {
        return false; // Found a non-fallback plant
      }
    }
    
    return true; // All plants are from the fallback list
  }

  Future<void> _recordToHistoryIfNeeded(String sensorId, int moisture, double temp, double humidity, List<Map<String, dynamic>> recommendations) async {
    if (recommendations.isEmpty) return;
    
    // Don't record fallback recommendations
    if (_isFallbackRecommendation(recommendations)) {
      print('📝 Skipping fallback recommendations from history');
      return;
    }
    
    final moistureStatus = _getMoistureStatus(moisture);
    
    for (var rec in recommendations) {
      final entry = RecommendationHistoryEntry(
        name: rec['name'] ?? 'Unknown Plant',
        scientificName: rec['scientificName'] ?? '',
        reason: rec['reason'] ?? '',
        dateRecommended: DateTime.now(),
        moisture: moisture,
        moistureStatus: moistureStatus,
        temperature: temp,
        humidity: humidity,
      );
      // The service will handle duplicate detection
      await _historyService.addHistoryEntry(sensorId, entry);
    }
  }

  Future<void> _loadRecommendations() async {
    if (_sensorData == null || _nodes.isEmpty) return;
    
    final sensorId = _nodes[_currentSensorIndex];
    final currentMoisture = _sensorData!.getNodeMoisture(sensorId);
    final currentTemp = _sensorData!.temperature;
    final currentHumidity = _sensorData!.humidity;
    
    // Check condition-based cache first
    if (_cacheService.hasAiCache(currentMoisture, currentTemp, currentHumidity)) {
      final cachedRecs = _cacheService.getAiCache(currentMoisture, currentTemp, currentHumidity)!;
      
      if (_recommendations != cachedRecs) {
        setState(() {
          _recommendations = cachedRecs;
        });
      }
      
      // Record to history if not fallback (service will handle duplicate detection)
      await _recordToHistoryIfNeeded(sensorId, currentMoisture, currentTemp, currentHumidity, cachedRecs);
      
      setState(() => _isLoading = false);
      return;
    }
    
    // Deadband check - only fetch from API if moisture changed significantly
    if (_cacheService.shouldSkipDueToDeadband(sensorId, currentMoisture)) {
      print('📡 Deadband ignored: moisture change less than 10%');
      return;
    }
    
    // Update last fetched moisture
    _cacheService.updateLastFetchedMoisture(sensorId, currentMoisture);
    
    setState(() => _isLoading = true);
    
    // This is an ACTUAL API call
    final result = await _geminiService.getRecommendations(
      moisture: currentMoisture,
      temperature: currentTemp,
      humidity: currentHumidity,
    );
    
    if (mounted) {
      // Store in cache
      _cacheService.setAiCache(currentMoisture, currentTemp, currentHumidity, result.recommendations);
      setState(() {
        _recommendations = result.recommendations;
        _isLoading = false;
      });
      
      // Only record to history if it's NOT a fallback
      if (!result.isFallback) {
        await _recordToHistoryIfNeeded(sensorId, currentMoisture, currentTemp, currentHumidity, result.recommendations);
      } else {
        print('📝 Skipping fallback recommendations from history');
      }
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