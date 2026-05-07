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
    // Handle new Arduino data structure
    Map<String, int> soilMoistureMap = {};
    
    if (json['soil_moisture'] is Map) {
      final soilData = json['soil_moisture'] as Map<dynamic, dynamic>;
      soilData.forEach((key, value) {
        // Convert node_1 to Node_1
        String nodeId = key.toString().replaceFirst('node_', 'Node_');
        soilMoistureMap[nodeId] = (value as int?) ?? 0;
      });
    }
    
    return SensorData(
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      soilMoisture: soilMoistureMap,
      timestamp: DateTime.now(),
    );
  }

  int getNodeMoisture(String node) => soilMoisture[node] ?? 0;

  List<String> getNodes() => soilMoisture.keys.toList();

  String getNodeCondition(String node) {
    int moisture = getNodeMoisture(node);
    if (moisture > 80) return 'Saturated';
    if (moisture > 40) return 'Optimal';
    return 'Dry';
  }
}