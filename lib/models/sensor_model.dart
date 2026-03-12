class SensorData {
  final double humidity;
  final double temperature;
  final Map<String, int> soilNodes;
  final DateTime timestamp;

  SensorData({
    required this.humidity,
    required this.temperature,
    required this.soilNodes,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    return SensorData(
      humidity: (json['Hum'] ?? 0.0).toDouble(),
      temperature: (json['Temp'] ?? 0.0).toDouble(),
      soilNodes: {
        'Node1': json['Node1'] ?? 0,
        'Node2': json['Node2'] ?? 0,
        'Node3': json['Node3'] ?? 0,
      },
      timestamp: DateTime.now(), // You'll need to add timestamp if not present
    );
  }

  // Get soil moisture for a specific node
  int getSoilMoisture(String node) => soilNodes[node] ?? 0;
  
  // Determine plant condition based on moisture
  String getCondition(String node) {
    int moisture = getSoilMoisture(node);
    if (moisture > 80) return 'Wet';
    if (moisture > 40) return 'Optimal';
    if (moisture > 10) return 'Dry';
    return 'Critical';
  }
}