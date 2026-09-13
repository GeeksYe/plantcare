import 'package:flutter/material.dart';

/// 治愈自然绿风 —— 与设计稿一致的色彩系统
class AppColors {
  static const bg = Color(0xFFF0FDF4); // 背景
  static const forest = Color(0xFF15803D); // 森林绿（主色）
  static const emerald = Color(0xFF059669); // 翡翠绿（辅色）
  static const amber = Color(0xFFD97706); // 金橙（强调）
  static const ink = Color(0xFF14532D); // 标题墨绿
  static const sub = Color(0xFF64748B); // 次要文字
  static const border = Color(0xFFE2EFE7); // 边框
  static const softCard = Color(0xFFF0F7F3); // 软卡背景
  static const white = Colors.white;
  static const danger = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'MiSans', // iOS 观感：中文接近苹方，西文接近 SF Pro（开源替代，避免版权问题）
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        secondary: AppColors.emerald,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'MiSans',
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
