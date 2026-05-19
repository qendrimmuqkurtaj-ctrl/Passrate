import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'core/design/app_colors.dart';
import 'core/services/firebase_service.dart';
import 'features/splash/splash_screen.dart';

const _appStoreId = '6754942459';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PassRateApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  WidgetsBinding.instance.addPostFrameCallback((_) => FirebaseService.seedAircraftTypes());
}

Future<void> _checkForUpdate() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('https://itunes.apple.com/lookup?id=$_appStoreId'),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    client.close();

    final data = jsonDecode(body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    if (results.isEmpty) return;

    final storeVersion = results[0]['version'] as String;
    if (_isNewerVersion(storeVersion, currentVersion)) {
      Get.dialog(
        AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text(
            'New Update Available',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFamily: 'satoshi',
            ),
          ),
          content: Text(
            'Version $storeVersion is available. Update now to get the latest features and improvements.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'satoshi',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Later',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'satoshi',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                final uri = Uri.parse(
                  'https://apps.apple.com/app/id$_appStoreId',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    }
  } catch (_) {}
}

bool _isNewerVersion(String storeVersion, String currentVersion) {
  final store = storeVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final current = currentVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final maxLen = store.length > current.length ? store.length : current.length;
  for (int i = 0; i < maxLen; i++) {
    final s = i < store.length ? store[i] : 0;
    final c = i < current.length ? current[i] : 0;
    if (s > c) return true;
    if (s < c) return false;
  }
  return false;
}

class PassRateApp extends StatelessWidget {
  const PassRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PassRate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgPrimary,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          error: AppColors.failText,
          surface: AppColors.bgCard,
          onSurface: AppColors.textPrimary,
          outline: AppColors.border,
        ),
        fontFamily: 'satoshi',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgSecondary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.accent),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'satoshi',
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgCard,
          labelStyle: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        textTheme: const TextTheme(
          labelLarge: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          labelMedium: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          bodySmall: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        dividerColor: AppColors.border,
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.bgCard),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.bgCard),
      ),
      home: const SplashScreen(),
    );
  }
}
