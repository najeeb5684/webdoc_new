

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:Webdoc/utils/shared_preferences.dart';
import '../constants/ApiConstants.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _revealAnimation;
  late Animation<double> _logoScaleAnimation;
  String _statusMessage = "Opening App..."; // Initial message
  bool _isLoading = false;
  bool _autoLoginAttempted = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(seconds: 3);
  static const Duration _retryDelay = Duration(seconds: 3);
  bool _navigateToLogin = false;
  late Animation<double> _textFadeInAnimation;
  final List<String> _greetingMessages = [
    "Connecting you to the best doctors...",
    "Your health journey starts here...",
    "Personalized care, just a tap away...",
    "Making healthcare accessible and convenient...",
    "Experience seamless consultations...",
    "Your prescription, delivered to your screen...",
    "Book appointments with ease...",
    "Welcome to a healthier you!",
    "Empowering you with the best medical advice...",
    "Taking the stress out of healthcare..."
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutBack),
    );

    _textFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    _messageTimer = Timer.periodic(const Duration(seconds: 4, milliseconds: 500), (timer) { // Adjust for better flow
      setState(() {
        _messageIndex = (_messageIndex + 1) % _greetingMessages.length;
        _statusMessage = _greetingMessages[_messageIndex];
      });
    });

    Timer(_initialDelay, () {
      _checkLoginAndNavigate();
    });
  }

  Future<void> _checkLoginAndNavigate() async {
    String? mobileNumber = SharedPreferencesManager.getString('mobileNumber');
    String? pin = SharedPreferencesManager.getString('pin');

    if (mobileNumber != null && pin != null) {
      if (!_autoLoginAttempted) {
        _autoLoginAttempted = true;
        _attemptAutoLogin(mobileNumber, pin);
      }
    } else {
      _navigateToLoginScreen();
    }
  }

  Future<void> _attemptAutoLogin(String mobileNumber, String pin) async {
    if (_navigateToLogin) return;

    setState(() {
      _isLoading = true;
      _statusMessage = _greetingMessages[_messageIndex];
    });

    final Uri apiUrl = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.patientLoginEndpoint}');

    try {
      final response = await http
          .post(
        apiUrl,
        headers: {'accept': '*/*', 'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": mobileNumber,
          "password": pin,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['statusCode'] == 1) {
        final userData = responseData['payLoad']?['user'];

        if (userData != null) {
          await SharedPreferencesManager.putString(
              'id', userData['Id']?.toString() ?? '');
          await SharedPreferencesManager.putString(
              'mobileNumber', userData['PhoneNumber']?.toString() ?? '');
          await SharedPreferencesManager.putString(
              'name', userData['UserName'] ?? '');
          await SharedPreferencesManager.putBool(
              'isPackageActivated', userData['isPackageActivated'] ?? false);
        }
        _navigateToDashboardScreen();
      } else {
        setState(() {
          _statusMessage = "Login failed. Please try again.";
          _isLoading = false;
        });

        if (_retryCount < _maxRetries - 1) {
          _retryAutoLogin(mobileNumber, pin);
        } else {
          setState(() {
            _statusMessage = "Please log in to continue.";
            _navigateToLogin = true;
          });
          Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
        }
      }
    } on TimeoutException catch (e) {
      setState(() {
        _statusMessage = "Connection timed out. Please check your network.";
        _isLoading = false;
      });

      if (_retryCount < _maxRetries - 1) {
        _retryAutoLogin(mobileNumber, pin);
      } else {
        setState(() {
          _statusMessage = "Please log in to continue.";
          _navigateToLogin = true;
        });
        Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
      }
    } on SocketException catch (e) {
      setState(() {
        _statusMessage = "No internet connection. Please connect to the internet.";
        _isLoading = false;
      });

      setState(() {
        _navigateToLogin = true;
      });
      Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
    } catch (error) {
      print(error);
      setState(() {
        _statusMessage = "An error occurred. Please try again.";
        _isLoading = false;
      });

      if (_retryCount < _maxRetries - 1) {
        _retryAutoLogin(mobileNumber, pin);
      } else {
        setState(() {
          _statusMessage = "Please log in to continue.";
          _navigateToLogin = true;
        });
        Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
      }
    }
  }

  void _retryAutoLogin(String mobileNumber, String pin) {
    _retryCount++;
    if (_retryCount < _maxRetries) {
      Timer(_retryDelay, () {
        _attemptAutoLogin(mobileNumber, pin);
      });
    }
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  void _navigateToDashboardScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final logoWidth = screenWidth * 0.6;
    final logoHeight = screenHeight * 0.3;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/splash_b.png',
              fit: BoxFit.cover,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Image.asset(
                      'assets/images/logob.png',
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _textFadeInAnimation,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: 20.0 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        const CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        )
                      else
                        const SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:Webdoc/utils/shared_preferences.dart';
// import '../constants/ApiConstants.dart';
// import '../theme/app_colors.dart';
// import 'login_screen.dart';
// import 'dashboard_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _revealAnimation;
//   late Animation<double> _logoScaleAnimation; // Optional subtle bounce
//   String _statusMessage = "Initializing...";
//   bool _isLoading = false;
//   bool _autoLoginAttempted = false;
//   int _retryCount = 0;
//   static const int _maxRetries = 3;
//   static const Duration _initialDelay = Duration(seconds: 3);
//   static const Duration _retryDelay = Duration(seconds: 3);
//   bool _navigateToLogin = false;
//   late Animation<double> _textFadeInAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//
//     _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//
//     _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(
//           parent: _animationController, curve: Curves.easeInOutBack),
//     );
//
//     _textFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Interval(0.7, 1.0, curve: Curves.easeIn),
//       ),
//     );
//
//     _animationController.forward();
//
//     Timer(_initialDelay, () {
//       _checkLoginAndNavigate();
//     });
//   }
//
//   Future<void> _checkLoginAndNavigate() async {
//     String? mobileNumber = SharedPreferencesManager.getString('mobileNumber');
//     String? pin = SharedPreferencesManager.getString('pin');
//
//     if (mobileNumber != null && pin != null) {
//       if (!_autoLoginAttempted) {
//         _autoLoginAttempted = true;
//         _attemptAutoLogin(mobileNumber, pin);
//       }
//     } else {
//       _navigateToLoginScreen();
//     }
//   }
//
//   Future<void> _attemptAutoLogin(String mobileNumber, String pin) async {
//     if (_navigateToLogin) return;
//
//     setState(() {
//       _isLoading = true;
//       _statusMessage =
//       "Attempting Auto Login (Attempt ${_retryCount + 1} of $_maxRetries)...";
//     });
//
//     final Uri apiUrl = Uri.parse(
//         '${ApiConstants.baseUrl}${ApiConstants.patientLoginEndpoint}');
//
//     try {
//       final response = await http
//           .post(
//         apiUrl,
//         headers: {'accept': '*/*', 'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "phone": mobileNumber,
//           "password": pin,
//         }),
//       )
//           .timeout(
//         const Duration(seconds: 15),
//       );
//
//       final Map<String, dynamic> responseData = jsonDecode(response.body);
//
//       if (responseData['statusCode'] == 1) {
//
//         final userData = responseData['payLoad']?['user'];
//
//         if (userData != null) {
//           // Now, store the data in SharedPreferences
//           await SharedPreferencesManager.putString(
//               'id', userData['Id']?.toString() ?? ''); // Use toString()
//           await SharedPreferencesManager.putString(
//               'mobileNumber', userData['PhoneNumber']?.toString() ?? ''); // Use toString()
//           await SharedPreferencesManager.putString(
//               'name', userData['UserName'] ?? '');
//           await SharedPreferencesManager.putBool(
//               'isPackageActivated', userData['isPackageActivated'] ?? false);
//         }
//         _navigateToDashboardScreen();
//       } else {
//         setState(() {
//           _statusMessage =
//           "Auto Login Failed: ${responseData['statusMessage'] ?? 'Unknown error'}.";
//           _isLoading = false;
//         });
//
//         if (_retryCount < _maxRetries - 1) {
//           _retryAutoLogin(mobileNumber, pin);
//         } else {
//           setState(() {
//             _statusMessage = "Auto Login Failed. Please Login Manually.";
//             _navigateToLogin = true;
//           });
//           Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//         }
//       }
//     } on TimeoutException catch (e) {
//       setState(() {
//         _statusMessage =
//         "Auto Login Timeout (Attempt ${_retryCount + 1} of $_maxRetries).";
//         _isLoading = false;
//       });
//
//       if (_retryCount < _maxRetries - 1) {
//         _retryAutoLogin(mobileNumber, pin);
//       } else {
//         setState(() {
//           _statusMessage = "Auto Login Failed. Please Login Manually.";
//           _navigateToLogin = true;
//         });
//         Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//       }
//     } on SocketException catch (e) {
//       setState(() {
//         _statusMessage = "No Internet Connection. Please check your network.";
//         _isLoading = false;
//       });
//
//       setState(() {
//         _navigateToLogin = true;
//       });
//       Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//     } catch (error) {
//       print(error);
//       setState(() {
//         _statusMessage = "An unexpected error occurred.";
//         _isLoading = false;
//       });
//
//       if (_retryCount < _maxRetries - 1) {
//         _retryAutoLogin(mobileNumber, pin);
//       } else {
//         setState(() {
//           _statusMessage = "Auto Login Failed. Please Login Manually.";
//           _navigateToLogin = true;
//         });
//         Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//       }
//     }
//   }
//
//   void _retryAutoLogin(String mobileNumber, String pin) {
//     _retryCount++;
//     if (_retryCount < _maxRetries) {
//       Timer(_retryDelay, () {
//         _attemptAutoLogin(mobileNumber, pin);
//       });
//     }
//   }
//
//   void _navigateToLoginScreen() {
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (_) => LoginScreen()));
//   }
//
//   void _navigateToDashboardScreen() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => DashboardScreen()),
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     final logoWidth = screenWidth * 0.6; // Adjust as needed
//     final logoHeight = screenHeight * 0.3; // Adjust as needed
//
//     return Scaffold(
//       body: Container(
//         color: Colors.white, // Set the background color to white
//         child: Stack(
//           fit: StackFit.expand, // Important: Make the Stack fill the entire screen
//           children: [
//             // Background Image
//             Image.asset(
//               'assets/images/splash_b.png', // Replace with your image path
//               fit: BoxFit.cover, // Cover the entire screen
//             ),
//
//             // Centered Content
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Logo with Scale Transition
//                   ScaleTransition(
//                     scale: _logoScaleAnimation,
//                     child: Image.asset(
//                       'assets/images/logob.png', // Replace with your logo path
//                       width: logoWidth,
//                       height: logoHeight,
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//
//                   SizedBox(height: 20), // Add some spacing
//                 ],
//               ),
//             ),
//
//             // Fade-in Text with Loading Indicator at the bottom
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: FadeTransition(
//                 opacity: _textFadeInAnimation,
//                 child: Padding(
//                   padding: EdgeInsets.only(bottom: 20.0 + MediaQuery.of(context).padding.bottom),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (_isLoading)
//                         const CircularProgressIndicator(
//                           color: AppColors.primaryColor, // Use your primary color
//                         )
//                       else
//                         const SizedBox.shrink(),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           _statusMessage,
//                           style: const TextStyle(
//                               fontSize: 14, color: Colors.grey),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// import 'package:Webdoc/theme/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math' as math;
//
// import 'package:Webdoc/utils/shared_preferences.dart';
// import '../constants/ApiConstants.dart';
// import 'login_screen.dart';
// import 'dashboard_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _revealAnimation;
//   late Animation<double> _logoScaleAnimation; // Optional subtle bounce
//   String _statusMessage = "Initializing...";
//   bool _isLoading = false;
//   bool _autoLoginAttempted = false;
//   int _retryCount = 0;
//   static const int _maxRetries = 3;
//   static const Duration _initialDelay = Duration(seconds: 3);
//   static const Duration _retryDelay = Duration(seconds: 3);
//   bool _navigateToLogin = false;
//   late Animation<double> _textFadeInAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//
//     _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//
//     _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(
//           parent: _animationController, curve: Curves.easeInOutBack),
//     );
//
//     _textFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Interval(0.7, 1.0, curve: Curves.easeIn), // Fade in during last 30%
//       ),
//     );
//
//     _animationController.forward();
//
//     Timer(_initialDelay, () {
//       _checkLoginAndNavigate();
//     });
//   }
//
//   Future<void> _checkLoginAndNavigate() async {
//     String? mobileNumber = SharedPreferencesManager.getString('mobileNumber');
//     String? pin = SharedPreferencesManager.getString('pin');
//
//     if (mobileNumber != null && pin != null) {
//       if (!_autoLoginAttempted) {
//         _autoLoginAttempted = true;
//         _attemptAutoLogin(mobileNumber, pin);
//       }
//     } else {
//       _navigateToLoginScreen();
//     }
//   }
//
//   Future<void> _attemptAutoLogin(String mobileNumber, String pin) async {
//     if (_navigateToLogin) return;
//
//     setState(() {
//       _isLoading = true;
//       _statusMessage =
//       "Attempting Auto Login (Attempt ${_retryCount + 1} of $_maxRetries)...";
//     });
//
//     final Uri apiUrl = Uri.parse(
//         '${ApiConstants.baseUrl}${ApiConstants.patientLoginEndpoint}');
//
//     try {
//       final response = await http
//           .post(
//         apiUrl,
//         headers: {'accept': '*/*', 'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "mobileNumber": mobileNumber,
//           "pin": pin,
//           "os": "android",
//           "devicetoken": "string"
//         }),
//       )
//           .timeout(
//         const Duration(seconds: 15),
//       );
//
//       final Map<String, dynamic> responseData = jsonDecode(response.body);
//
//       if (responseData['ResponseCode'] == '0000') {
//         _navigateToDashboardScreen();
//       } else {
//         setState(() {
//           _statusMessage =
//           "Auto Login Failed: ${responseData['message'] ?? 'Unknown error'}.";
//           _isLoading = false;
//         });
//
//         if (_retryCount < _maxRetries - 1) { // Moved the retry check here
//           _retryAutoLogin(mobileNumber, pin);
//         } else {
//           setState(() {
//             _statusMessage = "Auto Login Failed. Please Login Manually.";
//             _navigateToLogin = true;
//           });
//           Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//         }
//       }
//     } on TimeoutException catch (e) {
//       setState(() {
//         _statusMessage =
//         "Auto Login Timeout (Attempt ${_retryCount + 1} of $_maxRetries).";
//         _isLoading = false;
//       });
//
//       if (_retryCount < _maxRetries - 1) {
//         _retryAutoLogin(mobileNumber, pin);
//       } else {
//         setState(() {
//           _statusMessage = "Auto Login Failed. Please Login Manually.";
//           _navigateToLogin = true;
//         });
//         Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//       }
//     } on SocketException catch (e) {
//       setState(() {
//         _statusMessage = "No Internet Connection. Please check your network.";
//         _isLoading = false;
//       });
//
//       setState(() {
//         _navigateToLogin = true;
//       });
//       Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//     } catch (error) {
//       print(error);
//       setState(() {
//         _statusMessage = "An unexpected error occurred.";
//         _isLoading = false;
//       });
//
//       if (_retryCount < _maxRetries - 1) {
//         _retryAutoLogin(mobileNumber, pin);
//       } else {
//         setState(() {
//           _statusMessage = "Auto Login Failed. Please Login Manually.";
//           _navigateToLogin = true;
//         });
//         Timer(const Duration(seconds: 2), () => _navigateToLoginScreen());
//       }
//     }
//   }
//
//   void _retryAutoLogin(String mobileNumber, String pin) {
//     _retryCount++;
//     if (_retryCount < _maxRetries) { // Double check before scheduling another retry
//       Timer(_retryDelay, () {
//         _attemptAutoLogin(mobileNumber, pin);
//       });
//     }
//   }
//
//   void _navigateToLoginScreen() {
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (_) => LoginScreen()));
//   }
//
//   void _navigateToDashboardScreen() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => DashboardScreen()),
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     // Calculate dynamic width and height based on screen size.  You can adjust the percentages to fit your design.
//     final logoWidth = screenWidth * 0.6; // 60% of screen width
//     final logoHeight = screenHeight * 0.3; // 30% of screen height
//     return Scaffold(
//       backgroundColor: AppColors.primaryColor.withOpacity(0.5),
//       body: Stack(
//         children: [
//           // Circular Reveal
//           AnimatedBuilder(
//             animation: _animationController,
//             builder: (context, child) {
//               return ClipPath(
//                 clipper: CircularRevealClipper(
//                     revealPercent: _revealAnimation.value),
//                 child: Container(
//                   color: Colors.white, // Color behind the logo
//                   child: Center(
//                     child: ScaleTransition(
//                       scale: _logoScaleAnimation,
//                       child: Image.asset(
//                         'assets/images/images/logo.png',
//                         width: logoWidth,
//                         height: logoHeight,
//                         fit: BoxFit.contain,// Optional: how the image should be inscribed into the space
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Fade in Text
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: FadeTransition(
//               opacity: _textFadeInAnimation,
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (_isLoading)
//                       const CircularProgressIndicator(color: Colors.black)
//                     else
//                       const SizedBox.shrink(),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8.0),
//                       child: Text(
//                         _statusMessage,
//                         style: const TextStyle(fontSize: 14, color: Colors.grey),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class CircularRevealClipper extends CustomClipper<Path> {
//   final double revealPercent;
//
//   CircularRevealClipper({required this.revealPercent});
//
//   @override
//   Path getClip(Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = math.sqrt(
//         size.width * size.width + size.height * size.height) * revealPercent;
//     return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
//   }
//
//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
//     return true;
//   }
// }


