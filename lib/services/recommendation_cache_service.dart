import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecommendationCacheService {
  static const String _cacheKeyPrefix = 'rec_cache_';
  static const String _imageCacheKeyPrefix = 'plant_image_';
  static const Duration cacheDuration = Duration(minutes: 30);
  
  // Save recommendations to cache
  Future<void> cacheRecommendations({
    required String sensorId,
    required int moisture,
    required double ph,
    required double temperature,
    required double humidity,
    required List<Map<String, dynamic>> recommendations,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _generateCacheKey(sensorId, moisture, ph, temperature, humidity);
    
    await prefs.setString(_cacheKeyPrefix + cacheKey, json.encode({
      'data': recommendations,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }
  
  // Get cached recommendations
  Future<List<Map<String, dynamic>>?> getCachedRecommendations({
    required String sensorId,
    required int moisture,
    required double ph,
    required double temperature,
    required double humidity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _generateCacheKey(sensorId, moisture, ph, temperature, humidity);
    
    final cached = prefs.getString(_cacheKeyPrefix + cacheKey);
    if (cached == null) return null;
    
    try {
      final data = json.decode(cached);
      final timestamp = data['timestamp'] as int;
      final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
      
      if (elapsed > cacheDuration.inMilliseconds) {
        // Cache expired
        await prefs.remove(_cacheKeyPrefix + cacheKey);
        return null;
      }
      
      final recommendations = data['data'] as List;
      return recommendations.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading cached recommendations: $e');
      return null;
    }
  }
  
  // Cache plant image
  Future<void> cachePlantImage(String plantName, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageCacheKeyPrefix + plantName, imageUrl);
  }
  
  // Get cached plant image
  Future<String?> getCachedPlantImage(String plantName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imageCacheKeyPrefix + plantName);
  }
  
  // Clear all cache for a sensor
  Future<void> clearSensorCache(String sensorId) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.startsWith(_cacheKeyPrefix) && key.contains(sensorId)) {
        await prefs.remove(key);
      }
    }
  }
  
  // Clear all cache
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.startsWith(_cacheKeyPrefix) || key.startsWith(_imageCacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
  
  String _generateCacheKey(String sensorId, int moisture, double ph, double temperature, double humidity) {
    final roundedMoisture = (moisture / 10).round() * 10;
    final roundedTemp = temperature.round();
    final roundedHumidity = (humidity / 10).round() * 10;
    final roundedPh = (ph * 2).round() / 2;
    return '${sensorId}_${roundedMoisture}_${roundedPh}_${roundedTemp}_${roundedHumidity}';
  }
}