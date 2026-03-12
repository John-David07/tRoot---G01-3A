import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final int moisture;
  final double temperature;
  final double humidity;
  final String condition;

  const SensorCard({
    super.key,
    required this.title,
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.condition,
  });

  Color _getConditionColor() {
    switch (condition) {
      case 'Optimal': return Colors.green;
      case 'Wet': return Colors.blue;
      case 'Dry': return Colors.orange;
      case 'Critical': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConditionColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getConditionColor()),
                  ),
                  child: Text(
                    condition,
                    style: TextStyle(color: _getConditionColor()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSensorIndicator('💧', 'MOISTURE', '$moisture%'),
                _buildSensorIndicator('🌡️', 'TEMP', '${temperature.round()}°C'),
                _buildSensorIndicator('💨', 'HUMIDITY', '${humidity.round()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}