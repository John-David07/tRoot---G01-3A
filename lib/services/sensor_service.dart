import 'package:firebase_database/firebase_database.dart';
import 'package:plant_monitoring_system/models/sensor_model.dart';

class SensorService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get current real-time data
Stream<SensorData> getCurrentData() {
  print('🔍 Listening to Current_Data...'); // Add this
  return _db.child('Current_Data').onValue.map((event) {
    print('📦 Data received: ${event.snapshot.value}'); // Add this
    final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
    print('📊 Parsed data: $data'); // Add this
    return SensorData.fromCurrentData(data);
  }).handleError((error) {
    print('❌ Error: $error'); // Add this
    throw error;
  });
}

  /*/ For multi-sensor support (since they only have one sensor in Current_Data)
  // We'll simulate multiple sensors using the same data for now
  Stream<List<SensorData>> getAllSensors() {
    return getCurrentData().map((currentData) {
      // Create 5 simulated sensors based on the real data
      return List.generate(5, (index) {
        // Add some variation to make each sensor look different
        double variation = (index * 5).toDouble();
        return SensorData(
          humidity: currentData.humidity + (index % 3),
          temperature: currentData.temperature + (index % 2),
          soilMoisture: (currentData.soilMoisture + variation) % 100,
          timestamp: DateTime.now(),
        );
      });
    });
  }
  */

  // Get historical data
Stream<List<SensorData>> getHistoricalData() {
  return _db.child('History').onValue.map((event) {
    final List<SensorData> history = [];
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    
    if (data != null) {
      data.forEach((key, value) {
        if (value is Map) {
          // You'll need to implement fromHistory based on your actual history structure
          // For now, return empty or implement based on your groupmate's history format
        }
      });
    }
    
    return history;
    });
  }
}