import 'dart:convert';

class RecommendationHistoryEntry {
  final String name;
  final String scientificName;
  final String? reason;
  final DateTime dateRecommended;
  final int moisture;
  final double ph;
  final String moistureStatus;
  final double temperature;
  final double humidity;

  RecommendationHistoryEntry({
    required this.name,
    required this.scientificName,
    this.reason,
    required this.dateRecommended,
    required this.moisture,
    required this.ph,
    required this.moistureStatus,
    required this.temperature,
    required this.humidity,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'scientificName': scientificName,
    if (reason != null) 'reason': reason,
    'dateRecommended': dateRecommended.toIso8601String(),
    'moisture': moisture,
    'ph': ph,
    'moistureStatus': moistureStatus,
    'temperature': temperature,
    'humidity': humidity,
  };

  factory RecommendationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RecommendationHistoryEntry(
      name: json['name'],
      scientificName: json['scientificName'],
      reason: json['reason'],
      dateRecommended: DateTime.parse(json['dateRecommended']),
      moisture: json['moisture'],
      ph: json['ph']?.toDouble() ?? 7.0,
      moistureStatus: json['moistureStatus'],
      temperature: json['temperature']?.toDouble() ?? 0,
      humidity: json['humidity']?.toDouble() ?? 0,
    );
  }
}