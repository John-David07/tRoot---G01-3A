import 'dart:convert';
import 'dart:typed_data';
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
  
  Future<Map<String, String>> getPlantCareFromImage(XFile imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
      );
      
      final bytes = await imageFile.readAsBytes();
      
      final prompt = '''
You are a plant care expert for Philippine home gardening. Identify this plant from the image and provide:

1. Plant name (common Filipino name if available)
2. Scientific name
3. Care instructions including:
   - Watering frequency
   - Sunlight requirements
   - Ideal temperature range
   - Humidity preference
   - Soil type
   - Common issues to watch for

Format your response as JSON:
{
  "name": "Plant Name",
  "scientificName": "Scientific name",
  "watering": "Watering instructions",
  "sunlight": "Sunlight requirements",
  "temperature": "Ideal temperature range",
  "humidity": "Humidity preference",
  "soil": "Soil type recommendation",
  "commonIssues": "Common problems and solutions"
}
''';
      
      final response = await model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', bytes),
      ]);
      
      if (response.text == null) {
        return _getFallbackCare();
      }
      
      return _parseCareResponse(response.text!);
    } catch (e) {
      print('Plant care error: $e');
      return _getFallbackCare();
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
  
  Map<String, String> _parseCareResponse(String responseText) {
    try {
      String cleaned = responseText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();
      
      final decoded = json.decode(cleaned);
      return {
        'name': decoded['name'] ?? 'Unknown Plant',
        'scientificName': decoded['scientificName'] ?? '',
        'watering': decoded['watering'] ?? 'Water when soil is dry',
        'sunlight': decoded['sunlight'] ?? 'Bright indirect light',
        'temperature': decoded['temperature'] ?? '18-28°C',
        'humidity': decoded['humidity'] ?? 'Moderate (40-60%)',
        'soil': decoded['soil'] ?? 'Well-draining potting mix',
        'commonIssues': decoded['commonIssues'] ?? 'Overwatering, pests',
      };
    } catch (e) {
      print('Parse error: $e');
      return _getFallbackCare();
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
  
  Map<String, String> _getFallbackCare() {
    return {
      'name': 'Unable to identify',
      'scientificName': '',
      'watering': 'Water when topsoil feels dry',
      'sunlight': 'Bright indirect sunlight',
      'temperature': '18-28°C',
      'humidity': '40-60%',
      'soil': 'Well-draining potting mix',
      'commonIssues': 'Watch for yellowing leaves or pests',
    };
  }
}