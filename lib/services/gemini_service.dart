import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Add this class to return both recommendations and a flag
class RecommendationResult {
  final List<Map<String, dynamic>> recommendations;
  final bool isFallback;
  
  RecommendationResult({required this.recommendations, required this.isFallback});
}

class GeminiService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }
  
  Future<RecommendationResult> getRecommendations({
    required int moisture,
    required double temperature,
    required double humidity,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
You are a plant recommendation expert for Philippine home gardening. Based on the following environmental conditions, recommend 3 indoor plants that are:

REQUIREMENTS:
- Native or common to the Philippines
- Easily available in local nurseries
- Popular among Filipino plant enthusiasts
- Suitable for indoor growing in tropical climate

Conditions:
- Soil Moisture: $moisture%
- Temperature: ${temperature.toStringAsFixed(1)}°C
- Humidity: ${humidity.toStringAsFixed(1)}%

For each plant, provide:
1. Plant name
2. Scientific name
3. One sentence explaining why it matches these conditions
4. Complete plant care guide including:
   - Light requirements
   - Watering frequency
   - Ideal temperature range
   - Humidity preferences
   - Soil type
   - Fertilizer needs
   - Pro tips for beginners
   - Common problems to watch for

Return ONLY valid JSON in this exact format:
[
  {
    "name": "Plant Name",
    "scientificName": "Scientificus name",
    "reason": "Brief reason why this plant matches the conditions.",
    "care": {
      "light": "Light requirements",
      "water": "Watering frequency and amount",
      "temperature": "Ideal temperature range in °C",
      "humidity": "Humidity preferences",
      "soil": "Soil type and mix recommendations",
      "fertilizer": "Fertilizer type and frequency",
      "tips": "Pro tips for beginners",
      "commonProblems": "Common issues to watch for (as a comma-separated string)"
    }
  }
]
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        return RecommendationResult(
          recommendations: _getFallbackRecommendations(),
          isFallback: true,
        );
      }

      final recommendations = _parseRecommendations(response.text!);
      if (recommendations.isNotEmpty) {
        return RecommendationResult(
          recommendations: recommendations,
          isFallback: false,
        );
      } else {
        return RecommendationResult(
          recommendations: _getFallbackRecommendations(),
          isFallback: true,
        );
      }
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
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
      
      final bytes = await imageFile.readAsBytes();
      
      final prompt = '''
You are a soil identification expert. Analyze this image and determine if it shows soil.

If the image shows soil (any type: clay, sandy, loamy, potting mix, garden soil, etc.), provide:

1. Soil type name
2. Brief description of this soil type
3. Best for: What plants thrive in this soil
4. Drainage: Fast, moderate, or poor
5. Nutrients: High, medium, or low

If the image does NOT show soil (grass, rocks, plants, roots, people, animals, etc.), respond with:
{
  "error": true,
  "message": "Image unidentified. Please provide an image of soil or any kind of it."
}

Format your response as JSON only, no other text:
{
  "name": "Soil Type Name",
  "description": "Brief description",
  "bestFor": "What plants thrive here",
  "drainage": "Fast/Moderate/Poor",
  "nutrients": "High/Medium/Low"
}

Or for invalid images:
{
  "error": true,
  "message": "Image unidentified. Please provide an image of soil or any kind of it."
}
''';
      
      final response = await model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', bytes),
      ]);
      
      if (response.text == null) {
        return {'error': 'true', 'message': 'Unable to analyze image'};
      }
      
      return _parseSoilResponse(response.text!);
    } catch (e) {
      print('Soil identification error: $e');
      return {'error': 'true', 'message': 'Failed to analyze image'};
    }
  }
  
  List<Map<String, dynamic>> _parseRecommendations(String responseText) {
    try {
      String cleaned = responseText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final decoded = json.decode(cleaned);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      print('Parse error: $e');
      return [];
    }
  }
  
  Map<String, String> _parseSoilResponse(String responseText) {
    try {
      String cleaned = responseText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final decoded = json.decode(cleaned);
      
      if (decoded['error'] == true) {
        return {'error': 'true', 'message': decoded['message'] ?? 'Unknown error'};
      }
      
      return {
        'name': decoded['name'] ?? 'Unknown Soil',
        'description': decoded['description'] ?? 'No description available',
        'bestFor': decoded['bestFor'] ?? 'Various plants',
        'drainage': decoded['drainage'] ?? 'Moderate',
        'nutrients': decoded['nutrients'] ?? 'Medium',
      };
    } catch (e) {
      print('Parse error: $e');
      return {'error': 'true', 'message': 'Failed to parse response'};
    }
  }
  
  List<Map<String, dynamic>> _getFallbackRecommendations() {
    return [
      {
        'name': 'Snake Plant',
        'scientificName': 'Sansevieria trifasciata',
        'reason': 'Extremely adaptable and tolerates a wide range of conditions.',
        'care': {
          'light': 'Low to bright indirect light. Avoid direct sunlight.',
          'water': 'Water every 2-6 weeks. Let soil dry completely between waterings.',
          'temperature': '18-27°C (65-80°F)',
          'humidity': 'Low to moderate. Very adaptable.',
          'soil': 'Well-draining cactus/succulent mix.',
          'fertilizer': 'Fertilize once in spring and summer with cactus fertilizer.',
          'tips': 'Very hard to kill! Perfect for beginners. Wipe leaves occasionally.',
          'commonProblems': 'Overwatering (yellow leaves), Cold damage, Root rot',
        },
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
          'soil': 'Well-draining potting mix with perlite.',
          'fertilizer': 'Fertilize 2-3 times per year with balanced fertilizer.',
          'tips': 'Drought tolerant. Wipe leaves to keep them shiny.',
          'commonProblems': 'Yellow leaves (overwatering), Root rot, Slow growth',
        },
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
          'soil': 'Well-draining potting mix.',
          'fertilizer': 'Fertilize monthly during growing season.',
          'tips': 'Trailing or climbing. Propagate easily from cuttings.',
          'commonProblems': 'Brown leaves (underwatering), Yellow leaves (overwatering), Leggy growth (not enough light)',
        },
      },
    ];
  }
}