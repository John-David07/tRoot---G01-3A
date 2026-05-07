import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // In-memory AI recommendation cache (by condition key)
  final Map<String, List<Map<String, dynamic>>> _aiCache = {};
  
  // Track last fetched moisture for deadband
  final Map<String, int> _lastFetchedMoisture = {};

  // Soil cache keys
  static const String _soilImageKeyPrefix = 'soil_image_';
  static const String _soilInfoKeyPrefix = 'soil_info_';

  Future<void> clearAllCache() async {
    // Clear in-memory AI cache
    _aiCache.clear();
    _lastFetchedMoisture.clear();
    
    // Clear persisted soil cache from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.startsWith(_soilImageKeyPrefix) || key.startsWith(_soilInfoKeyPrefix)) {
        await prefs.remove(key);
      }
    }
    
    print('🧹 All cache cleared (AI recommendations + soil data)');
  }

  // AI Cache methods
  String _getConditionKey(int moisture, double temperature, double humidity) {
    int roundedMoisture = ((moisture + 5) / 10).floor() * 10;
    int roundedTemp = temperature.round();
    int roundedHumidity = ((humidity + 5) / 10).floor() * 10;
    return '${roundedMoisture}_${roundedTemp}_${roundedHumidity}';
  }

  bool hasAiCache(int moisture, double temperature, double humidity) {
    final key = _getConditionKey(moisture, temperature, humidity);
    return _aiCache.containsKey(key);
  }

  List<Map<String, dynamic>>? getAiCache(int moisture, double temperature, double humidity) {
    final key = _getConditionKey(moisture, temperature, humidity);
    return _aiCache[key];
  }

  void setAiCache(int moisture, double temperature, double humidity, List<Map<String, dynamic>> recommendations) {
    final key = _getConditionKey(moisture, temperature, humidity);
    _aiCache[key] = recommendations;
  }

  bool shouldSkipDueToDeadband(String sensorId, int currentMoisture) {
    final lastMoisture = _lastFetchedMoisture[sensorId];
    if (lastMoisture == null) return false;
    return (currentMoisture - lastMoisture).abs() < 10;
  }

  void updateLastFetchedMoisture(String sensorId, int moisture) {
    _lastFetchedMoisture[sensorId] = moisture;
  }

  // Soil Cache methods
  Future<void> saveSoilImage(String nodeId, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_soilImageKeyPrefix}${nodeId}', imagePath);
  }

  Future<String?> getSoilImage(String nodeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_soilImageKeyPrefix}${nodeId}');
  }

  Future<void> saveSoilInfo(String nodeId, Map<String, String> soilInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_soilInfoKeyPrefix}${nodeId}', json.encode(soilInfo));
  }

  Future<Map<String, String>?> getSoilInfo(String nodeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_soilInfoKeyPrefix}${nodeId}');
    if (data != null) {
      return Map<String, String>.from(json.decode(data));
    }
    return null;
  }
}