

import 'package:Webdoc/services/appointment_count_provider.dart';
import 'package:Webdoc/services/firebase_messaging_service.dart';
import 'package:Webdoc/services/local_notifications_service.dart';

import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Firebase Crashlytics
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:provider/provider.dart'; // Import Provider

import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen
//import 'screens/dashboard_screen.dart'; // if you are using DashboardScreen directly

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
  // await NotificationService.initialize();

  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();

  final firebaseMessagingService = FirebaseMessagingService.instance();

  // Initialize facebook event
  final facebookAppEvents = FacebookAppEvents();

  // Set auto log app events
  facebookAppEvents.setAutoLogAppEventsEnabled(true); // Corrected method
  await firebaseMessagingService.init(
      localNotificationsService:
      localNotificationsService); // Pass facebookAppEvents


  runApp(
    ChangeNotifierProvider(
      create: (context) => AppointmentCountProvider(),
      child: const MyApp(), // MyApp must be const
    ),
  );
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
      home: const SplashScreen(), // changed here because splash screen is initial route
      //home:  DashboardScreen(),
      // home: const RegistrationScreen(mobileNumber: "03306809669"),
      builder: EasyLoading.init(), // Use const constructor
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics), // For screen tracking (optional)
      ],
    );
  }
}



/*import 'package:Webdoc/services/firebase_messaging_service.dart';
import 'package:Webdoc/services/local_notifications_service.dart';

import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
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
 // await NotificationService.initialize();

  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();

  final firebaseMessagingService = FirebaseMessagingService.instance();

  // Initialize facebook event
  final facebookAppEvents = FacebookAppEvents();

  // Set auto log app events
  facebookAppEvents.setAutoLogAppEventsEnabled(true); // Corrected method
  await firebaseMessagingService.init(
      localNotificationsService:
      localNotificationsService); // Pass facebookAppEvents


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
}*/






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

