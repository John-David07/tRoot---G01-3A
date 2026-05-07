import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }
  
  Future<List<Map<String, dynamic>>> getRecommendations({
    required int moisture,
    required double temperature,
    required double humidity,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
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

Return ONLY valid JSON in this exact format:
[
  {
    "name": "Plant Name",
    "scientificName": "Scientificus name",
    "reason": "Brief reason why this plant matches the conditions."
  }
]
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        return _getFallbackRecommendations();
      }

      final recommendations = _parseRecommendations(response.text!);
      return recommendations.isNotEmpty ? recommendations : _getFallbackRecommendations();
    } catch (e) {
      print('Recommendations error: $e');
      return _getFallbackRecommendations();
    }
  }
  
  Future<Map<String, String>> getSoilInfoFromImage(XFile imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
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
        'reason': 'Extremely adaptable and tolerates a wide range of conditions.'
      },
      {
        'name': 'ZZ Plant',
        'scientificName': 'Zamioculcas zamiifolia',
        'reason': 'Survives in low light and irregular watering schedules.'
      },
      {
        'name': 'Pothos',
        'scientificName': 'Epipremnum aureum',
        'reason': 'Very forgiving plant that adapts to most indoor environments.'
      },
    ];
  }
}