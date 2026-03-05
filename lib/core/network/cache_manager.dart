import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _cachePrefix = 'cache_';

  /// Saves data to local storage with a key based on the URL.
  static Future<void> saveData(String url, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cachePrefix$url';

    String jsonString;
    if (data is String) {
      jsonString = data;
    } else {
      jsonString = jsonEncode(data);
    }

    await prefs.setString(key, jsonString);
  }

  /// Retrieves data from local storage for a specific URL.
  static Future<dynamic> getData(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cachePrefix$url';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString);
    } catch (_) {
      return jsonString;
    }
  }

  /// Clears all cached API data.
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
