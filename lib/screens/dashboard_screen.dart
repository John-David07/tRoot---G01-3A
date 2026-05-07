import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/sensor_data.dart';
import '../widgets/independent_sensor_carousel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/ai_recommendations_widget.dart';
import '../utils/theme_manager.dart';
import 'sensors_hub_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardCarousel(),
    const SensorsHubScreen(),
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

class DashboardCarousel extends StatefulWidget {
  const DashboardCarousel({super.key});

  @override
  State<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<DashboardCarousel> {
  final DatabaseService _dbService = DatabaseService();
  
  List<String> _nodes = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData>(
      stream: _dbService.getCurrentData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('No sensor data available'));
        }

        final data = snapshot.data!;
        
        _nodes = data.getNodes()..sort((a, b) {
          int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
          int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
          return numA.compareTo(numB);
        });

        if (_nodes.isEmpty) {
          return const Center(child: Text('No sensors found'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSmartInsightCard(data),
              IndependentSensorCarousel(),
              const SizedBox(height: 24),
              const AiRecommendationsWidget(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartInsightCard(SensorData data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Smart Insight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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