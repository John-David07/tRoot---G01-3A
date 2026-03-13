import 'package:flutter/material.dart';
import 'package:plant_monitoring_system/services/sensor_service.dart';
import 'package:plant_monitoring_system/models/sensor_model.dart';
import 'package:plant_monitoring_system/models/plant_recommendation.dart';
import 'package:plant_monitoring_system/widgets/sensor_card.dart';
import 'package:plant_monitoring_system/widgets/recommendation_card.dart';
import 'package:provider/provider.dart';
import 'package:plant_monitoring_system/providers/theme_provider.dart';

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
    stream: _sensorService.getCurrentData(),  // Changed from getAtmosphereData
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
            
            // Main Sensor Card (Living Room)
            Column(
              children: data.getNodes().map((node) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SensorCard(
                    title: 'SENSOR - ${node.replaceAll('_', ' ')}',
                    soilMoisture: data.soilMoisture,
                    temperature: data.temperature,
                    humidity: data.humidity,
                    node: node,
                  ),
                );
              }).toList(),
            ),

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
  return StreamBuilder<SensorData>(
    stream: _sensorService.getCurrentData(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final data = snapshot.data!;
      final nodes = data.getNodes();
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'All Sensors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text('Monitoring ${nodes.length} active sensors'),
          const SizedBox(height: 16),
          ...nodes.map((node) {
            int moisture = data.getNodeMoisture(node);
            String condition = data.getNodeCondition(node);
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: condition == 'Optimal' ? Colors.green :
                               condition == 'Wet' ? Colors.blue : 
                               condition == 'Dry' ? Colors.orange : Colors.red,
                radius: 8,
              ),
              title: Text(node.replaceAll('_', ' ')),
              trailing: Text(
                '$moisture% - $condition',
                style: TextStyle(
                  color: condition == 'Optimal' ? Colors.green :
                         condition == 'Wet' ? Colors.blue :
                         condition == 'Dry' ? Colors.orange : Colors.red,
                ),
              ),
            );
          }).toList(),
        ],
      );
    },
  );
}

Widget _buildHistoryTab() {
  return StreamBuilder<List<SensorData>>(
    stream: _sensorService.getHistoricalData(),
    builder: (context, snapshot) {
      final history = snapshot.data ?? [];
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'All Sensors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text('${history.length} historical records'),
          const SizedBox(height: 16),
          ...history.map((data) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Sensor Reading'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data.timestamp}'),
                    Text('Humidity: ${data.humidity.toStringAsFixed(1)}% • Temperature: ${data.temperature.toStringAsFixed(1)}°C'),
                    ...data.getNodes().map((node) => 
                      Text('  $node: ${data.getNodeMoisture(node)}%')
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    },
  );
}

Widget _buildSettingsTab() {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Toggle
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(themeProvider.isDarkMode ? 'Dark' : 'Light'),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ],
            ),
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
              _showResetDialog(context);
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
    },
  );
}

void _showResetDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset Data'),
      content: const Text('Are you sure you want to clear all local storage and sensor logs?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Implement reset logic here
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data reset completed')),
            );
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
}
}