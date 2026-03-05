import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:test_project/core/network/api_urls.dart';
import 'package:test_project/core/network/api_client.dart';
import 'package:test_project/features/auth/controllers/auth_controller.dart';
import 'package:test_project/features/blog/models/blog_model.dart';

class BlogController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  // Reactive states
  final blogs = <BlogModel>[].obs;
  final myBlogs = <BlogModel>[].obs;
  final categoryBlogs = <BlogModel>[].obs;
  final isLoading = false.obs;
  final isMyBlogsLoading = false.obs;
  final isCategoryLoading = false.obs;
  final isActionLoading = false.obs;
  final errorMessage = ''.obs;
  final categoryError = ''.obs;

  // Pagination states
  final currentPage = 1.obs;
  final hasMore = true.obs;
  final isLoadMoreLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlogs();
  }

  /// Fetches all blogs from the API.
  Future<void> fetchBlogs() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await ApiClient.get(ApiUrls.blogs);
      if (data is List) {
        blogs.value = data
            .map((json) => BlogModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        errorMessage.value = 'Unexpected response format';
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // My Blogs Pagination states
  final myBlogsCurrentPage = 1.obs;
  final myBlogsHasMore = true.obs;
  final isMyBlogsLoadMoreLoading = false.obs;

  /// Fetches only the blogs created by the current user with pagination.
  Future<void> fetchMyBlogs({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isMyBlogsLoadMoreLoading.value || !myBlogsHasMore.value) return;
      isMyBlogsLoadMoreLoading.value = true;
    } else {
      isMyBlogsLoading.value = true;
      myBlogsCurrentPage.value = 1;
      myBlogsHasMore.value = true;
    }

    try {
      final token = await _authController.getSavedToken();
      final url =
          '${ApiUrls.myBlogs}?page=${myBlogsCurrentPage.value}&limit=10';

      final data = await ApiClient.get(
        url,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (data is List) {
        final List<BlogModel> newBlogs = data
            .map((json) => BlogModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (isLoadMore) {
          // Filter out blogs that are already in the list to prevent Hero tag collisions
          final existingIds = myBlogs.map((b) => b.id).toSet();
          final uniqueNewBlogs = newBlogs
              .where((b) => !existingIds.contains(b.id))
              .toList();
          myBlogs.addAll(uniqueNewBlogs);
        } else {
          myBlogs.value = newBlogs;
        }

        if (newBlogs.length < 10) {
          myBlogsHasMore.value = false;
        } else {
          myBlogsCurrentPage.value++;
        }
      }
    } catch (e) {
      print('Error fetching my blogs: $e');
    } finally {
      if (isLoadMore) {
        isMyBlogsLoadMoreLoading.value = false;
      } else {
        isMyBlogsLoading.value = false;
      }
    }
  }

  /// Fetches blogs filtered by category from the API with pagination.
  /// Use 'All' or empty string to fetch all blogs.
  Future<void> fetchBlogsByCategory(
    String category, {
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isLoadMoreLoading.value || !hasMore.value) return;
      isLoadMoreLoading.value = true;
    } else {
      isCategoryLoading.value = true;
      categoryError.value = '';
      currentPage.value = 1;
      hasMore.value = true;
    }

    try {
      final String baseUrl =
          (category.isEmpty || category.toLowerCase() == 'all')
          ? ApiUrls.blogs
          : '${ApiUrls.blogs}?category=$category';

      // Add pagination params
      final separator = baseUrl.contains('?') ? '&' : '?';
      final url = '$baseUrl${separator}page=${currentPage.value}&limit=10';

      final data = await ApiClient.get(url);

      if (data is List) {
        final List<BlogModel> newBlogs = data
            .map((json) => BlogModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (isLoadMore) {
          // Filter out blogs that are already in the list to prevent Hero tag collisions
          final existingIds = categoryBlogs.map((b) => b.id).toSet();
          final uniqueNewBlogs = newBlogs
              .where((b) => !existingIds.contains(b.id))
              .toList();
          categoryBlogs.addAll(uniqueNewBlogs);
        } else {
          categoryBlogs.value = newBlogs;
        }

        // If we got fewer than 10 items, there are no more pages
        if (newBlogs.length < 10) {
          hasMore.value = false;
        } else {
          currentPage.value++;
        }
      } else {
        categoryError.value = 'Unexpected response format';
      }
    } catch (e) {
      if (isLoadMore) {
        print('Error loading more: $e');
      } else {
        categoryError.value = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (isLoadMore) {
        isLoadMoreLoading.value = false;
      } else {
        isCategoryLoading.value = false;
      }
    }
  }

  /// Creates a new blog post.
  Future<void> createBlog({
    required String title,
    required String description,
    required List<String> tags,
    required String category,
    required File imageFile,
  }) async {
    isActionLoading.value = true;
    try {
      final token = await _authController.getSavedToken();
      if (token == null) throw Exception('Auth token not found.');

      // 1. Upload Image
      final uploadUrl = await _uploadImage(imageFile, token);

      // 2. Create Blog
      await ApiClient.post(
        ApiUrls.blogs,
        {
          'title': title,
          'description': description,
          'tags': tags,
          'image': uploadUrl,
          'imageUrl': uploadUrl,
          'category': category,
          'status': 'published',
          'isFeatured': false,
          'metaTitle': title,
          'metaDescription': description,
          'publishedDate': DateTime.now().toIso8601String(),
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      // 3. Refresh lists
      await fetchBlogs();
      await fetchMyBlogs();
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Updates an existing blog post.
  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String description,
    required List<String> tags,
    required String category,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    isActionLoading.value = true;
    try {
      final token = await _authController.getSavedToken();
      if (token == null) throw Exception('Auth token not found.');

      String imageUrl = existingImageUrl ?? '';
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, token);
      }

      await ApiClient.put(
        '${ApiUrls.blogById}/$blogId',
        {
          'title': title,
          'description': description,
          'tags': tags,
          'category': category,
          if (imageUrl.isNotEmpty) 'image': imageUrl,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      // Refresh lists
      await fetchBlogs();
      await fetchMyBlogs();
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Deletes a blog post.
  Future<void> deleteBlog(String blogId) async {
    isActionLoading.value = true;
    try {
      final token = await _authController.getSavedToken();
      if (token == null) throw Exception('Auth token not found.');

      await ApiClient.delete(
        '${ApiUrls.blogById}/$blogId',
        headers: {'Authorization': 'Bearer $token'},
      );

      // Refresh lists
      await fetchBlogs();
      await fetchMyBlogs();
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<String> _uploadImage(File file, String token) async {
    final uri = Uri.parse(ApiUrls.uploadImage);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 45),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final url =
          data['image'] ??
          data['imageUrl'] ??
          data['url'] ??
          data['data']?['url'] ??
          data['filePath'];
      if (url != null) return url.toString();
      throw Exception('Server returned 200 but no URL found.');
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  Future<BlogModel> getBlogById(String id) async {
    final token = await _authController.getSavedToken();
    final data = await ApiClient.get(
      '${ApiUrls.blogById}/$id',
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    if (data is Map<String, dynamic>) {
      return BlogModel.fromJson(data);
    } else {
      throw Exception('Blog not found');
    }
  }
}
