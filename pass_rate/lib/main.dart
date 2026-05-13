import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'core/design/app_colors.dart';
import 'features/home/screens/home_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PassRateApp());
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
        scaffoldBackgroundColor: AppColors.bgColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        fontFamily: 'satoshi',
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: AppColors.primaryColor, fontSize: 16, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryColor, width: 2)),
          hintStyle: const TextStyle(color: AppColors.primaryColor, fontSize: 14),
        ),
        textTheme: const TextTheme(
          labelLarge: TextStyle(color: AppColors.black, fontSize: 18, fontWeight: FontWeight.w700),
          labelMedium: TextStyle(color: AppColors.primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: AppColors.black, fontSize: 16),
          bodySmall: TextStyle(color: AppColors.black, fontSize: 14),
          titleMedium: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(color: AppColors.primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
