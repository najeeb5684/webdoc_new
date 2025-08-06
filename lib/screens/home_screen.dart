

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:Webdoc/screens/package_screen.dart';
import 'package:Webdoc/screens/specialist_category_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/login_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'account_screen.dart';
import 'appointment_screen.dart';
import 'doctor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isPackageActivated = false;
  String? _packageName;
  Timer? _apiTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_animationController);

    _loadPackageDetails(); // Load initial values
    _startApiPolling();
  }

  Future<void> _loadPackageDetails() async {
    final isPackageActivated = SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    final packageName = SharedPreferencesManager.getString("packageName");

    if (mounted) {
      setState(() {
        _isPackageActivated = isPackageActivated;
        _packageName = packageName;
      });
    }
  }

  void _startApiPolling() {

    _apiTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      _loginAfterActivatePackage();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _apiTimer?.cancel();
    super.dispose();
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return "User Name";
    List<String> words = text.split(" ");
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(" ");
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "UU";
    List<String> names = name.split(' ');
    String initials = '';
    for (var i = 0; i < names.length; i++) {
      if (names[i].isNotEmpty) initials += names[i][0].toUpperCase();
      if (i == 1) break;
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardCount = 4;
    final cardSpacing = 10;
    final totalSpacingWidth = (cardCount - 1) * cardSpacing;
    final availableWidth = screenWidth - (32 + totalSpacingWidth);
    final cardWidth = availableWidth / cardCount;

    Image img = Image.asset('assets/images/international_comingsoon.png');
    Completer<Size> completer = Completer<Size>();
    img.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool syncCall) {
        completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }),
    );

    return FutureBuilder<Size>(
      future: completer.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data == null)
          return Center(child: Text('No image data'));

        final imageWidth = snapshot.data!.width;
        final imageHeight = snapshot.data!.height;
        final double calculatedHeight = screenWidth * (imageHeight / imageWidth);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen()));
              },
              child: AppBar(
                backgroundColor: AppColors.backgroundColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          _getInitials(
                            _capitalizeFirstLetter(SharedPreferencesManager.getString("name")),
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Align content vertically
                          children: [
                            Text(
                              _capitalizeFirstLetter(
                                  SharedPreferencesManager.getString("name")) ??
                                  "User Name",
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.titleMedium(context)
                                  .copyWith(color: AppColors.primaryTextColor),
                            ),
                            Text(
                              SharedPreferencesManager.getString("mobileNumber") ??
                                  "Phone Number",
                              style: AppStyles.bodyMedium(context)
                                  .copyWith(color: AppColors.primaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      // Conditional Button Display
                      if ((_packageName == 'Free Call' && _isPackageActivated) || (!_isPackageActivated && _packageName != 'Free Call'))
                        FadeTransition(
                          opacity: _animation,
                          child: GestureDetector(
                            onTap: () {
                              if (_packageName == 'Free Call' && _isPackageActivated) {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => DoctorListScreen(),
                                  ),
                                );
                              } else if (!_isPackageActivated && _packageName != 'Free Call') {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => PackageScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                (_packageName == 'Free Call' && _isPackageActivated) ? "Free Call" : "Subscribe Now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DoctorListScreen()));
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/instant_ban.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 45,
                          left: 10,
                          child: Text(
                            "Instant Doctors",
                            style: AppStyles.titleSmall(context)
                                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          top: 65,
                          left: 10,
                          child: Text(
                            "Doctor in your \npocket",
                            style: AppStyles.bodyMedium(context)
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DoctorListScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              textStyle: AppStyles.bodyLarge(context)
                                  .copyWith(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100)),
                              minimumSize: Size.zero,
                            ),
                            child: Text("Click Here",
                                style: AppStyles.bodySmall(context).copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildSectionHeader("Specialist Doctors", context, onSeeAllTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SpecialistCategoryScreen()));
                }),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryCard(context: context, icon: 'assets/images/gyne.png', label: "Gynecologist", width: cardWidth, categoryId: 24),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/pedia.png', label: "Pediatrician", width: cardWidth, categoryId: 31),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/gastro.png', label: "Gastro", width: cardWidth, categoryId: 9),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/urolo.png', label: "Urologist", width: cardWidth, categoryId: 44),
                  ],
                ),
                SizedBox(height: 20),
                _buildSectionHeader("International Doctors", context, onSeeAllTap: () {
                  _showComingSoonDialog(context);
                }),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showComingSoonDialog(context),
                  child: Container(
                    width: double.infinity,
                    height: calculatedHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/international_comingsoon.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeTransition(
                                opacity: _animation,
                                child: Text(
                                  "Coming Soon",
                                  style: AppStyles.titleLarge(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 0.5, color: Colors.white, offset: Offset(1.0, 1.0))]),
                                ),
                              ),
                              Text(
                                "\nExplore healthcare across\nborders with our global\nnetwork of skilled doctors.",
                                style: AppStyles.bodyMedium(context).copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context, {VoidCallback? onSeeAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppStyles.titleMedium(context).copyWith(color: AppColors.primaryTextColor)),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Text("See All", style: AppStyles.bodyMedium(context).copyWith(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String icon,
    required String label,
    double? width,
    required int categoryId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AppointmentScreen(specialityId: categoryId),
        ));
      },
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 30, height: 30, color: AppColors.primaryColor),
            SizedBox(height: 4),
            Text(label, style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          title: Text("Coming Soon"),
          content: Text("This feature is under development."),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: AppColors.primaryColor),),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loginAfterActivatePackage() async {
    final String? mobileNumber =
        SharedPreferencesManager.getString("mobileNumber") ?? "Phone Number";
    final String? pin = SharedPreferencesManager.getString("pin") ?? "Pin";

    if (mobileNumber == "Phone Number" || pin == "Pin") {
      print("Mobile number or PIN not found in SharedPreferences. Skipping login.");
      return;
    }


    try {
      final url = Uri.parse('${ApiService.irfanBaseUrl}${ApiService.patientLoginEndpoint}');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'phone': mobileNumber,
        'password': pin,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(decodedJson);

        if (loginResponse.statusCode == 1) {
          // Get the updated values *before* calling setState
          final newIsPackageActivated = loginResponse.payLoad?.user?.isPackageActivated ?? false;
          final newPackageName = loginResponse.payLoad?.user?.packageName ?? '';

          // Update Shared Preferences
          SharedPreferencesManager.putBool("isPackageActivated", newIsPackageActivated);
          SharedPreferencesManager.putString("packageName", newPackageName);

          // Update the UI, but only if the values have actually changed
          if (newIsPackageActivated != _isPackageActivated || newPackageName != _packageName) {
            _loadPackageDetails();  // Load the details after settings prefs.
          }
        } else {
          String errorMessage = "Login Failed";
          if(loginResponse.statusMessage != null){
            errorMessage = loginResponse.statusMessage!.join(', ');
          }
          print("Login API Error: $errorMessage"); // Log the error
        }
      } else {
        print('Login failed: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');

    } catch (e) {
      print('Login error: $e');
    }
  }
