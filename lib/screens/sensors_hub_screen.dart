import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/sensor_data.dart';
import '../utils/theme_manager.dart';

class SensorsHubScreen extends StatefulWidget {
  const SensorsHubScreen({super.key});

  @override
  State<SensorsHubScreen> createState() => _SensorsHubScreenState();
}

class _SensorsHubScreenState extends State<SensorsHubScreen> {
  final DatabaseService _dbService = DatabaseService();

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
        
        // Sort nodes naturally
        var nodes = data.getNodes()..sort((a, b) {
          int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
          int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
          return numA.compareTo(numB);
        });

        if (nodes.isEmpty) {
          return const Center(child: Text('No sensors found'));
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensor Hub',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring ${nodes.length} active sensors',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final nodeId = nodes[index];
                  return _buildSensorCard(
                    nodeId: nodeId,
                    data: data,
                  );
                },
                childCount: nodes.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildSensorCard({required String nodeId, required SensorData data}) {
    final moisture = data.getNodeMoisture(nodeId);
    final condition = _getCondition(moisture);
    final color = _getConditionColor(moisture);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/sensor_detail',
            arguments: {
              'nodeId': nodeId,
              'moisture': moisture,
              'temperature': data.temperature,
              'humidity': data.humidity,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Moisture indicator circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$moisture%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Sensor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nodeId.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plant ${nodeId.replaceAll('Node_', '')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.thermostat, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${data.temperature.toInt()}°C', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.water_drop, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${data.humidity.toInt()}%', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Text(
                  condition,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
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
}