import 'package:flutter/material.dart';

/// Thème moderne Visual Media (VM).
class VMTheme {
  static const Color background = Color(0xFF0B0E17);
  static const Color surface = Color(0xFF141926);
  static const Color surfaceLight = Color(0xFF1E2540);
  static const Color primary = Color(0xFF7C5CFF);
  static const Color accent = Color(0xFFFF8A3D);
  static const Color textPrimary = Color(0xFFF2F4FF);
  static const Color textSecondary = Color(0xFF9AA3C0);

  static const LinearGradient logoGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2140), Color(0xFF12172B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: accent,
      surface: surface,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: Colors.white12,
      ),
    );
  }
}
