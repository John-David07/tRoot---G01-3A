import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../models/sensor_data.dart';
import '../widgets/independent_sensor_carousel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/recommendation_carousel.dart';
import '../widgets/plant_care_dialog.dart';
import '../utils/theme_manager.dart';
import 'sensors_hub_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final GeminiService _geminiService = GeminiService();
  
  int _currentSensorIndex = 0;
  
  // Data
  SensorData? _sensorData;
  List<String> _nodes = [];
  
  // Recommendations
  List<Map<String, dynamic>> _currentRecommendations = [];
  bool _isLoadingRecommendations = false;
  final Map<String, List<Map<String, dynamic>>> _recommendationsCache = {};
  final Map<String, bool> _loadingCache = {};
  
  // Plant upload state
  XFile? _uploadedImage;
  Map<String, String>? _plantCareData;
  bool _isAnalyzingPlant = false;

  void _onSensorChanged(int index) {
    if (_currentSensorIndex == index) return;
    _currentSensorIndex = index;
    _loadRecommendationsForCurrentSensor();
  }

  Future<void> _loadRecommendationsForCurrentSensor() async {
    if (_sensorData == null || _nodes.isEmpty) return;
    
    final sensorId = _nodes[_currentSensorIndex];
    
    if (_recommendationsCache.containsKey(sensorId)) {
      setState(() {
        _currentRecommendations = _recommendationsCache[sensorId]!;
        _isLoadingRecommendations = false;
      });
      return;
    }
    
    if (_loadingCache[sensorId] == true) return;
    
    _loadingCache[sensorId] = true;
    setState(() => _isLoadingRecommendations = true);

    final moisture = _sensorData!.getNodeMoisture(sensorId);
    
    final recommendations = await _geminiService.getRecommendations(
      moisture: moisture,
      temperature: _sensorData!.temperature,
      humidity: _sensorData!.humidity,
    );
    
    if (mounted) {
      _recommendationsCache[sensorId] = recommendations;
      _loadingCache[sensorId] = false;
      setState(() {
        _currentRecommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _handleImageUpload() async {
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
      // Request camera permission first
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final picker = ImagePicker();
        image = await picker.pickImage(source: ImageSource.camera);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to take photos')),
        );
        return;
      }
    } else if (option == 'gallery') {
      final picker = ImagePicker();
      image = await picker.pickImage(source: ImageSource.gallery);
    }
  
    if (image != null) {
      setState(() {
        _uploadedImage = image;
        _isAnalyzingPlant = true;
        _plantCareData = null;
      });
    
      final careData = await _geminiService.getPlantCareFromImage(image);
      
      if (mounted) {
        setState(() {
          _plantCareData = careData;
          _isAnalyzingPlant = false;
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
        _sensorData = data;
        
        _nodes = data.getNodes()..sort((a, b) {
          int numA = int.tryParse(a.replaceAll('Node_', '')) ?? 0;
          int numB = int.tryParse(b.replaceAll('Node_', '')) ?? 0;
          return numA.compareTo(numB);
        });

        if (_nodes.isEmpty) {
          return const Center(child: Text('No sensors found'));
        }

        if (_currentRecommendations.isEmpty && !_isLoadingRecommendations) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadRecommendationsForCurrentSensor();
          });
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Smart Insight Card
              _buildSmartInsightCard(data),

              // Sensor Carousel
              IndependentSensorCarousel(),

              const SizedBox(height: 24),

              // Drag & Drop Upload Area
              _buildUploadArea(),

              const SizedBox(height: 24),

              // AI Recommendation Section
              _buildRecommendationSection(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
        ),
        child: InkWell(
          onTap: _handleImageUpload,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isAnalyzingPlant
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('AI is analyzing your plant...'),
                    ],
                  )
                : _uploadedImage != null && _plantCareData != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plant image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_uploadedImage!.path),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Plant name
                          Text(
                            _plantCareData!['name'] ?? 'Unknown Plant',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Scientific name
                          Text(
                            _plantCareData!['scientificName'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Care sections
                          _buildCareSection('💧 Watering', _plantCareData!['watering']),
                          _buildCareSection('☀️ Sunlight', _plantCareData!['sunlight']),
                          _buildCareSection('🌡️ Temperature', _plantCareData!['temperature']),
                          _buildCareSection('💨 Humidity', _plantCareData!['humidity']),
                          _buildCareSection('🌱 Soil', _plantCareData!['soil']),
                          _buildCareSection('⚠️ Common Issues', _plantCareData!['commonIssues']),
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
                          const Text(
                            'Add/drag&drop img file',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PNG, JPG, JPEG only',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildCareSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
        ],
      ),
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

  Widget _buildRecommendationSection() {
    if (_isLoadingRecommendations) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
          ),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('AI is analyzing conditions...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_currentRecommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
          ),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No recommendations available')),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RecommendationCarousel(recommendations: _currentRecommendations),
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