/*  Future<void> _loginAfterActivatePackage(ApiService apiService) async {
    final String? mobileNumber =
        SharedPreferencesManager.getString("mobileNumber") ?? "Phone Number";
    final String? pin = SharedPreferencesManager.getString("pin") ?? "Pin";

    try {
      final loginResponse = await apiService.login(context, mobileNumber!, pin!);
      if (loginResponse != null && loginResponse.statusCode == 1) {
        // Get the updated values *before* calling setState
        final newIsPackageActivated = loginResponse.payLoad?.user?.isPackageActivated ?? false;
        final newPackageName = loginResponse.payLoad?.user?.packageName ?? '';

        // Update Shared Preferences
        SharedPreferencesManager.putBool("isPackageActivated", newIsPackageActivated);
        SharedPreferencesManager.putString("packageName", newPackageName);

        // Update the UI, but only if the values have actually changed
        if (newIsPackageActivated != _isPackageActivated || newPackageName != _packageName) {
          _loadPackageDetails();  // Load the details after settings prefs.
        }
      } else {
        String errorMessage = "Login Failed";
        errorMessage = loginResponse!.statusMessage!.join(', ');
        print("Login API Error: $errorMessage"); // Log the error
      }
    } catch (error) {
      print("API error: $error"); // Log the error
    }
  }*/
}



