// lib/services/notification_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationService {
  static const String _notificationsKey = 'app_notifications';
  
  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notificationsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> addNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    
    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    
    await _saveNotifications(notifications);
  }
  
  Future<void> markAsRead(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = AppNotification(
        id: notifications[index].id,
        title: notifications[index].title,
        message: notifications[index].message,
        sensorId: notifications[index].sensorId,
        sensorName: notifications[index].sensorName,
        timestamp: notifications[index].timestamp,
        isRead: true,
        type: notifications[index].type,
      );
      await _saveNotifications(notifications);
    }
  }
  
  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updated = notifications.map((n) => AppNotification(
      id: n.id,
      title: n.title,
      message: n.message,
      sensorId: n.sensorId,
      sensorName: n.sensorName,
      timestamp: n.timestamp,
      isRead: true,
      type: n.type,
    )).toList();
    await _saveNotifications(updated);
  }
  
  Future<void> deleteNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == id);
    await _saveNotifications(notifications);
  }
  
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
  
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }
  
  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString(_notificationsKey, json.encode(jsonList));
  }
}