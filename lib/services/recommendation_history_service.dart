import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation_history.dart';

class RecommendationHistoryService {
  static const String _historyKeyPrefix = 'rec_history_';
  static const String _recordedHashesKey = 'recorded_hashes';
  static const int maxEntriesPerSensor = 10;
  
  // Track recorded hashes across app sessions
  Future<Set<String>> _getRecordedHashes() async {
    final prefs = await SharedPreferences.getInstance();
    final hashesJson = prefs.getString(_recordedHashesKey);
    if (hashesJson == null) return {};
    try {
      final List<String> hashes = List<String>.from(json.decode(hashesJson));
      return hashes.toSet();
    } catch (e) {
      return {};
    }
  }
  
  Future<void> _saveRecordedHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final hashes = await _getRecordedHashes();
    hashes.add(hash);
    await prefs.setString(_recordedHashesKey, json.encode(hashes.toList()));
  }
  
  Future<bool> hasHashBeenRecorded(String hash) async {
    final hashes = await _getRecordedHashes();
    return hashes.contains(hash);
  }

  Future<void> addHistoryEntry(String sensorId, RecommendationHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyKeyPrefix$sensorId';
    
    // Create a unique hash for this exact recommendation + conditions + minute
    final minuteKey = entry.dateRecommended.toIso8601String().substring(0, 16); // Year-Month-Day Hour:Minute
    final hash = '${sensorId}_${entry.name}_${entry.moisture}_${entry.temperature}_${entry.humidity}_$minuteKey';
    
    // Check if this exact combo was already recorded
    if (await hasHashBeenRecorded(hash)) {
      print('📝 Skipping - hash already recorded: $hash');
      return;
    }
    
    List<RecommendationHistoryEntry> history = await getHistoryForSensor(sensorId);
    
    // Check for duplicate within last 3 entries
    bool isDuplicate = false;
    for (int i = 0; i < history.length && i < 3; i++) {
      if (history[i].name == entry.name && 
          history[i].moisture == entry.moisture &&
          history[i].temperature == entry.temperature) {
        isDuplicate = true;
        break;
      }
    }
    
    if (isDuplicate) {
      print('📝 Skipping - duplicate found in recent history for $sensorId');
      return;
    }
    
    // Add new entry at the beginning
    history.insert(0, entry);
    
    // Keep only recent entries
    if (history.length > maxEntriesPerSensor) {
      history = history.take(maxEntriesPerSensor).toList();
    }
    
    // Save to SharedPreferences
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(key, json.encode(jsonList));
    
    // Mark this hash as recorded
    await _saveRecordedHash(hash);
    
    print('✅ Recorded new history entry for $sensorId: ${entry.name} at ${entry.dateRecommended}');
  }

  Future<List<RecommendationHistoryEntry>> getHistoryForSensor(String sensorId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyKeyPrefix$sensorId';
    
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => RecommendationHistoryEntry.fromJson(json)).toList();
    } catch (e) {
      print('Error loading recommendation history: $e');
      return [];
    }
  }

  Future<void> clearHistoryForSensor(String sensorId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyKeyPrefix$sensorId';
    await prefs.remove(key);
  }

  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.startsWith(_historyKeyPrefix)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_recordedHashesKey);
  }
}