import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../utils/theme_manager.dart';
import '../widgets/recommendation_history_widget.dart';

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
  
  // Soil upload state
  XFile? _uploadedSoilImage;
  Map<String, String>? _soilInfo;
  bool _isAnalyzingSoil = false;
  
  // Cache keys for this specific sensor
  String get _soilImageCacheKey => 'soil_image_${nodeId}';
  String get _soilInfoCacheKey => 'soil_info_${nodeId}';

  @override
  void initState() {
    super.initState();
    _loadCachedSoilData();
  }

  Future<void> _loadCachedSoilData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load cached image path (use existsSync for synchronous check)
    final cachedImagePath = prefs.getString(_soilImageCacheKey);
    if (cachedImagePath != null && File(cachedImagePath).existsSync()) {
      _uploadedSoilImage = XFile(cachedImagePath);
    }
    
    // Load cached soil info
    final cachedSoilInfo = prefs.getString(_soilInfoCacheKey);
    if (cachedSoilInfo != null) {
      try {
        _soilInfo = Map<String, String>.from(json.decode(cachedSoilInfo));
      } catch (e) {
        print('Error loading cached soil info: $e');
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveSoilDataToCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save image path
    if (_uploadedSoilImage != null) {
      await prefs.setString(_soilImageCacheKey, _uploadedSoilImage!.path);
    }
    
    // Save soil info
    if (_soilInfo != null) {
      await prefs.setString(_soilInfoCacheKey, json.encode(_soilInfo));
    }
  }

  Future<void> _clearSoilCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_soilImageCacheKey);
    await prefs.remove(_soilInfoCacheKey);
  }

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

  Future<void> _handleSoilImageUpload() async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Soil Photo'),
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
        _uploadedSoilImage = image;
        _isAnalyzingSoil = true;
        _soilInfo = null;
      });
      
      final soilInfo = await _geminiService.getSoilInfoFromImage(image);
      
      if (mounted) {
        setState(() {
          _soilInfo = soilInfo;
          _isAnalyzingSoil = false;
        });
        await _saveSoilDataToCache();
      }
    }
  }

  Widget _buildSoilInfoRow(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
    final condition = getCondition();
    final color = getColor();final textColor = Theme.of(context).brightness == Brightness.light 
        ? Colors.black 
        : Colors.white;

        print('Text color: $textColor');


    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor ${nodeId.replaceAll('_', ' ')}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_uploadedSoilImage != null || _soilInfo != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                setState(() {
                  _uploadedSoilImage = null;
                  _soilInfo = null;
                });
                await _clearSoilCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Soil data cleared')),
                );
              },
              tooltip: 'Clear soil data',
            ),
        ],
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${temperature.toInt()}°C',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${humidity.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 4),
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

            // Soil Identification Assistant
            Container(
              width: double.infinity,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
                ),
                child: InkWell(
                  onTap: _handleSoilImageUpload,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _isAnalyzingSoil
                        ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('AI is analyzing your soil...'),
                            ],
                          )
                        : _uploadedSoilImage != null && _soilInfo != null
                            ? (_soilInfo!['error'] == 'true'
                                ? Column(
                                    children: [
                                      Icon(Icons.error_outline, size: 48, color: Colors.orange),
                                      const SizedBox(height: 12),
                                      Text(
                                        _soilInfo!['message'] ?? 'Unable to identify',
                                        style: const TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: _handleSoilImageUpload,
                                        child: const Text('Try Another Image'),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(_uploadedSoilImage!.path),
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _soilInfo!['name'] ?? 'Unknown Soil',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _soilInfo!['description'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildSoilInfoRow('🌱 Best for', _soilInfo!['bestFor']),
                                      _buildSoilInfoRow('💧 Drainage', _soilInfo!['drainage']),
                                      _buildSoilInfoRow('🧪 Nutrients', _soilInfo!['nutrients']),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _handleSoilImageUpload,
                                        child: const Text('Upload Another Soil Sample'),
                                      ),
                                    ],
                                  ))
                            : Column(
                                children: [
                                  Icon(Icons.cloud_upload, size: 48, color: ThemeManager.primaryColor),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload soil image for identification',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'PNG, JPG, JPEG only',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            RecommendationHistoryWidget(
              sensorId: nodeId,
              onResetHistory: () {
                // Optional: Additional callback when history is cleared
                if (mounted) {
                  setState(() {});
                }
              },
            ),

            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}