// lib/models/notification_model.dart

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String sensorId;
  final String sensorName;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'weekly_checkin', 'dry_pattern'

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.sensorId,
    required this.sensorName,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'sensorId': sensorId,
    'sensorName': sensorName,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'type': type,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      sensorId: json['sensorId'],
      sensorName: json['sensorName'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
      type: json['type'],
    );
  }
}