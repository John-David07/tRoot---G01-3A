import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// Public URL of the Vercel deployment (the same backend the web app uses).
  /// This is NOT a secret. Override per build if needed:
  ///   flutter build apk --dart-define=API_BASE_URL=https://your-app.vercel.app
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://YOUR-APP.vercel.app', // TODO: put your real Vercel URL
  );
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// All calls to the backend go through here, so the app never needs the
/// Gemini or Unsplash keys. The keys live only in Vercel's environment variables.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 60);

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handle(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  /// Uploads one image as multipart form data under the field name "image",
  /// which is what the Next.js routes expect.
  static Future<Map<String, dynamic>> postImage(
    String path,
    List<int> bytes, {
    String filename = 'upload.jpg',
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path))
        ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handle(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  static Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      // Non-JSON body (for example an HTML error page from the host).
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && data != null) return data;

    final err = data?['error'];
    final serverMessage = err is String ? err : null;
    throw ApiException(
      serverMessage ?? _defaultMessage(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  static String _defaultMessage(int status) {
    switch (status) {
      case 413:
        return 'Image is too large. Maximum size is 4 MB.';
      case 415:
        return 'Only PNG and JPEG images are allowed.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return 'Server error ($status). Please try again.';
    }
  }
}
