class SensorData {
  final double humidity;
  final double temperature;
  final Map<String, int> soilMoisture;
  final DateTime timestamp;

  SensorData({
    required this.humidity,
    required this.temperature,
    required this.soilMoisture,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    return SensorData(
      humidity: (json['Humidity'] ?? 0.0).toDouble(),
      temperature: (json['Temperature'] ?? 0.0).toDouble(),
      soilMoisture: Map<String, int>.from(json['Soil_Moisture'] ?? {}),
      timestamp: DateTime.now(),
    );
  }

  int getNodeMoisture(String node) => soilMoisture[node] ?? 0;

  List<String> getNodes() => soilMoisture.keys.toList();

  // Remove Critical - only Wet, Optimal, Dry
  String getNodeCondition(String node) {
    int moisture = getNodeMoisture(node);
    if (moisture > 80) return 'Wet';
    if (moisture > 40) return 'Optimal';
    return 'Dry';
  }
}