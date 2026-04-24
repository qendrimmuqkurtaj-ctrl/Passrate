import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class DeviceUtility {
  DeviceUtility._();

  // Set Status Bar Color
  static void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: color));
  }

  // Enable/Disable Full-Screen Mode
  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  // Check if Running on Physical Device
  static bool isPhysicalDevice() {
    return Platform.isAndroid || Platform.isIOS;
  }

  // Device Type Checks
  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  // Vibrate Device



  static void hapticFeedback() async{
    HapticFeedback.heavyImpact();
  }

  // Set Preferred Orientations
  static Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  // Hide Status Bar
  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: <SystemUiOverlay>[]);
  }

  // Show Status Bar
  static void showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }
}
