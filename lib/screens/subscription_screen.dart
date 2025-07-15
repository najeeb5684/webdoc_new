
import 'package:Webdoc/screens/package_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html_unescape/html_unescape.dart';
import '../models/user_package_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  UserPackageResponse? _userPackage;
  bool _isLoading = true;
  String? userId;
  final ApiService _apiService = ApiService(); // Instance of ApiService

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    userId = SharedPreferencesManager.getString('id');

    if (userId != null) {
      _userPackage =
      await _apiService.fetchUserPackage(context: context, userId: userId!);
    } else {
      print('User ID not found.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User ID not found.')));
    }
    setState(() {
      _isLoading = false;
    });
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
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.black, size: 16)),
            Text('Subscription',
                style: AppStyles.bodyLarge(context)
                    .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ))
          : _userPackage == null ||
          _userPackage?.payLoad == null ||
          _userPackage?.payLoad?.id == null
          ? _buildNoSubscriptionView() // Show "No Subscription Activated"
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackageCard(),
            const SizedBox(height: 10),
            _buildUsageDetailsCard(),
            const SizedBox(height: 10),
            _buildAddOnFeaturesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2), width: 1.5), // Add border
      ),
      color: AppColors.primaryColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership,
                    color: AppColors.primaryColor, size: 30),
                const SizedBox(width: 10),
                Text('Package',
                    style: AppStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor)),
              ],
            ),
            Divider(color: AppColors.primaryColor.withOpacity(0.4)),
            _buildDetailRow('Package Name',
                _userPackage?.payLoad?.packageName?.description ?? 'N/A', Icons.star),
            _buildDetailRow(
                'Status', _userPackage?.payLoad?.status ?? 'N/A', Icons.info),
            _buildDetailRow(
                'Active Date',
                _userPackage?.payLoad?.activeDate != null
                    ? DateFormat('yyyy-MM-dd hh:mm a').format(
                    DateFormat('yyyy-MM-dd hh:mm:ss.SSS')
                        .parse(_userPackage!.payLoad!.activeDate!))
                    : 'N/A',
                Icons.calendar_today),
            _buildDetailRow(
                'Expiry Date',
                _userPackage?.payLoad?.expiryDate != null
                    ? DateFormat('yyyy-MM-dd hh:mm a').format(
                    DateFormat('yyyy-MM-dd hh:mm:ss.SSS')
                        .parse(_userPackage!.payLoad!.expiryDate!))
                    : 'N/A',
                Icons.event),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2), width: 1.5), // Add border
      ),
      color: AppColors.primaryColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: AppColors.primaryColor, size: 30),
                const SizedBox(width: 10),
                Text('Usage',
                    style: AppStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor)),
              ],
            ),
            Divider(color: AppColors.primaryColor.withOpacity(0.4)),
            _buildDetailRow('Total Voice Calls',
                _userPackage?.payLoad?.voiceCalls?.toString() ?? 'N/A', Icons.voice_chat),
            _buildDetailRow('Total Video Calls',
                _userPackage?.payLoad?.videoCalls?.toString() ?? 'N/A', Icons.videocam),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnFeaturesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2), width: 1.5), // Add border
      ),
      color: AppColors.primaryColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: AppColors.primaryColor, size: 30),
                const SizedBox(width: 10),
                Text('Add-on Features',
                    style: AppStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor)),
              ],
            ),
            Divider(color: AppColors.primaryColor.withOpacity(0.4)),
            Html(
              data: HtmlUnescape().convert(_userPackage?.payLoad?.packageName
                  ?.addonfeatures ??
                  '<p>No features available.</p>'),
              style: {
                "body": Style(
                  fontFamily: AppStyles.fontFamily,
                  fontSize: FontSize(14.0),
                  color: AppColors.primaryTextColor,
                ),
                "ul": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.only(left: 10.0),
                ),
                "li": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                )
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column( // Changed Row to Column
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondaryTextColor, size: 20),
              const SizedBox(width: 10),
              Text(title + ': ',
                  style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Padding( // Add padding for the value
            padding: const EdgeInsets.only(left: 30.0), // Indent to align with title text
            child: Text(
              value,
              style: AppStyles.bodyMedium(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.exclamationTriangle,
                size: 60, color: AppColors.secondaryTextColor),
            SizedBox(height: 20),
            Text(
              'No Subscription Activated',
              style: AppStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.primaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Activate a package to start enjoying premium features.',
              style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PackageScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('View Packages', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/*



import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html_unescape/html_unescape.dart';
import '../models/user_package_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  UserPackageResponse? _userPackage;
  bool _isLoading = true;
  String? userId;
  final ApiService _apiService = ApiService(); // Instance of ApiService

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    userId = SharedPreferencesManager.getString('id');

    if (userId != null) {
      _userPackage =
      await _apiService.fetchUserPackage(context: context, userId: userId!);
    } else {
      print('User ID not found.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User ID not found.')));
    }
    setState(() {
      _isLoading = false;
    });
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
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.black, size: 16)),
            Text('Subscription',
                style: AppStyles.bodyLarge
                    .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ))
          : _userPackage == null || _userPackage?.payLoad == null || _userPackage?.payLoad?.id == null
          ? _buildNoSubscriptionView() // Show "No Subscription Activated"
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackageCard(),
            const SizedBox(height: 10),
            _buildUsageDetailsCard(),
            const SizedBox(height: 10),
            _buildAddOnFeaturesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side:  BorderSide(color: AppColors.primaryColor.withOpacity(0.2), width: 1.5), // Add border
      ),
      color: AppColors.primaryColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: AppColors.primaryColor, size: 30),
                const SizedBox(width: 10),
                Text('Package', style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryTextColor)),
              ],
            ),
             Divider(color: AppColors.primaryColor.withOpacity(0.4)),
            _buildDetailRow('Package Name', _userPackage?.payLoad?.packageName?.description ?? 'N/A', Icons.star),
            _buildDetailRow('Status', _userPackage?.payLoad?.status ?? 'N/A', Icons.info),
            _buildDetailRow('Active Date', _userPackage?.payLoad?.activeDate != null
                ? DateFormat('yyyy-MM-dd hh:mm a').format(
                DateFormat('yyyy-MM-dd hh:mm:ss.SSS')
                    .parse(_userPackage!.payLoad!.activeDate!))
                : 'N/A', Icons.calendar_today),
            _buildDetailRow('Expiry Date', _userPackage?.payLoad?.expiryDate != null
                ? DateFormat('yyyy-MM-dd hh:mm a').format(
                DateFormat('yyyy-MM-dd hh:mm:ss.SSS')
                    .parse(_userPackage!.payLoad!.expiryDate!))
                : 'N/A', Icons.event),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side:  BorderSide(color: AppColors.primaryColor.withOpacity(0.2), width: 1.5), // Add border
      ),
      color: AppColors.primaryColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: AppColors.primaryColor, size: 30),
                const SizedBox(width: 10),
                Text('Usage', style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryTextColor)),
              ],
            ),
             Divider(color: AppColors.primaryColor.withOpacity(0.4)),
            _buildDetailRow('Total Voice Calls', _userPackage?.payLoad?.voiceCalls?.toString() ?? 'N/A', Icons.voice_chat),
            _buildDetailRow('Total Video Calls', _userPackage?.payLoad?.videoCalls?.toString() ?? 'N/A', Icons.videocam),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnFeaturesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side:  BorderSide(color: AppColors.primaryColor.withOpacity(0.2), width: 1.5), // Add border
      ),
      color: AppColors.primaryColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: AppColors.primaryColor, size: 30),
                const SizedBox(width: 10),
                Text('Add-on Features', style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryTextColor)),
              ],
            ),
             Divider(color: AppColors.primaryColor.withOpacity(0.4)),
            Html(
              data: HtmlUnescape().convert(_userPackage?.payLoad?.packageName?.addonfeatures ??
                  '<p>No features available.</p>'),
              style: {
                "body": Style(
                  fontFamily: AppStyles.fontFamily,
                  fontSize: FontSize(14.0),
                  color: AppColors.primaryTextColor,
                ),
                "ul": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.only(left: 10.0),
                ),
                "li": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                )
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryTextColor, size: 20),
          const SizedBox(width: 10),
          Text(title + ': ', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: AppStyles.bodyMedium),
        ],
      ),
    );
  }
  Widget _buildNoSubscriptionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.exclamationTriangle,
                size: 60, color: AppColors.secondaryTextColor),
            SizedBox(height: 20),
            Text(
              'No Subscription Activated',
              style: AppStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.primaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Activate a package to start enjoying premium features.',
              style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to the package screen (replace with your actual route)
                Navigator.pushNamed(context, '/package_screen'); // Adjust route name
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('View Packages', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}


*/
