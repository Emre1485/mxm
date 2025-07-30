import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF90CAF9), // Açık mavi (vurgular, butonlar)
    onPrimary: Colors.black, // Primary üzerindeki yazı rengi
    secondary: Color(0xFF0D47A1), // Lacivert (yardımcı vurgular)
    onSecondary: Colors.white,
    error: Color(0xFFEF9A9A),
    onError: Colors.black,
    surface: Color(0xFF1E1E1E), // Kartlar, diyaloglar
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D47A1),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E),
    surfaceTintColor: Colors.blueGrey.shade700,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF90CAF9),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
    labelLarge: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
  ),
);
