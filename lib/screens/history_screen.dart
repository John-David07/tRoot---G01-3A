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
  List<HistoryRecord> _filteredHistory = [];
  bool _loading = true;
  String _selectedSensor = 'all';
  int _currentPage = 1;
  final int _recordsPerPage = 10;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  DateTime _parseDateFromString(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);

    try {
      final database = FirebaseDatabase.instance;
      final soilSnapshot = await database.ref('History/soil_sensor').get();
      final tempSnapshot = await database.ref('History/temperature').get();
      final humiditySnapshot = await database.ref('History/humidity').get();

      if (!soilSnapshot.exists) {
        setState(() => _loading = false);
        return;
      }

      final soilData = soilSnapshot.value as Map<dynamic, dynamic>? ?? {};
      final tempData = tempSnapshot.value as Map<dynamic, dynamic>? ?? {};
      final humidityData = humiditySnapshot.value as Map<dynamic, dynamic>? ?? {};

      final sensors = ['node_1', 'node_2', 'node_3', 'node_4', 'node_5'];
      final historyMap = <DateTime, HistoryRecord>{};

      for (var sensor in sensors) {
        final sensorData = soilData[sensor];
        if (sensorData is Map) {
          sensorData.forEach((pushId, entry) {
            if (entry is Map && entry.containsKey('value') && entry.containsKey('time')) {
              final timeStr = entry['time'].toString();
              final dateTime = _parseDateFromString(timeStr);
              final moistureValue = entry['value'] is int ? entry['value'] : 0;

              if (!historyMap.containsKey(dateTime)) {
                historyMap[dateTime] = HistoryRecord(
                  timestamp: dateTime,
                  sensorReadings: [],
                  temperature: 0,
                  humidity: 0,
                );
              }

              historyMap[dateTime]!.sensorReadings.add(
                SensorReading(
                  nodeId: sensor.replaceFirst('node_', 'Node_'),
                  moisture: moistureValue,
                ),
              );
            }
          });
        }
      }

      for (var entry in tempData.entries) {
        if (entry.value is Map && (entry.value as Map).containsKey('value')) {
          final timeStr = (entry.value as Map)['time'].toString();
          final dateTime = _parseDateFromString(timeStr);
          final tempValue = (entry.value as Map)['value'] is num 
              ? ((entry.value as Map)['value'] as num).toDouble() 
              : 0.0;
          
          if (historyMap.containsKey(dateTime)) {
            historyMap[dateTime]!.temperature = tempValue;
          }
        }
      }

      for (var entry in humidityData.entries) {
        if (entry.value is Map && (entry.value as Map).containsKey('value')) {
          final timeStr = (entry.value as Map)['time'].toString();
          final dateTime = _parseDateFromString(timeStr);
          final humidityValue = (entry.value as Map)['value'] is num 
              ? ((entry.value as Map)['value'] as num).toDouble() 
              : 0.0;
          
          if (historyMap.containsKey(dateTime)) {
            historyMap[dateTime]!.humidity = humidityValue;
          }
        }
      }

      var historyList = historyMap.values.toList();
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (int i = 0; i < historyList.length; i++) {
        final older = i + 1 < historyList.length ? historyList[i + 1] : null;
        if (older != null) {
          for (var reading in older.sensorReadings) {
            historyList[i].previousMoistureMap[reading.nodeId] = reading.moisture;
          }
        }
      }

      setState(() {
        _history = historyList;
        _filteredHistory = historyList;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching history: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<HistoryRecord>.from(_history);

    if (_selectedSensor != 'all') {
      filtered = filtered.where((record) =>
        record.sensorReadings.any((s) => s.nodeId == _selectedSensor)
      ).toList();
    }

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

    setState(() {
      _filteredHistory = filtered;
      _currentPage = 1;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSensor = 'all';
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
      _filteredHistory = _history;
    });
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
    if (previous == null) return {'icon': '●', 'color': Colors.grey, 'text': '0%', 'change': 0};
    final change = current - previous;
    if (change > 0) return {'icon': '▲', 'color': Colors.green, 'text': '+$change%', 'change': change};
    if (change < 0) return {'icon': '▼', 'color': Colors.red, 'text': '$change%', 'change': change};
    return {'icon': '●', 'color': Colors.grey, 'text': '0%', 'change': 0};
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredHistory.length / _recordsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _recordsPerPage;
    final endIndex = startIndex + _recordsPerPage;
    final currentRecords = _filteredHistory.length > startIndex
        ? _filteredHistory.sublist(startIndex, endIndex > _filteredHistory.length ? _filteredHistory.length : endIndex)
        : [];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : currentRecords.isEmpty
                    ? const Center(child: Text('No records match your filters'))
                    : ListView.builder(
                        itemCount: currentRecords.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryCard(currentRecords[index], isDarkMode);
                        },
                      ),
          ),
          if (totalPages > 1) _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final sensors = ['all', 'Node_1', 'Node_2', 'Node_3', 'Node_4', 'Node_5'];

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSensor,
            decoration: const InputDecoration(labelText: 'Sensor', border: OutlineInputBorder()),
            items: sensors.map((s) => DropdownMenuItem(value: s, child: Text(s == 'all' ? 'All Sensors' : s))).toList(),
            onChanged: (value) => setState(() {
              _selectedSensor = value!;
              _applyFilters();
            }),
          ),
          const SizedBox(height: 8),
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
                    if (date != null) {
                      _startDate = date;
                      _applyFilters();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'From Date', border: OutlineInputBorder()),
                    child: Text(_startDate != null ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}' : 'Select date'),
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
                    if (date != null) {
                      _endDate = date;
                      _applyFilters();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'To Date', border: OutlineInputBorder()),
                    child: Text(_endDate != null ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}' : 'Select date'),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedSensor != 'all' || _startDate != null || _endDate != null)
            const SizedBox(height: 8),
          if (_selectedSensor != 'all' || _startDate != null || _endDate != null)
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black),
              child: const Text('Clear All Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryRecord record, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Text(
              _formatDate(record.timestamp),
              style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
          ...record.sensorReadings
              .where((s) => _selectedSensor == 'all' || s.nodeId == _selectedSensor)
              .map((sensor) {
            final status = _getCondition(sensor.moisture);
            final color = _getConditionColor(sensor.moisture);
            final trend = _getTrend(sensor.moisture, record.previousMoistureMap[sensor.nodeId]);
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sensor.nodeId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color),
                        ),
                        child: Text(status, style: TextStyle(color: color, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(record.temperature > 0 ? '${record.temperature.toInt()}°C' : '--', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Temp', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(record.humidity > 0 ? '${record.humidity.toInt()}%' : '--', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Humidity', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
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
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Text('Page $_currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}

class SensorReading {
  final String nodeId;
  final int moisture;
  SensorReading({required this.nodeId, required this.moisture});
}

class HistoryRecord {
  final DateTime timestamp;
  final List<SensorReading> sensorReadings;
  double temperature;
  double humidity;
  final Map<String, int> previousMoistureMap;

  HistoryRecord({
    required this.timestamp,
    required this.sensorReadings,
    required this.temperature,
    required this.humidity,
  }) : previousMoistureMap = {};
}