import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

// Add this class to return both recommendations and a flag
class RecommendationResult {
  final List<Map<String, dynamic>> recommendations;
  final bool isFallback;
  
  RecommendationResult({required this.recommendations, required this.isFallback});
}

/// Despite the name, this service no longer talks to Gemini directly.
/// It calls the Vercel backend, which holds the Gemini key and enforces
/// rate limits and upload checks.
class GeminiService {
  Future<RecommendationResult> getRecommendations({
    required int moisture,
    required double ph,
    required double temperature,
    required double humidity,
  }) async {
    try {
      final data = await ApiClient.postJson('/api/recommendations', {
        'moisture': moisture,
        'ph': ph,
        'temperature': temperature,
        'humidity': humidity,
      });

      final raw = data['recommendations'];
      if (raw is List && raw.isNotEmpty) {
        return RecommendationResult(
          recommendations: List<Map<String, dynamic>>.from(raw),
          isFallback: data['isFallback'] == true,
        );
      }
      return RecommendationResult(
        recommendations: _getFallbackRecommendations(),
        isFallback: true,
      );
    } catch (e) {
      print('Recommendations error: $e');
      return RecommendationResult(
        recommendations: _getFallbackRecommendations(),
        isFallback: true,
      );
    }
  }
  
  Future<Map<String, String>> getSoilInfoFromImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await ApiClient.postImage('/api/soil-identifier', bytes);

      final soil = data['soilData'];
      if (soil is! Map) {
        return {'error': 'true', 'message': 'Unable to analyze image'};
      }

      return {
        'name': (soil['name'] ?? 'Unknown Soil').toString(),
        'description': (soil['description'] ?? 'No description available').toString(),
        'bestFor': (soil['bestFor'] ?? 'Various plants').toString(),
        'drainage': (soil['drainage'] ?? 'Moderate').toString(),
        'nutrients': (soil['nutrients'] ?? 'Medium').toString(),
      };
    } on ApiException catch (e) {
      // Includes the server's "Image unidentified..." message for non-soil photos.
      return {'error': 'true', 'message': e.message};
    } catch (e) {
      print('Soil identification error: $e');
      return {'error': 'true', 'message': 'Failed to analyze image'};
    }
  }
  
  List<Map<String, dynamic>> _getFallbackRecommendations() {
  const invalidPlantTerms = ['machine', 'singing', 'dancing', 'computer', 'robot', 'device', 'app', 'software', 'company'];
  
  final fallback = [
    {
      'name': 'Snake Plant',
      'scientificName': 'Sansevieria trifasciata',
      'reason': 'Extremely adaptable and tolerates a wide range of conditions.',
      'care': {
        'light': 'Low to bright indirect light. Avoid direct sunlight.',
        'water': 'Water every 2-6 weeks. Let soil dry completely between waterings.',
        'temperature': '18-27°C (65-80°F)',
        'humidity': 'Low to moderate. Very adaptable.',
        'soil': 'Well-draining cactus/succulent mix. pH 6.0-7.5',
        'fertilizer': 'Fertilize once in spring and summer with cactus fertilizer.',
        'tips': 'Very hard to kill! Perfect for beginners. Wipe leaves occasionally.',
        'commonProblems': 'Overwatering (yellow leaves), Cold damage, Root rot'
      }
    },
    {
      'name': 'ZZ Plant',
      'scientificName': 'Zamioculcas zamiifolia',
      'reason': 'Survives in low light and irregular watering schedules.',
      'care': {
        'light': 'Low to bright indirect light. Very shade tolerant.',
        'water': 'Water every 2-3 weeks. Allow soil to dry completely.',
        'temperature': '18-24°C (65-75°F)',
        'humidity': 'Low to high. Very adaptable.',
        'soil': 'Well-draining potting mix with perlite. pH 6.0-7.0',
        'fertilizer': 'Fertilize 2-3 times per year with balanced fertilizer.',
        'tips': 'Drought tolerant. Wipe leaves to keep them shiny.',
        'commonProblems': 'Yellow leaves (overwatering), Root rot, Slow growth'
      }
    },
    {
      'name': 'Pothos',
      'scientificName': 'Epipremnum aureum',
      'reason': 'Very forgiving plant that adapts to most indoor environments.',
      'care': {
        'light': 'Low to bright indirect light. Variegation needs more light.',
        'water': 'Water when top 2 inches of soil are dry.',
        'temperature': '18-29°C (65-85°F)',
        'humidity': 'Moderate to high. Benefits from occasional misting.',
        'soil': 'Well-draining potting mix. pH 6.0-7.0',
        'fertilizer': 'Fertilize monthly during growing season.',
        'tips': 'Trailing or climbing. Propagate easily from cuttings.',
        'commonProblems': 'Brown leaves (underwatering), Yellow leaves (overwatering), Leggy growth (not enough light)'
      }
    }
  ];
  
  // Filter out invalid names from fallback
  return fallback.where((plant) {
    final name = (plant['name'] as String?)?.toLowerCase() ?? '';
    return !invalidPlantTerms.any((term) => name.contains(term));
  }).toList();
}
}