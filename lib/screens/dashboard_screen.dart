import 'package:flutter/material.dart';
import 'package:plant_monitoring_system/models/plant.dart';
import 'package:plant_monitoring_system/services/database_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // 1. Create an instance of your database service
  DatabaseService get _databaseService => DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Monitoring Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      // 2. Use a StreamBuilder to listen to the real-time data stream
      body: StreamBuilder<List<Plant>>(
        stream: _databaseService.getPlants(),
        builder: (context, snapshot) {
          // 3. Handle different connection states
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No plants found. Add your first plant!'));
          }

          // 4. Data is available! Build the list of plants.
          final plants = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              // Determine condition-based color for visual alert
              Color statusColor = Colors.green;
              if (plant.condition == 'Too Dry') {
                statusColor = Colors.red;
              } else if (plant.condition == 'Low Moisture') {
                statusColor = Colors.orange;
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plant.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              plant.condition ?? 'Unknown',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorIndicator('💧', 'Soil', '${plant.soilMoisture}%'),
                          _buildSensorIndicator('🌡️', 'Temp', '${plant.temperature}°C'),
                          _buildSensorIndicator('💨', 'Humidity', '${plant.humidity}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${_formatDate(plant.lastUpdated)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget for sensor readings
  Widget _buildSensorIndicator(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Helper function to format the timestamp
  static String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}/${date.year}';
  }
}