import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/features/auth/controllers/auth_controller.dart';
import 'package:test_project/features/blog/controllers/blog_controller.dart';
import 'package:test_project/core/network/connectivity_controller.dart';
import 'package:test_project/core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inject global controllers
  Get.put(AuthController());
  Get.put(BlogController());
  Get.put(ConnectivityController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Blogger App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
      ),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
    );
  }
}
