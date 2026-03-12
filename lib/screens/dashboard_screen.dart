import 'package:flutter/material.dart';
import 'package:plant_monitoring_system/services/sensor_service.dart';
import 'package:plant_monitoring_system/models/sensor_model.dart';
import 'package:plant_monitoring_system/models/plant_recommendation.dart';
import 'package:plant_monitoring_system/widgets/sensor_card.dart';
import 'package:plant_monitoring_system/widgets/recommendation_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SensorService _sensorService = SensorService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildSensorsTab(),
          _buildHistoryTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder<SensorData>(
      stream: _sensorService.getAtmosphereData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final recommendations = PlantRecommendation.getRecommendations(data.humidity);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Smart Insight Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Insight',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Optimal for Growth: Current conditions are perfect for tropical varieties. No action needed.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sensor 1 Card (Living Room)
              SensorCard(
                title: 'SENSOR 1 - LIVING ROOM',
                moisture: data.getSoilMoisture('Node1'),
                temperature: data.temperature,
                humidity: data.humidity,
                condition: data.getCondition('Node1'),
              ),
              const SizedBox(height: 24),

              // Plant Recommendations
              const Text(
                'PLANT RECOMMENDATIONS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...recommendations.map((plant) => RecommendationCard(plant: plant)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorsTab() {
    return StreamBuilder<Map<String, int>>(
      stream: _sensorService.getSoilData(),
      builder: (context, snapshot) {
        final soilData = snapshot.data ?? {};
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'All Sensors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Monitoring 5 active samples'),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              String nodeKey = 'Node${index + 1}';
              int moisture = soilData[nodeKey] ?? 0;
              String condition;
              if (moisture > 80) condition = 'Wet';
              else if (moisture > 40) condition = 'Optimal';
              else condition = 'Dry';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: condition == 'Optimal' ? Colors.green :
                                 condition == 'Wet' ? Colors.blue : Colors.orange,
                  radius: 8,
                ),
                title: Text('Sensor ${index + 1}'),
                trailing: Text(
                  condition,
                  style: TextStyle(
                    color: condition == 'Optimal' ? Colors.green :
                           condition == 'Wet' ? Colors.blue : Colors.orange,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    // Implement history view based on your groupmate's data structure
    return const Center(child: Text('History Tab - Implement based on actual historical data'));
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.brightness_6),
          title: Text('Theme Mode'),
          trailing: Text('Dark'),
        ),
        const ListTile(
          leading: Icon(Icons.refresh),
          title: Text('Data Refresh Rate'),
          trailing: Text('15 min'),
        ),
        const ListTile(
          leading: Icon(Icons.tune),
          title: Text('Calibration'),
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Reset Data'),
          subtitle: const Text('Clear all local storage and sensor logs.'),
          onTap: () {
            // Show confirmation dialog
          },
        ),
        const Divider(),
        const ListTile(
          title: Text('System Info'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Firmware Version: v2.4.12-stable'),
              Text('Hardware ID: EG-SENS-8842-X'),
              Text('Network Status: Connected'),
            ],
          ),
        ),
      ],
    );
  }
}