import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDUc-aMT5E6935GDChaxvrt-hGQpXpgWAE';

  Future<List<Map<String, dynamic>>> getRecommendations({
    required int moisture,
    required double temperature,
    required double humidity,
  }) async {
    print('🔵 getRecommendations called with: moisture=$moisture, temp=$temperature, humidity=$humidity');
    
    try {
      print('🟢 Creating GenerativeModel...');
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
You are a plant recommendation expert for Philippine home gardening. Based on the following environmental conditions, recommend 3 indoor plants.

Conditions:
- Soil Moisture: $moisture%
- Temperature: ${temperature.toStringAsFixed(1)}°C
- Humidity: ${humidity.toStringAsFixed(1)}%

Return ONLY valid JSON in this exact format:
[
  {
    "name": "Plant Name",
    "scientificName": "Scientificus name",
    "reason": "Brief reason."
  }
]
''';

      print('🟢 Sending prompt to Gemini...');
      final response = await model.generateContent([Content.text(prompt)]);
      print('🟢 Response received: ${response.text}');

      if (response.text == null) {
        print('🔴 Response text is null');
        return _getFallbackRecommendations();
      }

      final recommendations = _parseRecommendations(response.text!);
      print('🟢 Parsed recommendations: $recommendations');
      
      return recommendations.isNotEmpty ? recommendations : _getFallbackRecommendations();
    } catch (e) {
      print('🔴 Gemini API error: $e');
      return _getFallbackRecommendations();
    }
  }

  List<Map<String, dynamic>> _parseRecommendations(String responseText) {
    try {
      print('🟢 Parsing response: $responseText');
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
      print('🔴 Parse error: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _getFallbackRecommendations() {
    print('🟡 Using fallback recommendations');
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