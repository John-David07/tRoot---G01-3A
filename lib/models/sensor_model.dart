class SensorData {
  final double humidity;
  final double temperature;
  final Map<String, int> soilMoisture;  // Changed from double to Map
  final DateTime timestamp;

  SensorData({
    required this.humidity,
    required this.temperature,
    required this.soilMoisture,
    required this.timestamp,
  });

  factory SensorData.fromCurrentData(Map<dynamic, dynamic> json) {
    return SensorData(
      humidity: (json['Humidity'] ?? 0.0).toDouble(),
      temperature: (json['Temperature'] ?? 0.0).toDouble(),
      soilMoisture: Map<String, int>.from(json['Soil_Moisture'] ?? {}),  // Parse the map
      timestamp: DateTime.now(),
    );
  }

  // Get moisture for a specific node
  int getNodeMoisture(String node) {
    return soilMoisture[node] ?? 0;
  }

  // Get all nodes
  List<String> getNodes() {
    return soilMoisture.keys.toList();
  }

  // Determine condition for a specific node
  String getNodeCondition(String node) {
    int moisture = getNodeMoisture(node);
    if (moisture > 80) return 'Saturated';
    if (moisture > 40) return 'Optimal';
    if (moisture > 10) return 'Dry';
    return 'Critical';
  }

  // Average soil moisture (if needed)
  double get averageSoilMoisture {
    if (soilMoisture.isEmpty) return 0;
    int sum = soilMoisture.values.reduce((a, b) => a + b);
    return sum / soilMoisture.length;
  }
}