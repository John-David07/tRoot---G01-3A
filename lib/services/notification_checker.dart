import '../models/notification_model.dart';
import '../models/sensor_data.dart';
import 'notification_service.dart';
import 'database_service.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationChecker {
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _dbService = DatabaseService();
  
  // Track last check per sensor to avoid duplicate notifications
  final Map<String, DateTime> _lastDryPatternNotification = {};
  final Map<String, List<int>> _moistureHistory = {};
  
  Future<void> checkAllNotifications(SensorData data) async {
    final nodes = data.getNodes();
    
    for (var nodeId in nodes) {
      final moisture = data.getNodeMoisture(nodeId);
      final nodeName = nodeId.replaceAll('Node_', 'Plant ');
      
      // Check for dry pattern (3 days of dryness)
      await _checkDryPattern(nodeId, nodeName, moisture);
    }
    
    // Check for weekly check-in (every 7 days)
    await _checkWeeklyCheckIn();
  }
  
  Future<void> _checkDryPattern(String nodeId, String nodeName, int currentMoisture) async {
    // Initialize history for this sensor
    if (!_moistureHistory.containsKey(nodeId)) {
      _moistureHistory[nodeId] = [];
    }
    
    // Add current moisture to history
    _moistureHistory[nodeId]!.add(currentMoisture);
    
    // Keep only last 10 readings (approximate 3 days if reading every 6-8 hours)
    if (_moistureHistory[nodeId]!.length > 10) {
      _moistureHistory[nodeId]!.removeAt(0);
    }
    
    // Check if all recent readings are dry (< 40%)
    final isDry = currentMoisture < 40;
    final recentDryCount = _moistureHistory[nodeId]!.where((m) => m < 40).length;
    final consecutiveDry = recentDryCount >= 3 && _moistureHistory[nodeId]!.length >= 3;
    
    if (isDry && consecutiveDry) {
      // Check if we already sent a notification for this pattern recently
      final lastSent = _lastDryPatternNotification[nodeId];
      if (lastSent == null || DateTime.now().difference(lastSent).inDays >= 1) {
        _lastDryPatternNotification[nodeId] = DateTime.now();
        
        final notification = AppNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_$nodeId',
          title: '⚠️ Dry Pattern Detected',
          message: '$nodeName has been dry for ${recentDryCount} days in a row. Time to water!',
          sensorId: nodeId,
          sensorName: nodeName,
          timestamp: DateTime.now(),
          type: 'dry_pattern',
        );
        
        await _notificationService.addNotification(notification);
      }
    }
  }
  
  Future<void> _checkWeeklyCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    const lastCheckInKey = 'last_weekly_checkin';
    
    final lastCheckInStr = prefs.getString(lastCheckInKey);
    DateTime? lastCheckIn;
    
    if (lastCheckInStr != null) {
      lastCheckIn = DateTime.parse(lastCheckInStr);
    }
    
    final now = DateTime.now();
    
    // If no check-in recorded or it's been 7+ days
    if (lastCheckIn == null || now.difference(lastCheckIn).inDays >= 7) {
      await prefs.setString(lastCheckInKey, now.toIso8601String());
      
      final notification = AppNotification(
        id: 'weekly_${now.millisecondsSinceEpoch}',
        title: '🌱 Weekly Plant Check',
        message: 'Time to check on your plants! Review moisture levels and plant health.',
        sensorId: 'all',
        sensorName: 'All Plants',
        timestamp: now,
        type: 'weekly_checkin',
      );
      
      await _notificationService.addNotification(notification);
    }
  }
  
  // Call this when app starts and when sensor data updates
  Future<void> initializeAndCheck() async {
    _dbService.getCurrentData().listen((data) async {  // Add async here
      await checkAllNotifications(data);  // Add await here
    });
  }
}