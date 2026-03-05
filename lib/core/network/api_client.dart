import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_project/core/network/cache_manager.dart';

class ApiClient {
  /// GET request helper.
  static Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json', ...?headers})
          .timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);

      // Save to cache for offline access
      await CacheManager.saveData(url, data);

      return data;
    } catch (e) {
      // If network fails (offline), try to return cached data
      final cachedData = await CacheManager.getData(url);
      if (cachedData != null) {
        return cachedData;
      }

      // If no cache, rethrow error
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST request helper.
  static Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// PUT request helper.
  static Future<dynamic> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);

    try {
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request helper.
  static Future<dynamic> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);

    try {
      final response = await http
          .delete(uri, headers: {'Accept': 'application/json', ...?headers})
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      String message = 'Error ${response.statusCode}';
      if (data is Map) {
        message = data['message'] ?? data['error'] ?? message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
      throw Exception(message);
    }
  }
}
