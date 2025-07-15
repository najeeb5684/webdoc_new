
/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import your generated firebase_options.dart
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Firebase Crashlytics
import 'package:flutter/foundation.dart'; // Import for kDebugMode

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase initialization

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");

    // Enable Crashlytics collection unless in debug mode
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Handle the error gracefully (e.g., show an error message to the user)
    return; // Stop the app from running if Firebase fails to initialize
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance; // Now safe to initialize

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Demo'),
        ),
        body: Center(
          child: Text('Firebase Initialized!'), //Or any other code
        ),
      ),
    );
  }
}*/



import 'package:Webdoc/theme/app_theme.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Firebase Crashlytics
import 'package:flutter/foundation.dart'; // Import for kDebugMode

import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase and preferredOrientations

  // Lock screen orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  String signature = await SmsAutoFill().getAppSignature;
  print("App signature: $signature");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");

    // Enable Crashlytics collection unless in debug mode
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Handle the error appropriately, e.g., show an error message to the user
  }

  // Required for SharedPreferences
  await SharedPreferencesManager.init(); // Initialize the SharedPreferencesManager

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Or any color you want
    statusBarIconBrightness: Brightness.dark, // Adjust based on statusBarColor
  ));

  runApp(const MyApp()); // Make MyApp const
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Add key and make const

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Flutter App',
      //theme: AppTheme.lightTheme, // Use AppTheme
      home: const SplashScreen(),
      //home:  DashboardScreen(),
      // home: const RegistrationScreen(mobileNumber: "03306809669"),
      builder: EasyLoading.init(), // Use const constructor
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics), // For screen tracking (optional)
      ],
    );
  }
}


/*import 'package:Webdoc/theme/app_theme.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase and preferredOrientations

  // Lock screen orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  String signature = await SmsAutoFill().getAppSignature;
  print("App signature: $signature");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Handle the error appropriately, e.g., show an error message to the user
  }

  // Required for SharedPreferences
  await SharedPreferencesManager.init(); // Initialize the SharedPreferencesManager

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Or any color you want
    statusBarIconBrightness: Brightness.dark, // Adjust based on statusBarColor
  ));

  runApp(const MyApp()); // Make MyApp const
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Add key and make const

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Flutter App',
      //theme: AppTheme.lightTheme, // Use AppTheme
      home: const SplashScreen(),
      //home:  DashboardScreen(),
      // home: const RegistrationScreen(mobileNumber: "03306809669"),
      builder: EasyLoading.init(), // Use const constructor
    );
  }
}*/


/*

import 'package:Webdoc/theme/app_theme.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase

  String signature = await SmsAutoFill().getAppSignature;
  print("App signature: $signature");
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Handle the error appropriately, e.g., show an error message to the user
  }
 // Required for SharedPreferences
  await SharedPreferencesManager.init(); // Initialize the SharedPreferencesManager

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Or any color you want
    statusBarIconBrightness: Brightness.dark, // Adjust based on statusBarColor
  ));

  runApp(const MyApp()); // Make MyApp const
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Add key and make const

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Flutter App',
      //theme: AppTheme.lightTheme, // Use AppTheme
      home: const SplashScreen(),
      //home:  DashboardScreen(),
     // home: const RegistrationScreen(mobileNumber: "03306809669"),
      builder: EasyLoading.init(), // Use const constructor
    );
  }
}*/
