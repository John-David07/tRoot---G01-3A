import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_manager.dart';
import 'plant_recommendations.dart';

class PlantRecommendationChat extends StatefulWidget {
  final String sensorId;
  final double defaultMoisture;
  final double defaultTemperature;
  final double defaultHumidity;
  final ValueChanged<String>? onSensorChanged; // For dashboard carousel

  const PlantRecommendationChat({
    super.key,
    required this.sensorId,
    required this.defaultMoisture,
    required this.defaultTemperature,
    required this.defaultHumidity,
    this.onSensorChanged,
  });

  @override
  State<PlantRecommendationChat> createState() => _PlantRecommendationChatState();
}

class _PlantRecommendationChatState extends State<PlantRecommendationChat> {
  final TextEditingController _moistureController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  
  bool _isSubmitted = false;
  double _submittedMoisture = 0;
  double _submittedPh = 7.0;
  double _submittedTemperature = 0;
  double _submittedHumidity = 0;
  int _recommendationKey = 0;
  
  static const String _sessionKeyPrefix = 'node_session_';
  
  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void didUpdateWidget(PlantRecommendationChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sensorId != widget.sensorId) {
      _loadSession();
      setState(() {
        _isSubmitted = false;
        _recommendationKey++;
      });
    }
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = _sessionKeyPrefix + widget.sensorId;
    final sessionData = prefs.getString(sessionKey);
    
    if (sessionData != null) {
      try {
        final data = json.decode(sessionData);
        _moistureController.text = data['moisture']?.toString() ?? widget.defaultMoisture.toStringAsFixed(1);
        _phController.text = data['ph']?.toString() ?? '';
        _temperatureController.text = data['temperature']?.toString() ?? widget.defaultTemperature.toStringAsFixed(1);
        _humidityController.text = data['humidity']?.toString() ?? widget.defaultHumidity.toStringAsFixed(1);
        
        if (data['hasSubmitted'] == true && data['submittedData'] != null) {
          final submitted = data['submittedData'];
          _submittedMoisture = submitted['moisture']?.toDouble() ?? 0;
          _submittedPh = submitted['ph']?.toDouble() ?? 7.0;
          _submittedTemperature = submitted['temperature']?.toDouble() ?? 0;
          _submittedHumidity = submitted['humidity']?.toDouble() ?? 0;
          _isSubmitted = true;
          _recommendationKey++;
        }
        setState(() {});
      } catch (e) {
        print('Error loading session: $e');
        _resetFields();
      }
    } else {
      _resetFields();
    }
  }

  void _resetFields() {
    _moistureController.text = widget.defaultMoisture.toStringAsFixed(1);
    _phController.text = '';
    _temperatureController.text = widget.defaultTemperature.toStringAsFixed(1);
    _humidityController.text = widget.defaultHumidity.toStringAsFixed(1);
  }

  Future<void> _saveSession(bool hasSubmitted, {Map<String, dynamic>? submittedData}) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = _sessionKeyPrefix + widget.sensorId;
    
    final session = {
      'moisture': double.tryParse(_moistureController.text) ?? 0,
      'ph': double.tryParse(_phController.text) ?? 0,
      'temperature': double.tryParse(_temperatureController.text) ?? 0,
      'humidity': double.tryParse(_humidityController.text) ?? 0,
      'hasSubmitted': hasSubmitted,
      if (submittedData != null) 'submittedData': submittedData,
    };
    
    await prefs.setString(sessionKey, json.encode(session));
  }

  void _handleSubmit() {
    final moisture = double.tryParse(_moistureController.text);
    final ph = double.tryParse(_phController.text);
    final temperature = double.tryParse(_temperatureController.text);
    final humidity = double.tryParse(_humidityController.text);
    
    if (moisture == null || ph == null || temperature == null || humidity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers for all fields')),
      );
      return;
    }
    
    setState(() {
      _submittedMoisture = moisture;
      _submittedPh = ph;
      _submittedTemperature = temperature;
      _submittedHumidity = humidity;
      _isSubmitted = true;
      _recommendationKey++;
    });
    
    _saveSession(true, submittedData: {
      'moisture': moisture,
      'ph': ph,
      'temperature': temperature,
      'humidity': humidity,
    });
  }

  void _handleReset() {
    setState(() {
      _isSubmitted = false;
      _resetFields();
      _recommendationKey++;
    });
    _saveSession(false);
  }

  @override
  void dispose() {
    _moistureController.dispose();
    _phController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Card(
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
                const Text(
                  '🌱 A.I. Plant Recommendation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter soil conditions to get AI plant recommendations',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                // 2-column layout for fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _moistureController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Moisture (%)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.water_drop, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        enabled: !_isSubmitted,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'pH (0-14)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.science, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        enabled: !_isSubmitted,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _temperatureController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Temp (°C)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.thermostat, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        enabled: !_isSubmitted,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _humidityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Humidity (%)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.opacity, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        enabled: !_isSubmitted,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSubmitted ? null : _handleSubmit,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Get Recommendations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeManager.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                    if (_isSubmitted)
                      OutlinedButton(
                        onPressed: _handleReset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text('Start New Search'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 Moisture 40-80% = Optimal | pH 6.0-7.5 = Ideal | Temp 18-28°C',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isSubmitted)
          PlantRecommendations(
            key: ValueKey(_recommendationKey),
            moisture: _submittedMoisture.toInt(),
            ph: _submittedPh,
            temperature: _submittedTemperature,
            humidity: _submittedHumidity,
            sensorId: widget.sensorId,
          ),
      ],
    );
  }
}