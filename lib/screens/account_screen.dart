


import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/screens/login_screen.dart';

import 'package:Webdoc/screens/profile_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:Webdoc/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

import '../utils/shared_preferences.dart';
import '../utils/global.dart';


class AccountScreen extends StatelessWidget {
  bool rememberMe = false;
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  /*Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );*/
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Settings',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 16),
              _buildListTile(
                context: context,
                icon: Icons.subscriptions,
                text: "Subscription",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SubscriptionScreen()),
                  );
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.description,
                text: "Terms and Conditions",
                onTap: () {
                  Global.privacyTermsUrl = "terms";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.privacy_tip,
                text: "Privacy Policy",
                onTap: () {
                  Global.privacyTermsUrl = "privacy";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
             /* _buildListTile(
                context: context,
                icon: Icons.cancel_presentation,
                text: "Appointment cancel rules",
                onTap: () {
                  print("Appointment cancel rules tapped");
                },
              ),*/
              _buildListTile(
                context: context,
                icon: Icons.question_answer,
                text: "FAQ's",
                onTap: () {
                  Global.privacyTermsUrl = "faqs";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),

              _buildListTile(
                context: context,
                icon: Icons.delete,
                text: "Delete Account",
                onTap: () {
                  Global.privacyTermsUrl = "delete";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.logout,
                text: "Logout",
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    String userName = SharedPreferencesManager.getString("name") ?? "User Name";
    String userMobile =
        SharedPreferencesManager.getString("mobileNumber") ?? "Mobile Number";

    return GestureDetector(  // Wrap with GestureDetector
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.primaryColorLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [  // Add subtle shadow
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.5),  // Very light black
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),  // Slightly downward
              ),
            ]
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardColor,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.cardColor,
                child: Text(
                  _getInitials(userName), // Display initials
                  style: TextStyle(
                      fontSize: 20,
                      color: AppColors.backgroundColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: AppStyles.bodyLarge(context).copyWith(
                      color: AppColors.primaryTextColor,fontWeight: FontWeight.bold
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "View Profile",
                    style: AppStyles.bodySmall(context).copyWith(
                      color: AppColors.cardColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.cardColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.cardColor),
        title: Text(
          text,
          style: AppStyles.bodyMedium(context).copyWith(
            color: AppColors.primaryTextColor,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.cardColor, size: 16),
        onTap: onTap,
      ),
    );
  }



  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.primaryColorLight,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout,
                  size: 50,
                  color: AppColors.primaryColor,
                ),
                SizedBox(height: 16),
                Text(
                  "Logout Confirmation",
                  style: AppStyles.titleMedium(context).copyWith(color: AppColors.primaryColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Are you sure you want to logout?",
                  style: AppStyles.bodyMedium(context).copyWith(color: AppColors.primaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryTextColor,
                        textStyle: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        // Clear preferences and remove all routes
                        Future.microtask(() async {
                          await SharedPreferencesManager.remove('mobileNumber');
                          await SharedPreferencesManager.remove('pin');
                          await SharedPreferencesManager.remove('isPackageActivated');
                          await SharedPreferencesManager.remove('id');
                          await SharedPreferencesManager.remove('name');
                          await SharedPreferencesManager.remove('packageName');
                          await SharedPreferencesManager.remove('upcomingAppointmentCount');

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                                (Route<dynamic> route) => false,
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}




/*import 'package:Webdoc/screens/login_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart';


class AccountScreen extends StatelessWidget {
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 16),
              _buildListTile(
                context: context,
                icon: Icons.subscriptions,
                text: "Subscription",
                onTap: () {
                  print("Subscription tapped");
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.description,
                text: "Terms and Conditions",
                onTap: () {
                  Global.privacyTermsUrl = "terms";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.report,
                text: "Complaints",
                onTap: () {
                  print("Complaints tapped");
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.cancel_presentation,
                text: "Appointment cancel rules",
                onTap: () {
                  print("Appointment cancel rules tapped");
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.question_answer,
                text: "FAQ's",
                onTap: () {
                  print("FAQ's tapped");
                },
              ),
              _buildListTile(
                context: context,
                icon: Icons.logout,
                text: "Logout",
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    String userName = SharedPreferencesManager.getString("name") ?? "User Name";
    String userMobile =
        SharedPreferencesManager.getString("mobileNumber") ?? "Mobile Number";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cardColor,
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                  "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dXNlciUyMHByb2ZpbGV8ZW58MHx8MHx8MA=="),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppStyles.titleMedium.copyWith(
                    color: AppColors.primaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "View Profile",
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.cardColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.cardColor, size: 18),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.cardColor),
        title: Text(
          text,
          style: AppStyles.bodyLarge.copyWith(
            color: AppColors.primaryTextColor,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.cardColor, size: 18),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () async {
                Navigator.of(context).pop();

                await SharedPreferencesManager.remove('mobileNumber');
                await SharedPreferencesManager.remove('pin');
                await SharedPreferencesManager.remove('isPackageActivated');
                await SharedPreferencesManager.remove('id');
                await SharedPreferencesManager.remove('name');
                await SharedPreferencesManager.remove('packageName');

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}*/



/*import 'package:Webdoc/screens/login_screen.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:Webdoc/screens/profile_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_list_item.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart'; // Ensure you have this for global variables
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts


class AccountScreen extends StatelessWidget {
  bool rememberMe = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView( // Wrap the entire content in SingleChildScrollView
          child: Column(
            children: [
              _buildProfileHeader(context), // Use the new profile header
              CustomListItem(
                icon: Icons.phone,
                text: SharedPreferencesManager.getString("mobileNumber") ??
                    "Phone Number",
                onTap: () {
                  print("Phone number tapped");
                },
              ),
              CustomListItem(
                icon: Icons.history,
                text: "Appointment History",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PastAppointmentsScreen()),
                  );
                },
              ),
              CustomListItem(
                icon: Icons.description,
                text: "Terms & Conditions",
                onTap: () {
                  Global.privacyTermsUrl = "terms";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
              CustomListItem(
                icon: Icons.privacy_tip,
                text: "Privacy Policy",
                onTap: () {
                  Global.privacyTermsUrl = "privacy";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
              CustomListItem(
                icon: Icons.delete_forever,
                text: "Delete Account",
                onTap: () {
                  Global.privacyTermsUrl = "delete";
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyTermsScreen()),
                  );
                },
              ),
              CustomListItem(
                icon: Icons.logout,
                text: "Logout",
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 20), // Add some space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // New Profile Header Widget
  Widget _buildProfileHeader(BuildContext context) {
    String userName = SharedPreferencesManager.getString("name") ?? "User Name";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: const Text("View Profile"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () async {
                Navigator.of(context).pop();

                await SharedPreferencesManager.remove('mobileNumber');
                await SharedPreferencesManager.remove('pin');
                await SharedPreferencesManager.remove('isPackageActivated');
                await SharedPreferencesManager.remove('id');
                await SharedPreferencesManager.remove('name');
                await SharedPreferencesManager.remove('packageName');
              //  await SharedPreferencesManager.clear();
              *//*  if(rememberMe){
                  await SharedPreferencesManager.getString('countryCode') ?? "country code";
                  await SharedPreferencesManager.getString('phoneNumber')?? "number";
                  await SharedPreferencesManager.getString('pin')?? "pin";
                  await SharedPreferencesManager.getBool('rememberMe')?? true;
                }*//*

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}*/



