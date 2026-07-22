import 'package:flutter/material.dart';

class AppTheme {
  static const _accent = Color(0xFF6366F1);
  static const _accentLight = Color(0xFF818CF8);
  static const _surface = Color(0xFF0F1117);
  static const _surfaceElevated = Color(0xFF161B26);
  static const _surfaceCard = Color(0xFF1C2230);
  static const _border = Color(0xFF2A3142);
  static const _textPrimary = Color(0xFFF1F5F9);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);

  static Color get accent => _accent;
  static Color get accentLight => _accentLight;
  static Color get surface => _surface;
  static Color get surfaceElevated => _surfaceElevated;
  static Color get surfaceCard => _surfaceCard;
  static Color get border => _border;
  static Color get textPrimary => _textPrimary;
  static Color get textSecondary => _textSecondary;
  static Color get success => _success;
  static Color get warning => _warning;
  static Color get error => _error;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _surface,
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        secondary: _accentLight,
        surface: _surfaceElevated,
        error: _error,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _textPrimary,
        displayColor: _textPrimary,
        fontFamily: 'system-ui',
      ),
      dividerColor: _border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: _textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
      ),
    );
  }
}
