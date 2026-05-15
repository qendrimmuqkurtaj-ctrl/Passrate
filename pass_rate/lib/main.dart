import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'core/design/app_colors.dart';
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
