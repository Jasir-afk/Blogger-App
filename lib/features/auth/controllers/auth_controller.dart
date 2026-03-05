import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/core/network/api_client.dart';
import 'package:test_project/core/network/api_urls.dart';
import 'package:test_project/features/auth/models/auth_model.dart';
import 'package:test_project/core/network/cache_manager.dart';

class AuthController extends GetxController {
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';
  static const _bioKey = 'auth_bio';
  static const _imageKey = 'auth_image';

  final userName = 'User'.obs;
  final userEmail = ''.obs;
  final userBio = ''.obs;
  final userProfileImage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    userName.value = await getSavedName() ?? 'User';
    userEmail.value = await getSavedEmail() ?? '';
    userBio.value = await getSavedBio() ?? '';
    userProfileImage.value = await getSavedProfileImage();
  }

  /// Calls the login API and returns an [AuthModel] on success.
  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(ApiUrls.login, {
      'email': email,
      'password': password,
    });

    final auth = AuthModel.fromJson(data);

    // Persist user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.token);
    await prefs.setString(_nameKey, auth.name);
    await prefs.setString(_emailKey, auth.email);
    await prefs.setString(_bioKey, auth.bio);
    if (auth.profileImage != null) {
      await prefs.setString(_imageKey, auth.profileImage!);
    }

    // Update reactive states
    userName.value = auth.name;
    userEmail.value = auth.email;
    userBio.value = auth.bio;
    userProfileImage.value = auth.profileImage;

    return auth;
  }

  /// Calls the registration API.
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(ApiUrls.register, {
      'name': name,
      'email': email,
      'password': password,
    });

    final auth = AuthModel.fromJson(data);

    // Persist user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.token);
    await prefs.setString(_nameKey, auth.name);
    await prefs.setString(_emailKey, auth.email);
    await prefs.setString(_bioKey, auth.bio);
    if (auth.profileImage != null) {
      await prefs.setString(_imageKey, auth.profileImage!);
    }

    // Update reactive states
    userName.value = auth.name;
    userEmail.value = auth.email;
    userBio.value = auth.bio;
    userProfileImage.value = auth.profileImage;

    return 'Registration successful';
  }

  /// Update and persist profile data (Sync with Backend)
  Future<void> saveProfileData({
    required String name,
    required String email,
    String? bio,
    String? imagePath,
  }) async {
    final token = await getSavedToken();
    if (token != null) {
      // 1. Sync with backend
      try {
        await ApiClient.put(
          '$ApiUrls.baseUrl/api/auth/profile', // Standard endpoint for profile updates
          {
            'name': name,
            'email': email,
            if (bio != null) 'bio': bio,
            if (imagePath != null && imagePath.startsWith('http'))
              'image': imagePath,
          },
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        print('Backend sync failed: $e');
        // We continue to save locally even if backend fails for offline support
      }
    }

    // 2. Persist local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);

    if (bio != null) {
      await prefs.setString(_bioKey, bio);
      userBio.value = bio;
    }

    if (imagePath != null) {
      await prefs.setString(_imageKey, imagePath);
      userProfileImage.value = imagePath;
    }

    userName.value = name;
    userEmail.value = email;
  }

  /// Retrieve the stored token (null if not logged in).
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clear saved credentials (logout).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_bioKey);
    await prefs.remove(_imageKey);

    // Clear API cache
    await CacheManager.clearCache();

    // Reset state
    userName.value = 'User';
    userEmail.value = '';
    userBio.value = '';
    userProfileImage.value = null;
  }

  // --- Helper Methods (still available for sync/internal use) ---
  Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> getSavedBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bioKey);
  }

  Future<String?> getSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imageKey);
  }
}
