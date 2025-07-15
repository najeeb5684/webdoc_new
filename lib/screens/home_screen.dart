

import 'dart:async';
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
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}


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
                title: Row(
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Patient Profile",
                                    style: AppStyles.bodySmall(context).copyWith(
                                        color: AppColors.secondaryTextColor),
                                  ),
                                //  SizedBox(height: 2), // Reduced space
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
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        ],
                      ),
                    ),
                  ],
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
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
                title: Row(
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Patient Profile",
                                style: AppStyles.bodySmall(context).copyWith(
                                    color: AppColors.secondaryTextColor),
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
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                ),


                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _capitalizeFirstLetter(
                                      SharedPreferencesManager.getString("name")) ??
                                      "User Name",
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyles.titleMedium(context)
                                      .copyWith(color: AppColors.primaryTextColor),
                                ),
                              ),
                              Text(
                                SharedPreferencesManager.getString("mobileNumber") ??
                                    "Phone Number",
                                style: AppStyles.bodyMedium(context)
                                    .copyWith(color: AppColors.primaryTextColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}*/



/*import 'dart:async';
import 'dart:ui';

import 'package:Webdoc/screens/specialist_category_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation =
        Tween<double>(begin: 0.2, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) {
      return "User Name"; // Default text
    }
    // Split the string into words
    List<String> words = text.split(" ");

    // Capitalize the first letter of each word
    List<String> capitalizedWords = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      } else {
        return word;
      }
    }).toList();

    // Join the words back together
    return capitalizedWords.join(" ");
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return "UU"; // Default initial if name is missing
    }
    List<String> names = name.split(' ');
    String initials = '';
    for (var i = 0; i < names.length; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
      if (i == 1) break; // Take only first two names
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
    // Fetch dimensions of the image
    Image img = Image.asset('assets/images/international_comingsoon.png');
    Completer<Size> completer = Completer<Size>();
    img.image
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
      final Size imageSize = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      completer.complete(imageSize);
    }));
    return FutureBuilder<Size>(
        future: completer.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Handle errors
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No image data')); // Handle no data
          } else {
            // *** Added explicit null check here ***
            if (snapshot.data == null) {
              return Center(child: Text("Data is unexpectedly null!"));
            }

            final imageWidth = snapshot.data!.width;
            final imageHeight = snapshot.data!.height;
            // calculate height from dimensions.
            final double calculatedHeight =
                screenWidth * (imageHeight / imageWidth);
            return Scaffold(
              backgroundColor: AppColors.backgroundColor,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(70),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AccountScreen()),
                    );
                  },
                  child: AppBar(
                    backgroundColor: AppColors.backgroundColor,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryColor,
                            child: Text(
                              _getInitials(_capitalizeFirstLetter(
                                  SharedPreferencesManager.getString("name"))),
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Patient Profile",
                                      style: AppStyles.bodySmall(context).copyWith(
                                          color: AppColors.secondaryTextColor),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _capitalizeFirstLetter(
                                            SharedPreferencesManager.getString(
                                                "name")) ??
                                            "User Name",
                                        overflow: TextOverflow.ellipsis,
                                        style: AppStyles.titleMedium(context).copyWith(
                                            color: AppColors.primaryTextColor),
                                      ),
                                    ),
                                    Text(
                                      SharedPreferencesManager.getString(
                                          "mobileNumber") ??
                                          "Phone Number",
                                      style: AppStyles.bodyMedium(context).copyWith(
                                          color: AppColors.primaryTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DoctorListScreen()));
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
                                  style: AppStyles.titleSmall(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Positioned(
                                top: 65,
                                left: 10,
                                child: Text(
                                  "Doctor in your \npocket",
                                  style: AppStyles.bodyMedium(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                            const DoctorListScreen()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primaryColor,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    textStyle: AppStyles.bodyLarge(context).copyWith(
                                        fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
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
                    ),
                    SizedBox(height: 20),
                    _buildSectionHeader("Specialist Doctors", context,
                        onSeeAllTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SpecialistCategoryScreen()),
                          );
                        }),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryCard(
                            context: context,
                            icon: 'assets/images/gyne.png',
                            label: "Gynecologist",
                            width: cardWidth,
                            categoryId: 24),
                        SizedBox(width: 10),
                        _buildCategoryCard(
                            context: context,
                            icon: 'assets/images/pedia.png',
                            label: "Pediatrician",
                            width: cardWidth,
                            categoryId: 31),
                        SizedBox(width: 10),
                        _buildCategoryCard(
                            context: context,
                            icon: 'assets/images/gastro.png',
                            label: "Gastro",
                            width: cardWidth,
                            categoryId: 9),
                        SizedBox(width: 10),
                        _buildCategoryCard(
                            context: context,
                            icon: 'assets/images/urolo.png',
                            label: "Urologist",
                            width: cardWidth,
                            categoryId: 44),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildSectionHeader("International Doctors", context,
                        onSeeAllTap: () {
                          _showComingSoonDialog(context);
                        }),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        _showComingSoonDialog(context);
                      },
                      child: Container(
                        width: double.infinity,
                        height: calculatedHeight,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/international_comingsoon.png'),
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
                                          shadows: [
                                            Shadow(
                                              blurRadius: 0.5,
                                              color: Colors.white,
                                              offset: Offset(1.0, 1.0),
                                            ),
                                          ]),
                                    ),
                                  ),
                                  Text(
                                    "\nExplore healthcare across\nborders with our global\nnetwork of skilled doctors.",
                                    style: AppStyles.bodyMedium(context).copyWith(
                                      color: Colors.white,
                                    ),
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
          }
        });
  }

  Widget _buildSectionHeader(String title, BuildContext context,
      {VoidCallback? onSeeAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: AppStyles.titleMedium
              (context).copyWith(color: AppColors.primaryTextColor)),
        GestureDetector(
          onTap: onSeeAllTap, // Call the provided callback function
          child: Text("See All",
              style: AppStyles.bodyMedium
                (context).copyWith(color: AppColors.primaryColor)),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentScreen(specialityId: categoryId),
          ),
        );
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
            Image.asset(icon,
                width: 30, height: 30, color: AppColors.primaryColor),
            SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor),
              textAlign: TextAlign.center,
            ),
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
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}*/







