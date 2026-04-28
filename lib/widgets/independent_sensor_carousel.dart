import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sensor_change_service.dart';
import '../models/sensor_data.dart';
import '../utils/theme_manager.dart';

class IndependentSensorCarousel extends StatefulWidget {
  const IndependentSensorCarousel({super.key});

  @override
  State<IndependentSensorCarousel> createState() => _IndependentSensorCarouselState();
}

class _IndependentSensorCarouselState extends State<IndependentSensorCarousel> {
  final DatabaseService _dbService = DatabaseService();
  
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoCycleTimer;
  List<String> _nodes = [];
  SensorData? _sensorData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _autoCycleTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    _dbService.getCurrentData().listen((data) {
      if (mounted) {
        final newNodes = data.getNodes()..sort((a, b) {
          int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
          int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
          return numA.compareTo(numB);
        });
        
        setState(() {
          _sensorData = data;
          _nodes = newNodes;
        });
        
        _startAutoCycle();
      }
    });
  }

  void _startAutoCycle() {
    _autoCycleTimer?.cancel();
    if (_nodes.isNotEmpty) {
      _autoCycleTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
        if (mounted && _nodes.isNotEmpty && _pageController.hasClients) {
          final newIndex = (_currentIndex + 1) % _nodes.length;
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    print('🔄 CAROUSEL: Page changed to index $index (${_nodes[index]})');
    setState(() {
      _currentIndex = index;
    });
    // BROADCAST to service so recommendations widget can listen
    SensorChangeService.notifySensorChanged(index);
  }

  String _getCondition(int moisture) {
    if (moisture > 80) return 'Saturated';
    if (moisture > 40) return 'Optimal';
    return 'Dry';
  }

  Color _getConditionColor(int moisture) {
    if (moisture > 80) return Colors.blue;
    if (moisture > 40) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (_nodes.isEmpty || _sensorData == null) {
      return const SizedBox(
        height: 450,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 450,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _nodes.length,
            itemBuilder: (context, index) {
              final nodeId = _nodes[index];
              final moisture = _sensorData!.getNodeMoisture(nodeId);
              final condition = _getCondition(moisture);
              final color = _getConditionColor(moisture);

              return Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(nodeId.replaceAll('_', ' '), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Plant ${nodeId.replaceAll('Node_', '')}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: moisture / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                              Text(
                                '$moisture%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color),
                          ),
                          child: Text(condition, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Text('${_sensorData!.temperature.toInt()}°C', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text('Temp', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Text('${_sensorData!.humidity.toInt()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text('Humidity', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_nodes.length, (index) {
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? ThemeManager.primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}