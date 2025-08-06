

import 'dart:io';

import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/screens/login_screen.dart';
import 'package:Webdoc/screens/profile_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:Webdoc/screens/subscription_screen.dart';
import 'package:Webdoc/screens/wallet_history_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome
import '../models/wallet_balance_response.dart'; // Create this model
import '../services/api_service.dart'; // Make sure this has the new API call
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool rememberMe = false;
  String _walletBalance = '';
  bool _isLoadingBalance = true;
  String _deviceModel = '';
  bool _isLoadingDeviceInfo = true;
  @override
  void initState() {
    super.initState();
   // _loadDeviceInfo();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final apiService = ApiService();
    final walletBalanceResponse = await apiService.getWalletBalance(context, patientId); // Replace patient id

    if (walletBalanceResponse != null) {
      setState(() {
        _walletBalance = walletBalanceResponse.payLoad.balance;
      });
    } else {
      // Handle the error as you see fit, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallet balance')));
      _walletBalance = '0'; // Display "Error" or a default value
    }
    setState(() {
      _isLoadingBalance = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16)),
            Text(
                'Settings',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold)
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
                icon: Icons.account_balance_wallet,
                text: "Wallet History",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletHistoryScreen(
                        patientId: SharedPreferencesManager.getString("id") ?? "0",
                      ),
                    ),
                  );
                },
              ),
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
             /* _buildListTile(
                context: context,
                icon: Icons.phone_android,
                text: "Device Info",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_deviceModel)));
                },
              ),*/
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

    return GestureDetector(
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
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Expanded( // Use Expanded to take up remaining space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppStyles.bodyLarge(context).copyWith(
                            color: AppColors.primaryTextColor, fontWeight: FontWeight.bold
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
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.cardColor, size: 16), // Forward icon
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardColor, width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.wallet, color: AppColors.cardColor, size: 16),
                      const SizedBox(width: 4),
                      _isLoadingBalance
                          ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2,color: AppColors.primaryColor,))
                          : Text(
                        "PKR/- $_walletBalance",
                        style: AppStyles.bodyMedium(context).copyWith(
                          color: AppColors.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
 /* Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = '"Manufacturer: "${androidInfo.manufacturer}\n"Model: "${androidInfo.model}\n"Name: "${androidInfo.name}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = '"Model Name: "${iosInfo.modelName}\n"Model: "${iosInfo.physicalRamSize}\n"Name: "${iosInfo.name}';
      }
    } catch (e) {
      _deviceModel = 'Unknown';
    }


    setState(() {
      _isLoadingDeviceInfo = false;
    });
  }*/

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


