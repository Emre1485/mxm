// import 'package:flutter/material.dart';

// ThemeData lightMode = ThemeData(
//   colorScheme: ColorScheme.light(
//     surface: Colors.grey.shade300,
//     primary: Colors.grey.shade500,
//     secondary: Colors.grey.shade200,
//     tertiary: Colors.grey.shade100,
//     inversePrimary: Colors.grey.shade900,
//   ),
//   scaffoldBackgroundColor: Colors.grey.shade300,
// );

import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Colors.grey.shade500,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade200,
    onSecondary: Colors.black,
    error: Colors.red.shade400,
    onError: Colors.white,
    surface: Colors.grey.shade100,
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor: Colors.grey.shade300,
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.grey.shade200,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade500,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    labelLarge: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
  ),
);
