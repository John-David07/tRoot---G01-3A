import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/sensor_data.dart';
import '../widgets/sensor_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/theme_manager.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final DatabaseService _dbService = DatabaseService();

  final List<Widget> _screens = [
    const DashboardContent(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return StreamBuilder<SensorData>(
      stream: dbService.getCurrentData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('No sensor data available'));
        }

        final data = snapshot.data!;
        final nodes = data.getNodes();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Smart Insight Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Insight',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeManager.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ThemeManager.primaryColor),
                        ),
                        child: Text(
                          _getSmartInsight(data.temperature, data.humidity),
                          style: TextStyle(color: ThemeManager.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sensor Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final nodeId = nodes[index];
                  return SensorCard(
                    nodeId: nodeId,
                    moisture: data.getNodeMoisture(nodeId),
                    temperature: data.temperature,
                    humidity: data.humidity,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSmartInsight(double temperature, double humidity) {
    if (temperature > 30) {
      return 'High temperature detected. Consider moving plants away from direct sunlight.';
    }
    if (humidity < 40) {
      return 'Low humidity. Consider misting your plants.';
    }
    return 'Optimal for Growth: Current conditions are perfect for tropical varieties. No action needed.';
  }
}