/*import 'dart:async';
import 'dart:ui';

import 'package:Webdoc/screens/package_screen.dart';
import 'package:Webdoc/screens/specialist_category_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'account_screen.dart';
import 'appointment_screen.dart';
import 'doctor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isPackageActivated = false;
  String? _packageName;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_animationController);

    _loadPackageDetails();
  }

  Future<void> _loadPackageDetails() async {
    _isPackageActivated = SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _packageName = SharedPreferencesManager.getString("packageName");
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return "User Name";
    List<String> words = text.split(" ");
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(" ");
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "UU";
    List<String> names = name.split(' ');
    String initials = '';
    for (var i = 0; i < names.length; i++) {
      if (names[i].isNotEmpty) initials += names[i][0].toUpperCase();
      if (i == 1) break;
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardCount = 4;
    final cardSpacing = 10;
    final totalSpacingWidth = (cardCount - 1) * cardSpacing;
    final availableWidth = screenWidth - (32 + totalSpacingWidth);
    final cardWidth = availableWidth / cardCount;

    Image img = Image.asset('assets/images/international_comingsoon.png');
    Completer<Size> completer = Completer<Size>();
    img.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool syncCall) {
        completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }),
    );

    return FutureBuilder<Size>(
      future: completer.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data == null)
          return Center(child: Text('No image data'));

        final imageWidth = snapshot.data!.width;
        final imageHeight = snapshot.data!.height;
        final double calculatedHeight = screenWidth * (imageHeight / imageWidth);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen()));
              },
              child: AppBar(
                backgroundColor: AppColors.backgroundColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          _getInitials(
                            _capitalizeFirstLetter(SharedPreferencesManager.getString("name")),
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Align content vertically
                          children: [
                            Text(
                              _capitalizeFirstLetter(
                                  SharedPreferencesManager.getString("name")) ??
                                  "User Name",
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.titleMedium(context)
                                  .copyWith(color: AppColors.primaryTextColor),
                            ),
                            Text(
                              SharedPreferencesManager.getString("mobileNumber") ??
                                  "Phone Number",
                              style: AppStyles.bodyMedium(context)
                                  .copyWith(color: AppColors.primaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      // Conditional Button Display
                      if ((_packageName == 'Free Call' && _isPackageActivated) || (!_isPackageActivated && _packageName != 'Free Call'))
                        FadeTransition(
                          opacity: _animation,
                          child: GestureDetector(
                            onTap: () {
                              if (_packageName == 'Free Call' && _isPackageActivated) {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => DoctorListScreen(),
                                  ),
                                );
                              } else if (!_isPackageActivated && _packageName != 'Free Call') {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => PackageScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                (_packageName == 'Free Call' && _isPackageActivated) ? "Free Call" : "Subscribe Now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DoctorListScreen()));
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/instant_ban.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 45,
                          left: 10,
                          child: Text(
                            "Instant Doctors",
                            style: AppStyles.titleSmall(context)
                                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          top: 65,
                          left: 10,
                          child: Text(
                            "Doctor in your \npocket",
                            style: AppStyles.bodyMedium(context)
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DoctorListScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              textStyle: AppStyles.bodyLarge(context)
                                  .copyWith(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100)),
                              minimumSize: Size.zero,
                            ),
                            child: Text("Click Here",
                                style: AppStyles.bodySmall(context).copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildSectionHeader("Specialist Doctors", context, onSeeAllTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SpecialistCategoryScreen()));
                }),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryCard(context: context, icon: 'assets/images/gyne.png', label: "Gynecologist", width: cardWidth, categoryId: 24),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/pedia.png', label: "Pediatrician", width: cardWidth, categoryId: 31),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/gastro.png', label: "Gastro", width: cardWidth, categoryId: 9),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/urolo.png', label: "Urologist", width: cardWidth, categoryId: 44),
                  ],
                ),
                SizedBox(height: 20),
                _buildSectionHeader("International Doctors", context, onSeeAllTap: () {
                  _showComingSoonDialog(context);
                }),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showComingSoonDialog(context),
                  child: Container(
                    width: double.infinity,
                    height: calculatedHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/international_comingsoon.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeTransition(
                                opacity: _animation,
                                child: Text(
                                  "Coming Soon",
                                  style: AppStyles.titleLarge(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 0.5, color: Colors.white, offset: Offset(1.0, 1.0))]),
                                ),
                              ),
                              Text(
                                "\nExplore healthcare across\nborders with our global\nnetwork of skilled doctors.",
                                style: AppStyles.bodyMedium(context).copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context, {VoidCallback? onSeeAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppStyles.titleMedium(context).copyWith(color: AppColors.primaryTextColor)),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Text("See All", style: AppStyles.bodyMedium(context).copyWith(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String icon,
    required String label,
    double? width,
    required int categoryId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AppointmentScreen(specialityId: categoryId),
        ));
      },
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 30, height: 30, color: AppColors.primaryColor),
            SizedBox(height: 4),
            Text(label, style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          title: Text("Coming Soon"),
          content: Text("This feature is under development."),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: AppColors.primaryColor),),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
  Future<void> _loginAfterActivatePackage(ApiService apiService) async {
    final String? mobileNumber =
        SharedPreferencesManager.getString("mobileNumber") ?? "Phone Number";
    final String? pin = SharedPreferencesManager.getString("pin") ?? "Pin";


    try {
      final loginResponse = await apiService.login(context, mobileNumber!, pin!);
      if (loginResponse != null &&
          loginResponse.statusCode == 1) {
        // Update Shared Preferences with login data (activated date, expiry date etc)
        SharedPreferencesManager.putBool("isPackageActivated",
            loginResponse.payLoad?.user?.isPackageActivated ?? false);
        SharedPreferencesManager.putString(
            "expiryDate", loginResponse.payLoad?.user?.expiryDate ?? '');
        SharedPreferencesManager.putString(
            "activeDate", loginResponse.payLoad?.user?.activeDate ?? '');
        SharedPreferencesManager.putString(
            "packageName", loginResponse.payLoad?.user?.packageName ?? '');


      } else {
        String errorMessage = "Login Failed";

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

        errorMessage = loginResponse!.statusMessage!.join(', ');

      }
    } catch (error) {
      Navigator.of(context).pop(); // Dismiss loading dialog
    }
  }
}*/







