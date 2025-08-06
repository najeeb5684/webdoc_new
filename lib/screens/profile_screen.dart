import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io'; // Import for internet connectivity check

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _isLoading = true; // Initial loading state is TRUE
  bool _hasInternet = true;


  @override
  void initState() {
    super.initState();
    _checkInternetConnection(); // Check internet on init
  }


  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        _loadProfile(); // Load profile *after* confirming internet
      } else {
        setState(() {
          _hasInternet = false;
          _isLoading = false; // Stop loading if NO internet
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false; // Stop loading if NO internet
      });
    }
    // No finally block needed.  Errors/success handled above.
  }


  Future<void> _loadProfile() async {
    // setState(() {  // No need to set loading again.  Already set in _checkInternetConnection
    //   _isLoading = true;
    // });

    final apiService = ApiService();
    final phoneNumber = SharedPreferencesManager.getString('mobileNumber');

    if (phoneNumber != null) {
      final id = SharedPreferencesManager.getString('id');
      final profile = await apiService.getPatientProfile(context, id!);
      if (profile != null) {
        setState(() {
          _profile = profile;
          _isLoading = false; // Profile loaded, stop loading
        });
      } else {
        print("Failed to load profile");
        setState(() {
          _profile = null; // Explicitly set profile to null on failure
          _isLoading = false; // Stop loading even on failure
        });
      }
    } else {
      print('Phone number not found in SharedPreferences');
      setState(() {
        _profile = null; // Explicitly set profile to null if phone number not found
        _isLoading = false; // Stop loading
      });
    }

    // setState(() {  // No need to set loading again.
    //   _isLoading = false;
    // });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Profile',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: _getBody(),
    );
  }


  Widget _getBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)); // Show loading first
    }

    if (!_hasInternet) {
      return _buildNoInternet();
    }


    if (_profile == null) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Could not load profile. Please check your internet connection or try again later.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
            ),
          ));
    }



    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildProfileDetails(context),
              ],
            ),
          ),
        ),
        _buildEditProfileButton(context),
      ],
    );
  }


  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No internet connection.', style: GoogleFonts.poppins()),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true; // Start loading again when retrying
              });
              _checkInternetConnection();
            },
            child: Text('Try Again', style: GoogleFonts.poppins()),
          )
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return "U"; // Default initial if name is missing
    }
    List<String> names = name.split(' ');
    String initials = '';
    for (var i = 0; i < names.length; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
      if (i == 1) break; // Take only first two names
    }
    return initials;
  }
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryTextColor,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.cardColor,
              child: Text(
                _getInitials(SharedPreferencesManager.getString(
                    "name")), // Display initials
                style: TextStyle(
                    fontSize: 20,
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.payLoad.firstName ?? "N/A",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.phone, 'Phone:', _profile?.payLoad.mobileNumber ?? "N/A", AppColors.primaryColor), // Blue Accent
            _buildDetailRow(Icons.person, 'Gender:', _profile?.payLoad.gender ?? "N/A",  AppColors.primaryColor), // Pink Accent
            _buildDetailRow(Icons.favorite, 'Marital Status:', _profile?.payLoad.martialStatus ?? "N/A", AppColors.primaryColor), // Light Green
           // _buildDetailRow(Icons.email, 'Email:', "webdoc.com.pk", AppColors.primaryColor), // Orange Accent
            _buildDetailRow(Icons.calendar_today, 'DOB:', _profile?.payLoad.dateOfBirth ?? "N/A", AppColors.primaryColor), // Purple Accent
            _buildDetailRow(Icons.fitness_center, 'Weight:', _profile?.payLoad.weight ?? "N/A", AppColors.primaryColor), // Light Blue
            _buildDetailRow(Icons.straighten, 'Height:', _profile?.payLoad.height ?? "N/A", AppColors.primaryColor), // Cyan
            _buildDetailRow(Icons.cake, 'Age:', _profile?.payLoad.age ?? "N/A", AppColors.primaryColor), // Brown
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 0,
        bottom: 2 + MediaQuery.of(context).padding.bottom, // Add bottom padding
      ),
      decoration: BoxDecoration(
        color: Colors.white,
       // border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(profile: _profile!),
              ),
            ).then((value) {
              if (value == true) {
                _loadProfile();
              }
            });
          },
          child: const Text("Edit Profile"),
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final apiService = ApiService();
    final phoneNumber = SharedPreferencesManager.getString('mobileNumber');

    if (phoneNumber != null) {
      final email = '$phoneNumber@webdoc.com.pk';
      final profile = await apiService.getPatientProfile(context, email);
      if (profile != null) {
        setState(() {
          _profile = profile;
        });
      } else {
        print("Failed to load profile");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Phone number not found in SharedPreferences');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _profile == null
          ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Could not load profile. Please check your internet connection or try again later.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
            ),
          ))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildProfileDetails(context),
                ],
              ),
            ),
          ),
          _buildEditProfileButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.black.withOpacity(0.8)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?.profileDetails.name ?? "N/A",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.phone, 'Phone:', _profile?.profileDetails.mobileNumber ?? "N/A", const Color(0xFF42A5F5)), // Blue Accent
            _buildDetailRow(Icons.person, 'Gender:', _profile?.profileDetails.gender ?? "N/A", const Color(0xFFF48FB1)), // Pink Accent
            _buildDetailRow(Icons.favorite, 'Marital Status:', _profile?.profileDetails.martialStatus ?? "N/A", const Color(0xFFAED581)), // Light Green
            _buildDetailRow(Icons.email, 'Email:', _profile?.profileDetails.email ?? "N/A", const Color(0xFFFFB74D)), // Orange Accent
            _buildDetailRow(Icons.calendar_today, 'DOB:', _profile?.profileDetails.dateOfBirth ?? "N/A", const Color(0xFF9575CD)), // Purple Accent
            _buildDetailRow(Icons.fitness_center, 'Weight:', _profile?.profileDetails.weight ?? "N/A", const Color(0xFF64B5F6)), // Light Blue
            _buildDetailRow(Icons.straighten, 'Height:', _profile?.profileDetails.height ?? "N/A", const Color(0xFF81D4FA)), // Cyan
            _buildDetailRow(Icons.cake, 'Age:', _profile?.profileDetails.age ?? "N/A", const Color(0xFFA1887F)), // Brown
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(profile: _profile!),
              ),
            ).then((value) {
              if (value == true) {
                _loadProfile();
              }
            });
          },
          child: const Text("Edit Profile"),
        ),
      ),
    );
  }
}*/
