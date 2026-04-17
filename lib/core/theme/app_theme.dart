import 'package:flutter/material.dart';

class AppTheme {
  // Pulled from the Fajarly logo.
  static const brandBlue = Color(0xFF1E5FD9);
  static const brandBlueDark = Color(0xFF0F2E6E);
  static const brandGold = Color(0xFFF5A623);
  static const brandGoldLight = Color(0xFFFFC93C);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandBlue,
      secondary: brandGold,
      tertiary: brandGoldLight,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF6B97FF),
      secondary: brandGoldLight,
      tertiary: brandGold,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: Typography.englishLike2021.merge(Typography.blackMountainView),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
