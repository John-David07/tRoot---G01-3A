import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme_manager.dart';

class PlantCareDialog extends StatelessWidget {
  final Map<String, String> careData;
  final XFile imageFile;

  const PlantCareDialog({
    super.key,
    required this.careData,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plant Care Guide',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ThemeManager.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // Plant image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imageFile.path),  // Convert XFile to File
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            
            // Plant name
            Text(
              careData['name'] ?? 'Unknown Plant',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              careData['scientificName'] ?? '',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // care instructions
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCareSection('💧 Watering', careData['watering']),
                    _buildCareSection('☀️ Sunlight', careData['sunlight']),
                    _buildCareSection('🌡️ Temperature', careData['temperature']),
                    _buildCareSection('💨 Humidity', careData['humidity']),
                    _buildCareSection('🌱 Soil', careData['soil']),
                    _buildCareSection('⚠️ Common Issues', careData['commonIssues']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}