import 'package:flutter/material.dart';

import '../utils/global.dart';


class AppColors {
 // static const Color primaryColor = Color(0xFF007BFF);  // Still keep a primary color for certain accents
  static Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.grey;
  static const Color lightGreyStroke = Color(0xe6e6e6e6);
  static const Color accentColor = Color(0xFFFFC107);
 // static const Color backgroundColor = Colors.white; // Set to White
  static const Color primaryColor = Color(0xFF50C4CC);
  static const Color cardColor = Color(0xFF4BC4CD);
  static const Color primaryColorLight = Color(0xFFedf9fa);
  static const Color backgroundColor = Color(0xffffffff);// Set to White
  static const Color iconColor = Color(0xFF7F8081);
  static Color getThemeColor() {
    return Global.getColorFromHex(Global.THEME_COLOR_CODE);
  }
}