
import 'package:flutter/material.dart';



class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Roboto', // Set the default font family to Roboto
    primaryColor: const Color(0xFF50C4CC), // From login screen design
    scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Login screen background color
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF50C4CC), // Light blue
      titleTextStyle: TextStyle(
        color: Colors.white, // Use white text on the blue AppBar
        fontSize: 20,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto', // Override if needed for the title
      ),
      iconTheme: IconThemeData(color: Colors.white), // Ensure icons are white
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black, // Keep black for main titles
        fontFamily: 'Roboto', // Apply Roboto
      ),
      bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'Roboto'), // Apply Roboto
      bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
          fontFamily: 'Roboto'), // Apply Roboto
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF50C4CC), // Match the button color
        foregroundColor: Colors.white, // white foreground color
        textStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Roboto'), // Keep text styles for buttons
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          // Optional: adjust to match button shape
          borderRadius:
          BorderRadius.circular(10), // Match the rounded corners
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      color: Colors.white, // Set a default card color if needed
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF50C4CC)), // Base the scheme on the primary color
    dividerColor: Colors.grey[400],
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:
      Color(0xFF50C4CC), // Set progress indicator color to match design
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF50C4CC), // match the FloatingActionButton color
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      color: Colors.black87,
    ),
    inputDecorationTheme: InputDecorationTheme(
      // Set the global InputDecorationTheme
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
          color: Colors.black87,
          fontFamily: 'Roboto'), // Use black for labels
      hintStyle: const TextStyle(
          color: Colors.black54,
          fontFamily: 'Roboto'), // Use for hints
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
            8), // Match the border radius of the input fields.
        borderSide: BorderSide.none, // Remove the border around the input field
      ),
      focusedBorder: OutlineInputBorder(
        // Set border when focused
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: const Color(0xFF50C4CC),
            width: 2), // Style of border when focus is on the TextField
      ),
    ),
  );
}
/*
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF50C4CC), // From login screen design
    scaffoldBackgroundColor: const Color(0xFFF0F8FF), // Login screen background color
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF50C4CC), // Light blue
      titleTextStyle: TextStyle(
        color: Colors.white, // Use white text on the blue AppBar
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: Colors.white), // Ensure icons are white
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black, // Keep black for main titles
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF50C4CC), // Match the button color
        foregroundColor: Colors.white,       // white foreground color
        textStyle: const TextStyle(fontSize: 16),  // Keep text styles for buttons
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder( //Optional: adjust to match button shape
          borderRadius: BorderRadius.circular(10),  //Match the rounded corners
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      color: Colors.white,  // Set a default card color if needed
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF50C4CC)), //Base the scheme on the primary color
    dividerColor: Colors.grey[400],
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF50C4CC), // Set progress indicator color to match design
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF50C4CC), // match the FloatingActionButton color
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      color: Colors.black87,
    ),
    inputDecorationTheme: InputDecorationTheme(  // Set the global InputDecorationTheme
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black87), // Use black for labels
      hintStyle: const TextStyle(color: Colors.black54),  // Use for hints
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Match the border radius of the input fields.
        borderSide: BorderSide.none,  // Remove the border around the input field
      ),
      focusedBorder: OutlineInputBorder( // Set border when focused
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFF50C4CC), width: 2), // Style of border when focus is on the TextField
      ),

    ),

  );
}
*/

/*
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: Colors.black),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Keep default color for buttons
        foregroundColor: Colors.black,   // set default color to text
        textStyle: const TextStyle(fontSize: 16),  // Keep default white text
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
    dividerColor: Colors.grey[400],
    // Add the following to globally change progress indicator colors
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.black54,  // Changes the color of the CircularProgressIndicator
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black, // Keep default color for FAB
      foregroundColor: Colors.white, // Set text and icon color for FAB
    ),
    iconTheme: const IconThemeData(
      color: Colors.black87,  // Changes default icon colors.
    ),
  );
}*/
