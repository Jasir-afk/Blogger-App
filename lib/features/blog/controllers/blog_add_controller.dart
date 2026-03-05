import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:test_project/core/network/api_urls.dart';
import 'package:test_project/core/network/api_client.dart';
import 'package:test_project/features/auth/controllers/auth_controller.dart';

class BlogAddController {
  final AuthController _authController = AuthController();

  /// Creates a new blog post:
  /// Step 1: Upload the image and get the URL.
  /// Step 2: Create the blog post using that URL.
  Future<void> createBlog({
    required String title,
    required String description,
    required List<String> tags,
    required String category,
    required File imageFile,
  }) async {
    final token = await _authController.getSavedToken();
    if (token == null) {
      throw Exception('Auth token not found. Please log in again.');
    }

    // --- STEP 1: UPLOAD IMAGE ---
    print('Step 1: Uploading image to ${ApiUrls.uploadImage}...');
    final uploadUrl = await _uploadImage(imageFile, token);
    print('Step 1 Success: Image URL received: $uploadUrl');

    // --- STEP 2: CREATE BLOG POST ---
    print('Step 2: Creating blog post at ${ApiUrls.blogs}...');
    // We send ALL fields that the BlogModel requires
    // to satisfy the backend and prevent fetching issues.
    await ApiClient.post(
      ApiUrls.blogs,
      {
        'title': title,
        'description': description,
        'tags': tags,
        'image': uploadUrl,
        'imageUrl': uploadUrl, // App expects this
        'category': category,
        'status': 'published',
        'isFeatured': false,
        'metaTitle': title,
        'metaDescription': description,
        'publishedDate': DateTime.now().toIso8601String(),
      },
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Step 2 Success: Blog created!');
  }

  Future<String> _uploadImage(File file, String token) async {
    final uri = Uri.parse(ApiUrls.uploadImage);
    final request = http.MultipartRequest('POST', uri);

    // Headers
    request.headers['Authorization'] = 'Bearer $token';

    // Since your backend router.post("/image", upload.single("file"), ...)
    // now explicitly looks for "file", we send only that.
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: MediaType('image', 'jpeg'),
    );

    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Find the URL (try all common keys)
        final url =
            data['image'] ??
            data['imageUrl'] ??
            data['url'] ??
            data['data']?['url'] ??
            data['filePath'];

        if (url != null) return url.toString();
        throw Exception(
          'Step 1 Failed: Server returned 200 but no URL was found in the JSON.',
        );
      } else {
        print('Step 1: upload failed, body: ${response.body}');

        String errorMsg = 'Server Error ${response.statusCode}';
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['message'] ?? data['error'] ?? errorMsg;
        } catch (_) {
          if (response.body.contains('<pre>')) {
            errorMsg = response.body.split('<pre>').last.split('</pre>').first;
          } else if (response.body.isNotEmpty) {
            errorMsg = response.body.length > 200
                ? '${response.body.substring(0, 200)}...'
                : response.body;
          }
        }
        throw Exception('Step 1 Failed (${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error during upload: $e');
    }
  }

  /// Updates an existing blog post.
  /// If [imageFile] is provided, uploads new image first.
  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String description,
    required List<String> tags,
    required String category,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    final token = await _authController.getSavedToken();
    if (token == null) {
      throw Exception('Auth token not found. Please log in again.');
    }

    String imageUrl = existingImageUrl ?? '';

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, token);
    }

    await ApiClient.put(
      ApiUrls.blogById,
      {
        'title': title,
        'description': description,
        'tags': tags,
        'category': category,
        if (imageUrl.isNotEmpty) 'image': imageUrl,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Deletes a blog post by its ID.
  Future<void> deleteBlog(String blogId) async {
    final token = await _authController.getSavedToken();
    if (token == null) {
      throw Exception('Auth token not found. Please log in again.');
    }

    await ApiClient.delete(
      ApiUrls.blogById,
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
