import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/theme_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryRecord> _history = [];
  bool _loading = true;
  String _selectedSensor = 'all';
  int _currentPage = 1;
  final int _recordsPerPage = 10;
  
  // Filters
  String _moistureMin = '';
  String _moistureMax = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    
    try {
      final database = FirebaseDatabase.instance;
      
      // Fetch all three nodes simultaneously
      final results = await Future.wait([
        database.ref('History/Soil_Sensor').get(),
        database.ref('History/Temperature').get(),
        database.ref('History/humidity').get(),
      ]);
      
      final soilSnapshot = results[0];
      final tempSnapshot = results[1];
      final humiditySnapshot = results[2];
      
      if (!soilSnapshot.exists) {
        setState(() => _loading = false);
        return;
      }
      
      final soilData = soilSnapshot.value as Map<dynamic, dynamic>? ?? {};
      final tempData = tempSnapshot.value as Map<dynamic, dynamic>? ?? {};
      final humidityData = humiditySnapshot.value as Map<dynamic, dynamic>? ?? {};
      
      final sensors = ['Node_1', 'Node_2', 'Node_3', 'Node_4', 'Node_5'];
      
      // Collect all unique pushIds from Soil_Sensor
      final allPushIds = <String>{};
      for (var sensor in sensors) {
        final sensorData = soilData[sensor];
        if (sensorData is Map) {
          allPushIds.addAll(sensorData.keys.cast<String>());
        }
      }
      
      // Build timestamp maps for temperature and humidity
      final tempTimestampMap = <String, double>{};
      final humidityTimestampMap = <String, double>{};
      
      for (var key in tempData.keys) {
        if (key != 'id' && tempData[key] is num) {
          tempTimestampMap[key] = (tempData[key] as num).toDouble();
        }
      }
      
      for (var key in humidityData.keys) {
        if (key != 'id' && humidityData[key] is num) {
          humidityTimestampMap[key] = (humidityData[key] as num).toDouble();
        }
      }
      
      // Create history records
      final historyList = <HistoryRecord>[];
      for (var pushId in allPushIds) {
        final sensorReadings = <SensorReading>[];
        
        for (var sensor in sensors) {
          final sensorData = soilData[sensor];
          if (sensorData is Map && sensorData.containsKey(pushId)) {
            final value = sensorData[pushId];
            int moisture = 0;
            if (value is int) {
              moisture = value;
            } else if (value is Map && value.containsKey('value')) {
              moisture = value['value'];
            }
            
            sensorReadings.add(SensorReading(
              nodeId: sensor,
              moisture: moisture,
            ));
          }
        }
        
        if (sensorReadings.isNotEmpty) {
          // Parse timestamp from pushId
          DateTime timestamp = DateTime.now();
          if (pushId.length >= 8 && pushId.startsWith('-')) {
            final hexPart = pushId.substring(1, 9);
            try {
              final timeValue = int.parse(hexPart, radix: 16);
              if (timeValue > 1000000) {
                timestamp = DateTime.fromMillisecondsSinceEpoch(timeValue);
              }
            } catch (e) {}
          }
          
          // Find closest temperature and humidity by timestamp
          double temperature = 0;
          double humidity = 0;
          
          // Get the closest temperature reading (by pushId order)
          final closestTempKey = _findClosestKey(pushId, tempTimestampMap.keys.toList());
          if (closestTempKey != null) {
            temperature = tempTimestampMap[closestTempKey] ?? 0;
          }
          
          // Get the closest humidity reading
          final closestHumidityKey = _findClosestKey(pushId, humidityTimestampMap.keys.toList());
          if (closestHumidityKey != null) {
            humidity = humidityTimestampMap[closestHumidityKey] ?? 0;
          }
          
          historyList.add(HistoryRecord(
            id: pushId,
            timestamp: timestamp,
            sensorReadings: sensorReadings,
            temperature: temperature,
            humidity: humidity,
          ));
        }
      }
      
      // Sort newest first
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Calculate trends (compare with next record)
      for (int i = 0; i < historyList.length; i++) {
        final current = historyList[i];
        final older = i + 1 < historyList.length ? historyList[i + 1] : null;
        
        if (older != null) {
          for (var reading in older.sensorReadings) {
            current.previousMoistureMap[reading.nodeId] = reading.moisture;
          }
        }
      }
      
      setState(() {
        _history = historyList;
        _loading = false;
        _currentPage = 1;
      });
    } catch (e) {
      print('Error fetching history: $e');
      setState(() => _loading = false);
    }
  }

  String _findClosestKey(String targetKey, List<String> keys) {
    if (keys.isEmpty) return '';
    
    String closestKey = keys[0];
    int closestDiff = (targetKey.compareTo(keys[0])).abs();
    
    for (var key in keys) {
      final diff = (targetKey.compareTo(key)).abs();
      if (diff < closestDiff) {
        closestDiff = diff;
        closestKey = key;
      }
    }
    
    return closestKey;
  }

  List<HistoryRecord> get _filteredHistory {
    var filtered = List<HistoryRecord>.from(_history);
    
    // Filter by sensor
    if (_selectedSensor != 'all') {
      filtered = filtered.where((record) =>
        record.sensorReadings.any((s) => s.nodeId == _selectedSensor)
      ).toList();
    }
    
    // Filter by moisture range
    if (_moistureMin.isNotEmpty || _moistureMax.isNotEmpty) {
      filtered = filtered.where((record) {
        final values = record.sensorReadings
            .where((s) => _selectedSensor == 'all' || s.nodeId == _selectedSensor)
            .map((s) => s.moisture);
        
        if (values.isEmpty) return false;
        
        if (_selectedSensor == 'all') {
          return values.any((m) {
            if (_moistureMin.isNotEmpty && m < int.parse(_moistureMin)) return false;
            if (_moistureMax.isNotEmpty && m > int.parse(_moistureMax)) return false;
            return true;
          });
        } else {
          final m = values.first;
          if (_moistureMin.isNotEmpty && m < int.parse(_moistureMin)) return false;
          if (_moistureMax.isNotEmpty && m > int.parse(_moistureMax)) return false;
          return true;
        }
      }).toList();
    }
    
    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((record) =>
        record.timestamp.isAfter(_startDate!.subtract(const Duration(days: 1)))
      ).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((record) =>
        record.timestamp.isBefore(_endDate!.add(const Duration(days: 1)))
      ).toList();
    }
    
    return filtered;
  }

  String _getCondition(int moisture) {
    if (moisture > 80) return 'Saturated';
    if (moisture > 40) return 'Optimal';
    return 'Dry';
  }

  Color _getConditionColor(int moisture) {
    if (moisture > 80) return Colors.blue;
    if (moisture > 40) return Colors.green;
    return Colors.orange;
  }

  Map<String, dynamic> _getTrend(int current, int? previous) {
    if (previous == null) {
      return {'icon': '●', 'color': Colors.grey, 'text': '0%', 'change': 0};
    }
    final change = current - previous;
    if (change > 0) {
      return {'icon': '▲', 'color': Colors.green, 'text': '+$change%', 'change': change};
    } else if (change < 0) {
      return {'icon': '▼', 'color': Colors.red, 'text': '$change%', 'change': change};
    }
    return {'icon': '●', 'color': Colors.grey, 'text': '0%', 'change': 0};
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _clearFilters() {
    setState(() {
      _selectedSensor = 'all';
      _moistureMin = '';
      _moistureMax = '';
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory;
    final totalPages = (filtered.length / _recordsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _recordsPerPage;
    final endIndex = startIndex + _recordsPerPage;
    final currentRecords = filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(180),
          child: _buildFilterBar(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Results count
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Showing ${currentRecords.length} of ${filtered.length} records',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                // History list
                Expanded(
                  child: currentRecords.isEmpty
                      ? const Center(child: Text('No records match your filters'))
                      : ListView.builder(
                          itemCount: currentRecords.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(currentRecords[index]);
                          },
                        ),
                ),
                // Pagination
                if (totalPages > 1) _buildPagination(totalPages),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Sensor filter
          DropdownButtonFormField<String>(
            value: _selectedSensor,
            decoration: const InputDecoration(
              labelText: 'Sensor',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Sensors')),
              DropdownMenuItem(value: 'Node_1', child: Text('Node 1')),
              DropdownMenuItem(value: 'Node_2', child: Text('Node 2')),
              DropdownMenuItem(value: 'Node_3', child: Text('Node 3')),
              DropdownMenuItem(value: 'Node_4', child: Text('Node 4')),
              DropdownMenuItem(value: 'Node_5', child: Text('Node 5')),
            ],
            onChanged: (value) => setState(() => _selectedSensor = value!),
          ),
          const SizedBox(height: 8),
          // Moisture range
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Moisture Min (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => _moistureMin = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Moisture Max (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => _moistureMax = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_startDate != null
                        ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                        : 'Select date'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_endDate != null
                        ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                        : 'Select date'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Clear filters button
          if (_selectedSensor != 'all' ||
              _moistureMin.isNotEmpty ||
              _moistureMax.isNotEmpty ||
              _startDate != null ||
              _endDate != null)
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
              ),
              child: const Text('Clear All Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryRecord record) {
    final readings = _selectedSensor == 'all'
        ? record.sensorReadings
        : record.sensorReadings.where((s) => s.nodeId == _selectedSensor).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              _formatDate(record.timestamp),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Sensor readings
          ...readings.map((sensor) {
            final condition = _getCondition(sensor.moisture);
            final color = _getConditionColor(sensor.moisture);
            final trend = _getTrend(sensor.moisture, record.previousMoistureMap[sensor.nodeId]);
            
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sensor.nodeId.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color),
                        ),
                        child: Text(condition, style: TextStyle(color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text('${sensor.moisture}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Moisture', style: TextStyle(fontSize: 12)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(trend['icon'], style: TextStyle(color: trend['color'])),
                                const SizedBox(width: 4),
                                Text(trend['text'], style: TextStyle(color: trend['color'], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              record.temperature > 0 ? '${record.temperature.toInt()}°C' : '--',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('Temp', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              record.humidity > 0 ? '${record.humidity.toInt()}%' : '--',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text('Humidity', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text('Page $_currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }
}

// Data models
class SensorReading {
  final String nodeId;
  final int moisture;
  
  SensorReading({required this.nodeId, required this.moisture});
}

class HistoryRecord {
  final String id;
  final DateTime timestamp;
  final List<SensorReading> sensorReadings;
  final double temperature;
  final double humidity;
  final Map<String, int> previousMoistureMap;
  
  HistoryRecord({
    required this.id,
    required this.timestamp,
    required this.sensorReadings,
    required this.temperature,
    required this.humidity,
  }) : previousMoistureMap = {};
}