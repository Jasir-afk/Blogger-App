import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  var isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> result = await _connectivity
        .checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final hasNoInternet = result.contains(ConnectivityResult.none);

    if (hasNoInternet && isConnected.value) {
      isConnected.value = false;
      _showNoInternetSnackbar();
    } else if (!hasNoInternet && !isConnected.value) {
      isConnected.value = true;
      _showBackOnlineSnackbar();
    }
  }

  void _showNoInternetSnackbar() {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      'No Internet Connection',
      'Please check your internet settings.',
      isDismissible: false,
      duration: const Duration(days: 1), // Persistent until online
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      backgroundColor: Colors.redAccent.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      shouldIconPulse: true,
    );
  }

  void _showBackOnlineSnackbar() {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      'Back Online',
      'Internet connection restored.',
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.wifi, color: Colors.white),
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }
}
