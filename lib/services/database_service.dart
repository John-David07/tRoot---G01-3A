import 'package:firebase_database/firebase_database.dart';
import 'package:plant_monitoring_system/models/plant.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get a stream of all plants from the 'plants' node in the database
  Stream<List<Plant>> getPlants() {
    return _db.child('plants').onValue.map((event) {
      final List<Plant> plants = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          // Use the factory method from our Plant model
          plants.add(Plant.fromJson(key.toString(), value));
        });
      }
      // Sort plants by name or last updated, etc.
      plants.sort((a, b) => a.name.compareTo(b.name));
      return plants;
    });
  }

  // Future to get a single plant's data (for historical trends later)
  Future<Plant?> getPlant(String plantId) async {
    final snapshot = await _db.child('plants/$plantId').get();
    if (snapshot.exists) {
      return Plant.fromJson(plantId, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  // Method to add a new plant (optional for your setup)
  Future<void> addPlant(Plant plant) {
    return _db.child('plants/${plant.id}').set(plant.toJson());
  }
}