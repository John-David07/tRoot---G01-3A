import 'package:flutter/material.dart';
import 'package:plant_monitoring_system/models/plant_recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final PlantRecommendation plant;

  const RecommendationCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.spa, color: Colors.green),
        ),
        title: Text(plant.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plant.scientificName, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(plant.description, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
