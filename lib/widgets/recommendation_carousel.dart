import 'package:flutter/material.dart';
import '../utils/theme_manager.dart';
import 'plant_care_dialog.dart';

class RecommendationCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;

  const RecommendationCarousel({
    super.key,
    required this.recommendations,
  });

  @override
  State<RecommendationCarousel> createState() => _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<RecommendationCarousel> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(RecommendationCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendations != widget.recommendations) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  void _showPlantCareDialog() {
    final plant = widget.recommendations[_currentIndex];
    final plantName = plant['name'] ?? 'Unknown Plant';
    final scientificName = plant['scientificName'] ?? '';
    final careData = plant['care'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      builder: (context) => PlantCareDialog(
        plantName: plantName,
        scientificName: scientificName,
        careData: careData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) {
      return const Center(child: Text('No recommendations available'));
    }

    final plant = widget.recommendations[_currentIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _showPlantCareDialog,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
        ),
        color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Plant Recommendation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeManager.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Tap for care guide',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                plant['name'] ?? 'Unknown Plant',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                plant['scientificName'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,  // RESTORED: original grey color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeManager.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plant['reason'] ?? '',
                  style: const TextStyle(height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                  ),
                  Text(
                    '${_currentIndex + 1} of ${widget.recommendations.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentIndex < widget.recommendations.length - 1
                        ? () => setState(() => _currentIndex++)
                        : null,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.recommendations.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? ThemeManager.primaryColor
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}