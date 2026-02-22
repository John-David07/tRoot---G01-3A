class Plant {
  final String id;
  final String name;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final DateTime lastUpdated;
  final String? condition; // e.g., 'Healthy', 'Too Dry'

  Plant({
    required this.id,
    required this.name,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.lastUpdated,
    this.condition,
  });

  // Factory method to create a Plant object from Firebase data (JSON)
  factory Plant.fromJson(String id, Map<dynamic, dynamic> json) {
    return Plant(
      id: id,
      name: json['name'] ?? 'Unnamed Plant',
      soilMoisture: (json['soilMoisture'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      condition: json['condition'],
    );
  }

  // Method to convert a Plant object back to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': lastUpdated.millisecondsSinceEpoch,
      'condition': condition,
    };
  }
}