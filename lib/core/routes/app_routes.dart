import 'package:get/get.dart';
import 'package:test_project/features/auth/views/login_screen.dart';
import 'package:test_project/features/auth/views/register_screen.dart';
import 'package:test_project/features/blog/views/add_blog_screen.dart';
import 'package:test_project/features/blog/views/blog_detail_screen.dart';
import 'package:test_project/features/blog/views/blog_edit_screen.dart';
import 'package:test_project/features/home/views/home_screen.dart';
import 'package:test_project/features/profile/views/edit_profile_screen.dart';
import 'package:test_project/features/splash/view/splash_screen.dart';
import 'package:test_project/features/blog/models/blog_model.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const addBlog = '/add-blog';
  static const blogDetail = '/blog-detail';
  static const blogEdit = '/blog-edit';
  static const editProfile = '/edit-profile';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: addBlog, page: () => const BlogAddScreen()),
    GetPage(
      name: blogDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final String blogId = args['blogId'] as String;
        final String? heroImageUrl = args['heroImageUrl'] as String?;
        return BlogDetailScreen(blogId: blogId, heroImageUrl: heroImageUrl);
      },
    ),
    GetPage(
      name: blogEdit,
      page: () {
        final blog = Get.arguments as BlogModel;
        return BlogEditScreen(blog: blog);
      },
    ),
    GetPage(
      name: editProfile,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return EditProfileScreen(
          initialName: args['initialName'] as String,
          initialEmail: args['initialEmail'] as String,
          initialBio: args['initialBio'] as String,
          initialImagePath: args['initialImagePath'] as String?,
        );
      },
    ),
  ];
}
