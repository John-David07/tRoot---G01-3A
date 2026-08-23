import 'package:flutter/material.dart';
import '../utils/theme_manager.dart';

class PlantCareDialog extends StatelessWidget {
  final String plantName;
  final String scientificName;
  final Map<String, dynamic>? careData;

  const PlantCareDialog({
    super.key,
    required this.plantName,
    required this.scientificName,
    this.careData,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.eco, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    plantName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    scientificName,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: careData != null && careData!.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (careData!.containsKey('light'))
                            _buildCareSection(context, Icons.wb_sunny, 'Light', careData!['light'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('water'))
                            _buildCareSection(context, Icons.water_drop, 'Water', careData!['water'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('temperature'))
                            _buildCareSection(context, Icons.thermostat, 'Temperature', careData!['temperature'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('humidity'))
                            _buildCareSection(context, Icons.opacity, 'Humidity', careData!['humidity'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('soil'))
                            _buildCareSection(context, Icons.agriculture, 'Soil', careData!['soil'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('fertilizer'))
                            _buildCareSection(context, Icons.cleaning_services, 'Fertilizer', careData!['fertilizer'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('tips'))
                            _buildCareSection(context, Icons.lightbulb, 'Pro Tips', careData!['tips'], isDarkMode),
                          const SizedBox(height: 12),
                          if (careData!.containsKey('commonProblems'))
                            _buildCareSection(context, Icons.warning, 'Common Problems', careData!['commonProblems'], isDarkMode),
                        ],
                      )
                    : Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Care information temporarily unavailable',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareSection(BuildContext context, IconData icon, String title, String content, bool isDarkMode) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111827) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}