/*import 'dart:async';
import 'dart:ui';

import 'package:Webdoc/screens/package_screen.dart';
import 'package:Webdoc/screens/specialist_category_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'account_screen.dart';
import 'appointment_screen.dart';
import 'doctor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isPackageActivated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_animationController);

    // _checkPackageActivation();
    _isPackageActivated = SharedPreferencesManager.getBool('isPackageActivated') ?? false;
  }

  Future<void> _checkPackageActivation() async {

    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return "User Name";
    List<String> words = text.split(" ");
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(" ");
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "UU";
    List<String> names = name.split(' ');
    String initials = '';
    for (var i = 0; i < names.length; i++) {
      if (names[i].isNotEmpty) initials += names[i][0].toUpperCase();
      if (i == 1) break;
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardCount = 4;
    final cardSpacing = 10;
    final totalSpacingWidth = (cardCount - 1) * cardSpacing;
    final availableWidth = screenWidth - (32 + totalSpacingWidth);
    final cardWidth = availableWidth / cardCount;

    Image img = Image.asset('assets/images/international_comingsoon.png');
    Completer<Size> completer = Completer<Size>();
    img.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool syncCall) {
        completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }),
    );

    return FutureBuilder<Size>(
      future: completer.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data == null)
          return Center(child: Text('No image data'));

        final imageWidth = snapshot.data!.width;
        final imageHeight = snapshot.data!.height;
        final double calculatedHeight = screenWidth * (imageHeight / imageWidth);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen()));
              },
              child: AppBar(
                backgroundColor: AppColors.backgroundColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          _getInitials(
                            _capitalizeFirstLetter(SharedPreferencesManager.getString("name")),
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Align content vertically
                          children: [
                            Text(
                              _capitalizeFirstLetter(
                                  SharedPreferencesManager.getString("name")) ??
                                  "User Name",
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.titleMedium(context)
                                  .copyWith(color: AppColors.primaryTextColor),
                            ),
                            Text(
                              SharedPreferencesManager.getString("mobileNumber") ??
                                  "Phone Number",
                              style: AppStyles.bodyMedium(context)
                                  .copyWith(color: AppColors.primaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      if (!_isPackageActivated)
                        FadeTransition(
                          opacity: _animation,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                "Subscribe Now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DoctorListScreen()));
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/instant_ban.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 45,
                          left: 10,
                          child: Text(
                            "Instant Doctors",
                            style: AppStyles.titleSmall(context)
                                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          top: 65,
                          left: 10,
                          child: Text(
                            "Doctor in your \npocket",
                            style: AppStyles.bodyMedium(context)
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DoctorListScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              textStyle: AppStyles.bodyLarge(context)
                                  .copyWith(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100)),
                              minimumSize: Size.zero,
                            ),
                            child: Text("Click Here",
                                style: AppStyles.bodySmall(context).copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildSectionHeader("Specialist Doctors", context, onSeeAllTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SpecialistCategoryScreen()));
                }),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryCard(context: context, icon: 'assets/images/gyne.png', label: "Gynecologist", width: cardWidth, categoryId: 24),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/pedia.png', label: "Pediatrician", width: cardWidth, categoryId: 31),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/gastro.png', label: "Gastro", width: cardWidth, categoryId: 9),
                    SizedBox(width: 10),
                    _buildCategoryCard(context: context, icon: 'assets/images/urolo.png', label: "Urologist", width: cardWidth, categoryId: 44),
                  ],
                ),
                SizedBox(height: 20),
                _buildSectionHeader("International Doctors", context, onSeeAllTap: () {
                  _showComingSoonDialog(context);
                }),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showComingSoonDialog(context),
                  child: Container(
                    width: double.infinity,
                    height: calculatedHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/international_comingsoon.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeTransition(
                                opacity: _animation,
                                child: Text(
                                  "Coming Soon",
                                  style: AppStyles.titleLarge(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(blurRadius: 0.5, color: Colors.white, offset: Offset(1.0, 1.0))]),
                                ),
                              ),
                              Text(
                                "\nExplore healthcare across\nborders with our global\nnetwork of skilled doctors.",
                                style: AppStyles.bodyMedium(context).copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context, {VoidCallback? onSeeAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppStyles.titleMedium(context).copyWith(color: AppColors.primaryTextColor)),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Text("See All", style: AppStyles.bodyMedium(context).copyWith(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String icon,
    required String label,
    double? width,
    required int categoryId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AppointmentScreen(specialityId: categoryId),
        ));
      },
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 30, height: 30, color: AppColors.primaryColor),
            SizedBox(height: 4),
            Text(label, style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          title: Text("Coming Soon"),
          content: Text("This feature is under development."),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: AppColors.primaryColor),),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}*/











