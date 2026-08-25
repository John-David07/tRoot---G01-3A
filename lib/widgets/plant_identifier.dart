import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/plant_identifier_service.dart';
import '../utils/theme_manager.dart';

class PlantIdentifier extends StatefulWidget {
  const PlantIdentifier({super.key});

  @override
  State<PlantIdentifier> createState() => _PlantIdentifierState();
}

class _PlantIdentifierState extends State<PlantIdentifier> {
  final PlantIdentifierService _service = PlantIdentifierService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _plantData;
  String? _error;

  Future<void> _handleImagePicker() async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Plant Photo'),
        content: const Text('Choose how to get the image'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'camera'),
            child: const Text('📷 Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'gallery'),
            child: const Text('🖼️ Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (option == null || option == 'cancel') return;

    XFile? image;

    if (option == 'camera') {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        image = await _picker.pickImage(source: ImageSource.camera);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take photos'),
          ),
        );
        return;
      }
    } else if (option == 'gallery') {
      image = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (image != null) {
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      
      setState(() {
        _selectedImage = file;
        _plantData = null;
        _error = null;
        _isLoading = true;
      });

      try {
        final mimeType = image.mimeType ?? 'image/jpeg';
        final result = await _service.identifyPlant(bytes, mimeType);
        
        if (mounted) {
          setState(() {
            _plantData = result;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  void _clearData() {
    setState(() {
      _selectedImage = null;
      _plantData = null;
      _error = null;
    });
  }

  Widget _buildInfoRow(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Card(
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
            const Row(
              children: [
                Icon(Icons.search, color: ThemeManager.primaryColor),
                SizedBox(width: 8),
                Text(
                  '🔍 AI Plant Identifier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a photo of a plant to identify it and get care recommendations',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Upload Area
            GestureDetector(
              onTap: _handleImagePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ThemeManager.primaryColor,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode 
                      ? const Color(0xFF111827) 
                      : Colors.grey.shade50,
                ),
                child: _isLoading
                    ? const Column(
                        children: [
                          SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text('AI is identifying your plant...'),
                        ],
                      )
                    : _selectedImage != null && _plantData != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImage!,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _plantData!['name'] ?? 'Unknown Plant',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _plantData!['scientificName'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: isDarkMode 
                                                ? Colors.grey.shade400 
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _plantData!['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_plantData!['care'] != null)
                                Column(
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      '☀️ Light',
                                      _plantData!['care']['light'],
                                    ),
                                    _buildInfoRow(
                                      '💧 Water',
                                      _plantData!['care']['water'],
                                    ),
                                    _buildInfoRow(
                                      '🌡️ Temperature',
                                      _plantData!['care']['temperature'],
                                    ),
                                    _buildInfoRow(
                                      '💨 Humidity',
                                      _plantData!['care']['humidity'],
                                    ),
                                    _buildInfoRow(
                                      '🌱 Soil',
                                      _plantData!['care']['soil'],
                                    ),
                                    _buildInfoRow(
                                      '🧪 Fertilizer',
                                      _plantData!['care']['fertilizer'],
                                    ),
                                    _buildInfoRow(
                                      '💡 Tips',
                                      _plantData!['care']['tips'],
                                    ),
                                    _buildInfoRow(
                                      '⚠️ Common Problems',
                                      _plantData!['care']['commonProblems'],
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _clearData,
                                child: const Text(
                                  'Clear & Upload New',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                size: 48,
                                color: ThemeManager.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error != null ? 'Try Again' : 'Upload Plant Photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'PNG, JPG, JPEG only',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode 
                                        ? Colors.grey.shade500 
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}