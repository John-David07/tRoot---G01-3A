import 'package:flutter/material.dart';
import '../services/recommendation_history_service.dart';
import '../models/recommendation_history.dart';
import '../utils/theme_manager.dart';

class RecommendationHistoryWidget extends StatefulWidget {
  final String sensorId;
  final VoidCallback? onResetHistory;

  const RecommendationHistoryWidget({
    super.key,
    required this.sensorId,
    this.onResetHistory,
  });

  @override
  State<RecommendationHistoryWidget> createState() =>
      _RecommendationHistoryWidgetState();
}

class _RecommendationHistoryWidgetState
    extends State<RecommendationHistoryWidget> {
  final RecommendationHistoryService _historyService =
      RecommendationHistoryService();
  List<RecommendationHistoryEntry> _history = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(RecommendationHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sensorId != widget.sensorId) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyService.getHistoryForSensor(widget.sensorId);
    setState(() {
      _history = history;
      _isLoading = false;
      _currentPage = 0;
    });
  }

  int get _totalPages => (_history.length / _itemsPerPage).ceil();

  List<RecommendationHistoryEntry> get _currentPageItems {
    final start = _currentPage * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= _history.length) return [];
    return _history.sublist(
      start,
      end > _history.length ? _history.length : end,
    );
  }

  Color _getMoistureStatusColor(String status, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case 'Saturated':
        return isDarkMode ? Colors.lightBlueAccent : Colors.blue;
      case 'Optimal':
        return ThemeManager.primaryColor;
      case 'Dry':
        return isDarkMode ? Colors.orangeAccent : Colors.orange;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistoryForSensor(widget.sensorId);
    await _loadHistory();
    widget.onResetHistory?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recommendation history cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plant Recommendation History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (_history.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: isDarkMode ? Colors.redAccent : Colors.red,
                    ),
                    onPressed: _clearHistory,
                    tooltip: 'Clear history',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last ${_history.length} recommendations',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No recommendation history yet',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI recommendations will appear here when generated',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.grey.shade500
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ..._currentPageItems.map(
                    (entry) => _buildHistoryItem(entry, context),
                  ),
                  if (_totalPages > 1) _buildPagination(isDarkMode),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    RecommendationHistoryEntry entry,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getMoistureStatusColor(entry.moistureStatus, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111827) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      entry.scientificName,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  entry.moistureStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(entry.dateRecommended),
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChip(
                Icons.water_drop,
                '${entry.moisture}%',
                Colors.blue,
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildChip(
                Icons.thermostat,
                '${entry.temperature.toInt()}°C',
                Colors.red,
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildChip(
                Icons.opacity,
                '${entry.humidity.toInt()}%',
                Colors.teal,
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color, bool isDarkMode) {
    final chipColor = isDarkMode
        ? color.withOpacity(0.3)
        : color.withOpacity(0.1);
    final textColor = isDarkMode ? color : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Text(
            '${_currentPage + 1} / $_totalPages',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
