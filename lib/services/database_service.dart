import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get real-time current sensor data
  Stream<SensorData> getCurrentData() {
    return _db.child('CurrentData').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return SensorData.fromJson(data);
    });
  }

  // Get all soil moisture nodes
  Stream<Map<String, int>> getSoilData() {
    return _db.child('CurrentData/soil_moisture').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final Map<String, int> result = {};
      data.forEach((key, value) {
        // Convert node_1 to Node_1 for consistency
        String nodeId = key.toString().replaceFirst('node_', 'Node_');
        result[nodeId] = (value as int?) ?? 0;
      });
      return result;
    });
  }

  // Get historical data for a specific sensor
  Future<List<Map<String, dynamic>>> getHistoryForSensor(String nodeId) async {
    // Convert Node_1 to node_1 for Firebase path
    final firebaseNodeId = nodeId.toLowerCase().replaceFirst('node_', 'node_');
    final historyRef = _db.child('History/soil_sensor/$firebaseNodeId');
    final snapshot = await historyRef.get();
    
    if (!snapshot.exists) return [];
    
    final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
    final List<Map<String, dynamic>> history = [];
    
    data.forEach((pushId, entry) {
      if (entry is Map && entry.containsKey('value') && entry.containsKey('time')) {
        history.add({
          'moisture': entry['value'],
          'timestamp': entry['time'],
          'pushId': pushId,
        });
      }
    });
    
    // Sort by timestamp (newest first)
    history.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    return history;
  }
}