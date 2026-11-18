import 'api_client.dart';

class PlantIdentifierService {
  // mimeType is kept so existing callers don't change. The server checks the
  // real file type itself and does not trust the value sent by the client.
  Future<Map<String, dynamic>> identifyPlant(List<int> imageBytes, String mimeType) async {
    try {
      final data = await ApiClient.postImage('/api/plant-identify', imageBytes);

      final plant = data['plantData'];
      if (plant is Map<String, dynamic>) return plant;
      throw Exception('No response from server');
    } on ApiException catch (e) {
      // Includes "Image unidentified. Please provide an image of a plant."
      throw Exception(e.message);
    } catch (e) {
      print('Plant identification error: $e');
      throw Exception('Failed to identify plant. Please try again.');
    }
  }
}
