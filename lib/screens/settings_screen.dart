import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _refreshRate = '30';
  bool _isCalibrating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshRate = prefs.getString('refreshRate') ?? '30';
    });
  }

  void _saveRefreshRate(String value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshRate = value;
    });
    await prefs.setString('refreshRate', value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refresh rate set to $value seconds')),
    );
  }

  void _calibrateSensors() async {
    setState(() => _isCalibrating = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isCalibrating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sensors calibrated successfully')),
    );
  }

  void _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text('Are you sure? This will clear all local settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data reset completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Refresh Rate
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
          ),
          child: ListTile(
            title: const Text('Data Refresh Rate'),
            subtitle: const Text('How often sensor data updates'),
            trailing: DropdownButton<String>(
              value: _refreshRate,
              items: const [
                DropdownMenuItem(value: '15', child: Text('15 sec')),
                DropdownMenuItem(value: '30', child: Text('30 sec')),
                DropdownMenuItem(value: '60', child: Text('1 min')),
                DropdownMenuItem(value: '300', child: Text('5 min')),
              ],
              onChanged: (value) => _saveRefreshRate(value!),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Calibration
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
          ),
          child: ListTile(
            title: const Text('Calibration'),
            subtitle: const Text('Recalibrate soil moisture sensors'),
            trailing: _isCalibrating
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton(
                    onPressed: _calibrateSensors,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: const Text('Calibrate'),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Reset Data
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 1),
          ),
          child: ListTile(
            title: const Text('Reset Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Clear all local storage and settings'),
            trailing: ElevatedButton(
              onPressed: _resetData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // System Info
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildInfoRow('Firmware Version', 'v2.4.12-stable'),
                _buildInfoRow('Hardware ID', 'EG-SENS-8842-X'),
                _buildInfoRow('Network Status', 'Connected'),
                _buildInfoRow('AI Model', 'Gemini 2.5 Flash Lite'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}