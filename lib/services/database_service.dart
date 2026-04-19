import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get real-time current sensor data
  Stream<SensorData> getCurrentData() {
    return _db.child('Current_Data').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return SensorData.fromJson(data);
    });
  }

  // Get all soil moisture nodes
  Stream<Map<String, int>> getSoilData() {
    return _db.child('Current_Data/Soil_Moisture').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return Map<String, int>.from(data);
    });
  }

  // Get historical data for a specific sensor
  Future<List<Map<String, dynamic>>> getHistoryForSensor(String nodeId) async {
    final historyRef = _db.child('History/Soil_Sensor/$nodeId');
    final snapshot = await historyRef.get();
    
    if (!snapshot.exists) return [];
    
    final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
    final List<Map<String, dynamic>> history = [];
    
    data.forEach((pushId, value) {
      int moistureValue = 0;
      if (value is int) {
        moistureValue = value;
      } else if (value is Map && value.containsKey('value')) {
        moistureValue = value['value'];
      }
      
      // Parse timestamp from pushId
      DateTime timestamp = DateTime.now();
      if (pushId.toString().length >= 8) {
        final hexPart = pushId.toString().substring(1, 9);
        try {
          final timeValue = int.parse(hexPart, radix: 16);
          if (timeValue > 1000000) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(timeValue);
          }
        } catch (e) {}
      }
      
      history.add({
        'moisture': moistureValue,
        'timestamp': timestamp,
        'pushId': pushId,
      });
    });
    
    // Sort by timestamp (newest first)
    history.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    return history;
  }
}