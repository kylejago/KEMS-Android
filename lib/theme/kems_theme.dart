import 'package:flutter/material.dart';

class KemsTheme {
  static const background = Color(0xFF050C10);
  static const surface = Color(0xFF0D171C);
  static const surface2 = Color(0xFF132127);
  static const green = Color(0xFF38E06F);
  static const cyan = Color(0xFF55D6D0);
  static const blue = Color(0xFF3FA9F5);
  static const amber = Color(0xFFFFC107);
  static const purple = Color(0xFFB36BFF);
  static const red = Color(0xFFFF5C64);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.dark,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(primary: green, secondary: cyan, surface: surface),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(backgroundColor: background, elevation: 0, centerTitle: false),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF081116),
        indicatorColor: green.withValues(alpha: .16),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          color: s.contains(WidgetState.selected) ? green : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        )),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1C2D34)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF294047))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cyan, width: 1.5)),
      ),
      snackBarTheme: const SnackBarThemeData(backgroundColor: surface2),
    );
  }
}
