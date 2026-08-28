import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const acid = Color(0xFFB7F238);
  static const acidDark = Color(0xFF3F7200);
  static const violet = Color(0xFF925CFF);
  static const fuchsia = Color(0xFFE160FF);

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: acidDark,
      onPrimary: Colors.white,
      primaryContainer: acid,
      onPrimaryContainer: Color(0xFF172600),
      secondary: Color(0xFF65A915),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEEF7DF),
      onSecondaryContainer: Color(0xFF17200F),
      surface: Colors.white,
      onSurface: Color(0xFF17200F),
      outline: Color(0xFF748267),
      outlineVariant: Color(0xFFDCE7CF),
      error: Color(0xFFBA1A1A),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7FAEF),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: acid,
        foregroundColor: Color(0xFF172600),
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: fuchsia,
      onPrimary: Color(0xFF26002F),
      primaryContainer: Color(0xFF5C176C),
      onPrimaryContainer: Color(0xFFFFD6FF),
      secondary: violet,
      onSecondary: Color(0xFF1C0044),
      secondaryContainer: Color(0xFF38205B),
      onSecondaryContainer: Color(0xFFEBDDFF),
      surface: Color(0xFF1B1222),
      onSurface: Color(0xFFFBF5FF),
      outline: Color(0xFFA996B1),
      outlineVariant: Color(0xFF493653),
      error: Color(0xFFFFB4AB),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF100A15),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: fuchsia,
        foregroundColor: Color(0xFF26002F),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
}
