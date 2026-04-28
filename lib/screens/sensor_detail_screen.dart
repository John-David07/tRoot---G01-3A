import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../utils/theme_manager.dart';

class SensorDetailScreen extends StatefulWidget {
  const SensorDetailScreen({super.key});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  
  late String nodeId;
  late int moisture;
  late double temperature;
  late double humidity;
  late Future<List<Map<String, dynamic>>> _historyFuture;
  
  // Plant upload state
  XFile? _uploadedImage;
  Map<String, String>? _plantCareData;
  bool _isAnalyzingPlant = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    nodeId = args['nodeId'];
    moisture = args['moisture'];
    temperature = args['temperature'];
    humidity = args['humidity'];
    
    _historyFuture = _dbService.getHistoryForSensor(nodeId);
  }

  String getCondition() {
    if (moisture > 80) return 'Saturated';
    if (moisture > 40) return 'Optimal';
    return 'Dry';
  }

  Color getColor() {
    if (moisture > 80) return Colors.blue;
    if (moisture > 40) return Colors.green;
    return Colors.orange;
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

  @override
  Widget build(BuildContext context) {
    final condition = getCondition();
    final color = getColor();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor ${nodeId.replaceAll('_', ' ')}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current State Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
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
                          const SizedBox(height: 8),
                          Text(
                            'Moisture',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        condition,
                        style: TextStyle(color: color, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${temperature.toInt()}°C',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Temperature',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${humidity.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Humidity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
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

            const SizedBox(height: 16),

            // Live Moisture Tracking Graph
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Moisture Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 15 readings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 250,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox(
                            height: 250,
                            child: Center(child: Text('No historical data available')),
                          );
                        }

                        final history = snapshot.data!.take(15).toList();
                        final spots = <FlSpot>[];
                        
                        for (int i = 0; i < history.length; i++) {
                          spots.add(FlSpot(
                            i.toDouble(),
                            history[i]['moisture'].toDouble(),
                          ));
                        }

                        return SizedBox(
                          height: 250,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: const FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: ThemeManager.primaryColor,
                                  barWidth: 2,
                                  belowBarData: BarAreaData(show: false),
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

// AI Plant Care Assistant (Upload Area)
          Container(
            width: double.infinity,
            child: Card(
              margin: EdgeInsets.zero,
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
                                Text(
                                  _plantCareData!['name'] ?? 'Unknown Plant',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _plantCareData!['scientificName'] ?? '',
                                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 12),
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
                                Icon(Icons.cloud_upload, size: 48, color: ThemeManager.primaryColor),
                                const SizedBox(height: 12),
                                const Text('Add/drag&drop img file', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Text('PNG, JPG, JPEG only', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                ),
              ),
            ),
          ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}