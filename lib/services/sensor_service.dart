import 'package:firebase_database/firebase_database.dart';
import 'package:plant_monitoring_system/models/sensor_model.dart';

class SensorService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get real-time atmosphere data
  Stream<SensorData> getAtmosphereData() {
    return _db.child('Atmosphere').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return SensorData.fromJson(data);
    });
  }

  // Get soil node data
  Stream<Map<String, int>> getSoilData() {
    return _db.child('Soil').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return {
        'Node1': data['Node1'] ?? 0,
        'Node2': data['Node2'] ?? 0,
        'Node3': data['Node3'] ?? 0,
      };
    });
  }

  // For historical data (you'll need to implement if your ESP32 stores history)
  Future<List<SensorData>> getHistoricalData() async {
    // This depends on how your groupmate stores history
    // For now, returning empty list
    return [];
  }
}