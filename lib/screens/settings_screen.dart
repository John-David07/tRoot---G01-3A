import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache_service.dart';
import '../services/recommendation_history_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Reset All Data',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          '⚠️ CAUTION! This action cannot be undone.\n\n'
          'The following data will be permanently cleared:\n'
          '• AI-generated plant recommendations (cached)\n'
          '• Uploaded soil analysis results and images\n'
          '• Plant recommendation history\n'
          '• All locally stored preferences\n\n'
          'Your ESP32 sensor readings and historical data will NOT be affected.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear SharedPreferences (app preferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear AI cache and soil cache via CacheService
      await CacheService().clearAllCache();

      // Clear recommendation history
      final recommendationHistoryService = RecommendationHistoryService();
      await recommendationHistoryService.clearAllHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All local data has been reset. Restart the app for complete effect.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Reset Settings
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 1),
          ),
          color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
          child: ListTile(
            title: const Text(
              'Reset All Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'Clear AI recommendations cache, soil analysis, and preferences',
            ),
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
          color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
