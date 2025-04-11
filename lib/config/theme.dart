import 'package:flutter/material.dart';

class AppTheme {
  // App colors
  static const Color primaryColor = Colors.green;
  static const Color secondaryColor = Colors.lightGreenAccent;
  static const Color accentColor = Colors.amber;
  static const Color textColor = Colors.black87;
  static const Color lightTextColor = Colors.grey;

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
        .copyWith(secondary: secondaryColor),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    buttonTheme: const ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );
}
