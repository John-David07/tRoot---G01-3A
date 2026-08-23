import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/sensor_data.dart';
import '../widgets/independent_sensor_carousel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/plant_recommendation_chat.dart';
import '../utils/theme_manager.dart';
import 'sensors_hub_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../widgets/notification_bell.dart';
import '../services/notification_checker.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rootBg = isDarkMode
        ? const Color(0xFF101A24)
        : const Color(0xFFF5F7FA);
    return Scaffold(
      backgroundColor: rootBg,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/favicon.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.eco,
                  size: 28,
                  color: isDarkMode ? Colors.white : Colors.black87,
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Soil Monitor',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: const [
          NotificationBell(),
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
  late final NotificationChecker _notificationChecker;
  List<String> _nodes = [];
  int _currentCarouselIndex = 0;
  String? _currentNodeId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _notificationChecker = NotificationChecker();
    _notificationChecker.initializeAndCheck();
  }

  void _updateCurrentNode() {
    if (_nodes.isNotEmpty) {
      final newNodeId = _nodes[_currentCarouselIndex.clamp(0, _nodes.length - 1)];
      if (_currentNodeId != newNodeId) {
        setState(() {
          _currentNodeId = newNodeId;
        });
      }
    }
  }

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

        _nodes = data.getNodes()
          ..sort((a, b) {
            int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
            int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
            return numA.compareTo(numB);
          });

        if (_nodes.isEmpty) {
          return const Center(child: Text('No sensors found'));
        }

        // Ensure current index is valid
        if (_currentCarouselIndex >= _nodes.length) {
          _currentCarouselIndex = 0;
        }

        // Update current node
        final currentNodeId = _nodes[_currentCarouselIndex];
        
        // Only update if changed
        if (_currentNodeId != currentNodeId) {
          _currentNodeId = currentNodeId;
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSmartInsightCard(data),
              IndependentSensorCarousel(
                initialIndex: _currentCarouselIndex,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselIndex = index;
                    _currentNodeId = _nodes[index];
                  });
                },
                onNodeData: (nodeId, moisture, temp, humidity) {
                  // Optional: update if needed
                },
              ),
              const SizedBox(height: 24),
              if (_currentNodeId != null)
                PlantRecommendationChat(
                  key: ValueKey(_currentNodeId),
                  sensorId: _currentNodeId!,
                  defaultMoisture: data.getNodeMoisture(_currentNodeId!).toDouble(),
                  defaultTemperature: data.temperature,
                  defaultHumidity: data.humidity,
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartInsightCard(SensorData data) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
        ),
        color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
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