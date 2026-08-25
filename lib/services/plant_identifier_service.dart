import 'dart:convert';
import 'dart:typed_data'; // Add this import
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantIdentifierService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }
  
  Future<Map<String, dynamic>> identifyPlant(List<int> imageBytes, String mimeType) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
      );
      
      final prompt = '''You are a plant identification expert for Philippine home gardening. Analyze this image and identify the plant.

If the image shows a plant (leaf, flower, tree, herb, etc.), provide:

1. Plant name (common Filipino name if available, otherwise English)
2. Scientific name
3. Brief description of the plant
4. Complete care guide including:
   - Light requirements
   - Watering frequency
   - Ideal temperature range
   - Humidity preferences
   - Soil type
   - Fertilizer needs
   - Pro tips for beginners
   - Common problems to watch for

If the image does NOT show a plant, respond with:
{
  "error": true,
  "message": "Image unidentified. Please provide an image of a plant."
}

Format your response as JSON only, no other text:
{
  "name": "Plant Name",
  "scientificName": "Scientific name",
  "description": "Brief plant description",
  "care": {
    "light": "Light requirements",
    "water": "Watering frequency and amount",
    "temperature": "Ideal temperature range in °C",
    "humidity": "Humidity preferences",
    "soil": "Soil type and pH preferences",
    "fertilizer": "Fertilizer type and frequency",
    "tips": "Pro tips for beginners",
    "commonProblems": "Common issues to watch for"
  }
}''';

      // Convert List<int> to Uint8List
      final uint8List = Uint8List.fromList(imageBytes);

      final response = await model.generateContent([
        Content.text(prompt),
        Content.data(mimeType, uint8List),
      ]);
      
      if (response.text == null) {
        throw Exception('No response from AI');
      }
      
      final responseText = response.text!;
      
      // Clean the response (remove markdown code blocks)
      String cleaned = responseText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();
      
      final data = json.decode(cleaned);
      
      if (data['error'] == true) {
        throw Exception(data['message'] ?? 'No plant detected');
      }
      
      return data;
    } catch (e) {
      print('Plant identification error: $e');
      throw Exception('Failed to identify plant. Please try again.');
    }
  }
}