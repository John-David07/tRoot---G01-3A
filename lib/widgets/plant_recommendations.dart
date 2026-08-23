import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/gemini_service.dart';
import '../services/recommendation_cache_service.dart';
import '../services/recommendation_history_service.dart';
import '../models/recommendation_history.dart';
import '../utils/theme_manager.dart';
import 'plant_care_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantRecommendations extends StatefulWidget {
  final int moisture;
  final double ph;
  final double temperature;
  final double humidity;
  final String sensorId;

  const PlantRecommendations({
    super.key,
    required this.moisture,
    required this.ph,
    required this.temperature,
    required this.humidity,
    required this.sensorId,
  });

  @override
  State<PlantRecommendations> createState() => _PlantRecommendationsState();
}

class _PlantRecommendationsState extends State<PlantRecommendations> {
  final GeminiService _geminiService = GeminiService();
  final RecommendationCacheService _cacheService = RecommendationCacheService();
  final RecommendationHistoryService _historyService = RecommendationHistoryService();
  
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, String> _plantImages = {};
  bool _isLoading = false;
  bool _isAiMode = true;
  int _currentIndex = 0;
  
  final List<String> _invalidPlantTerms = [
    'machine', 'singing', 'dancing', 'computer', 'robot', 'device', 'app', 'software', 'company'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<String?> _fetchPlantImage(String plantName) async {
    // Check cache first
    final cached = await _cacheService.getCachedPlantImage(plantName);
    if (cached != null) return cached;
    
    try {
      // Try loading from Unsplash using a simpler approach
      // Use the free API without key for testing (limited)
      final query = Uri.encodeComponent('$plantName plant');
      
      // Try using a free image API as fallback
      final url = 'https://api.unsplash.com/search/photos?query=$query&per_page=1';
      
      // Get key from environment
      final accessKey = dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '';
      
      if (accessKey.isEmpty) {
        // If no key, use a placeholder service
        print('No Unsplash API key found, using placeholder');
        return null;
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Client-ID $accessKey'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final imageUrl = data['results'][0]['urls']['small'];
          await _cacheService.cachePlantImage(plantName, imageUrl);
          return imageUrl;
        }
      }
      return null;
    } catch (e) {
      print('Failed to fetch plant image: $e');
      return null;
    }
  }

  bool _isValidPlant(Map<String, dynamic> plant) {
    final name = (plant['name'] as String?)?.toLowerCase() ?? '';
    final scientificName = (plant['scientificName'] as String?)?.toLowerCase() ?? '';
    
    final hasInvalidTerm = _invalidPlantTerms.any((term) => 
      name.contains(term) || scientificName.contains(term)
    );
    
    final isValidLength = name.length > 2;
    final hasPlantKeywords = ['plant', 'flower', 'leaf', 'tree', 'fern', 'palm', 'bamboo', 'orchid', 'rose', 'lily', 'cactus', 'succulent', 'ivy', 'vine', 'herb', 'shrub'].any((keyword) => 
      name.contains(keyword) || scientificName.contains(keyword)
    );
    
    return !hasInvalidTerm && isValidLength && (hasPlantKeywords || (plant['scientificName']?.length ?? 0) > 3);
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);
    
    final cached = await _cacheService.getCachedRecommendations(
      sensorId: widget.sensorId,
      moisture: widget.moisture,
      ph: widget.ph,
      temperature: widget.temperature,
      humidity: widget.humidity,
    );
    
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _recommendations = cached;
        _isAiMode = true;
        _isLoading = false;
      });
      
      for (var plant in cached) {
        final imageUrl = await _fetchPlantImage(plant['name']);
        if (imageUrl != null) {
          setState(() {
            _plantImages[plant['name']] = imageUrl;
          });
        }
      }
      return;
    }
    
    try {
      final result = await _geminiService.getRecommendations(
        moisture: widget.moisture,
        temperature: widget.temperature,
        humidity: widget.humidity,
      );
      
      if (result.recommendations.isNotEmpty) {
        final validRecommendations = result.recommendations.where(_isValidPlant).toList();
        
        setState(() {
          _recommendations = validRecommendations.isNotEmpty ? validRecommendations : result.recommendations;
          _isAiMode = !result.isFallback;
          _currentIndex = 0;
        });
        
        await _cacheService.cacheRecommendations(
          sensorId: widget.sensorId,
          moisture: widget.moisture,
          ph: widget.ph,
          temperature: widget.temperature,
          humidity: widget.humidity,
          recommendations: _recommendations,
        );
        
        for (var plant in _recommendations) {
          final imageUrl = await _fetchPlantImage(plant['name']);
          if (imageUrl != null) {
            setState(() {
              _plantImages[plant['name']] = imageUrl;
            });
          }
        }
        
        final existingHistory = await _historyService.getHistoryForSensor(widget.sensorId);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final hasTodayEntry = existingHistory.any((entry) => 
          entry.dateRecommended.toIso8601String().substring(0, 10) == today
        );
        
        if (!hasTodayEntry) {
          for (var plant in _recommendations) {
            final entry = RecommendationHistoryEntry(
              name: plant['name'] ?? 'Unknown Plant',
              scientificName: plant['scientificName'] ?? '',
              reason: plant['reason'] ?? '',
              dateRecommended: DateTime.now(),
              moisture: widget.moisture,
              ph: widget.ph,
              moistureStatus: widget.moisture > 80 ? 'Saturated' : widget.moisture > 40 ? 'Optimal' : 'Dry',
              temperature: widget.temperature,
              humidity: widget.humidity,
            );
            await _historyService.addHistoryEntry(widget.sensorId, entry);
          }
        }
      } else {
        setState(() {
          _recommendations = [];
          _isAiMode = false;
        });
      }
    } catch (e) {
      print('Error fetching recommendations: $e');
      setState(() {
        _recommendations = [];
        _isAiMode = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openImageModal(String imageUrl, String plantName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plantName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 400,
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
        ),
        color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('AI is generating recommendations...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
        ),
        color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No recommendations available')),
        ),
      );
    }

    final plant = _recommendations[_currentIndex];
    final plantImage = _plantImages[plant['name']];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ThemeManager.primaryColor, width: 1),
      ),
      color: isDarkMode ? const Color(0xFF1f2937) : Colors.white,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => PlantCareDialog(
              plantName: plant['name'] ?? 'Unknown Plant',
              scientificName: plant['scientificName'] ?? '',
              careData: plant['care'] as Map<String, dynamic>?,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'A.I. Plant Recommendation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeManager.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap for care',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plantImage != null)
                    GestureDetector(
                      onTap: () => _openImageModal(plantImage, plant['name'] ?? 'Plant'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          plantImage,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.photo, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                  if (plantImage != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant['name'] ?? 'Unknown Plant',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plant['scientificName'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plant['reason'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    '${_currentIndex + 1} of ${_recommendations.length}',
                    style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentIndex < _recommendations.length - 1
                        ? () => setState(() => _currentIndex++)
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_recommendations.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? ThemeManager.primaryColor : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isAiMode 
                  ? '🤖 AI-powered • Tap for care guide'
                  : '⚠️ AI service busy. Showing fallback.',
                style: TextStyle(
                  fontSize: 10,
                  color: _isAiMode 
                    ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
                    : Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}