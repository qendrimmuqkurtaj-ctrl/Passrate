import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  // Dark theme palette
  static const Color bgPrimary     = Color(0xFF071525);
  static const Color bgSecondary   = Color(0xFF0C1524);
  static const Color bgCard        = Color(0xFF0F2040);
  static const Color border        = Color(0xFF1A3060);
  static const Color textPrimary   = Color(0xFFE8F0FF);
  static const Color textSecondary = Color(0xFFC8D8F0);
  static const Color textMuted     = Color(0xFF6080A0);
  static const Color accent        = Color(0xFF1A8FD1);
  // Pass
  static const Color passBg        = Color(0x33105032);
  static const Color passBorder    = Color(0xFF1A5A38);
  static const Color passText      = Color(0xFF3AAA6A);
  // Fail
  static const Color failBg        = Color(0x33501010);
  static const Color failBorder    = Color(0xFF5A1A1A);
  static const Color failText      = Color(0xFFCC4444);
  // Kept for success checkmark icon (DO NOT CHANGE)
  static const Color green         = Color(0xFF24A584);
  // Legacy aliases
  static const Color primaryColor  = accent;
  static const Color bgColor       = bgPrimary;
  static const Color red           = failText;
  static const Color black         = textPrimary;
  static const Color grey          = textMuted;
  static const Color greyLight     = textMuted;
  static const Color white         = Color(0xFFFFFFFF);
  static const Color blue          = Color(0xFF123462);
  static const Color darkRed       = Color(0xFF841414);
}
