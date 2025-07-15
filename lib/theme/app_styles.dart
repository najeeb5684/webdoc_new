import 'package:flutter/material.dart';

class AppStyles {
  static const String fontFamily = 'Roboto'; // Use the family name from pubspec.yaml

  // Helper function to get scaled font size
  static double getScaledFontSize(BuildContext context, double fontSize) {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return fontSize / textScaleFactor;
  }

  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 22), // Use the helper function
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
  );

  static TextStyle titleMedium(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 18),
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  static TextStyle titleSmall(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 16),
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
  static TextStyle titleSmalll(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 16),
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 14),
    fontFamily: fontFamily,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 12),
    fontFamily: fontFamily,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: getScaledFontSize(context, 10),
    fontFamily: fontFamily,
  );
}