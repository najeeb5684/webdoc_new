

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:Webdoc/screens/payment_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import 'dashboard_screen.dart';

class PackageScreen extends StatelessWidget {
  const PackageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phoneNumber = SharedPreferencesManager.getString('mobileNumber');
    final isPakistanNumber = phoneNumber != null &&
        (phoneNumber.startsWith('03') || phoneNumber.startsWith('+92'));

    int oneTimePackageId = isPakistanNumber ? 1123 : 1126;
    String oneTimePackagePrice = isPakistanNumber ? "300" : "10";
    String oneTimeOriginalPrice = isPakistanNumber ? "1500" : "50";
    String oneTimeDiscount = isPakistanNumber ? "80%" : "80%";

    int monthlyPackageId = isPakistanNumber ? 1124 : 1125;
    String monthlyPackagePrice = isPakistanNumber ? "999" : "14";
    String monthlyOriginalPrice = isPakistanNumber ? "4000" : "56";
    String monthlyDiscount = isPakistanNumber ? "75%" : "75%";

    String currencySymbol = isPakistanNumber ? 'Rs. ' : '\$';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 16),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => DashboardScreen()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        title: Text(
          "Packages",
          style: AppStyles.bodyLarge(context)
              .copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Packages',
              style: AppStyles.titleLarge(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the care that fits you best whether you need a one-time consultation or ongoing support with our monthly packages, our doctors are just a tap away.\nAvailable Monday to Saturday\n9:00 AM – 9:00 PM (PKT)',
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: AppColors.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/package_icon.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            PackageOption(
              title: 'One Time Instant Doctor',
              price: '$currencySymbol$oneTimePackagePrice',
              originalPrice: '$currencySymbol$oneTimeOriginalPrice',
              discountTag: oneTimeDiscount,
              details: const [
                'FREE Health insurance up to Rs. 50,000 Terms and Conditions Apply',
                'Video Call to Doctor Anytime',
                'Instant Prescription via SMS and App',
                'One-time Payment',
              ],
              packageId: oneTimePackageId,
              packagePrice: oneTimePackagePrice,
              packageName: "One Time Instant Doctors",
              showTermsAndConditions: true,
              currencySymbol: currencySymbol,
              showFreeHealthInsuranceTag: true,
              showRecommendedTag: false, // Important: Ensure this is false for the One-Time package
            ),
            const SizedBox(height: 16),
            PackageOption(
              title: 'Monthly',
              price: '$currencySymbol$monthlyPackagePrice',
              originalPrice: '$currencySymbol$monthlyOriginalPrice',
              discountTag: monthlyDiscount,
              details: const [
                'Video Call to Doctor Anytime',
                'Maintains Full Medical History',
                'Instant Prescription via SMS and App',
                'Monthly Subscription',
                'Unlimited Video Calls',
              ],
              packageId: monthlyPackageId,
              packagePrice: monthlyPackagePrice,
              packageName: "Monthly Premium",
              showTermsAndConditions: false,
              currencySymbol: currencySymbol,
              showFreeHealthInsuranceTag: false,
              showRecommendedTag: true, //  Enable the "Recommended" tag here
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class PackageOption extends StatefulWidget {
  final String title;
  final String price;
  final String originalPrice;
  final String discountTag;
  final List<String> details;
  final int packageId;
  final String packageName;
  final String packagePrice;
  final bool showTermsAndConditions;
  final String currencySymbol;
  final bool showFreeHealthInsuranceTag;
  final bool showRecommendedTag; // Add this line for the "Recommended" tag.

  const PackageOption({
    Key? key,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.discountTag,
    required this.details,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
    this.showTermsAndConditions = false,
    required this.currencySymbol,
    this.showFreeHealthInsuranceTag = false,
    this.showRecommendedTag = false,  // Initialize to false
  }) : super(key: key);

  @override
  _PackageOptionState createState() => _PackageOptionState();
}

class _PackageOptionState extends State<PackageOption> {
  bool _expanded = false;
  List<String> _visibleDetails = [];

  @override
  void initState() {
    super.initState();
    _visibleDetails = widget.details.sublist(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryColorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Price Row with Strikethrough
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppStyles.bodyLarge(context).copyWith(
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.originalPrice,
                        style: AppStyles.bodySmall(context).copyWith(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        widget.price,
                        style: AppStyles.bodyLarge(context).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._visibleDetails.map((detail) {
                Widget detailWidget;

                if (widget.showTermsAndConditions &&
                    detail.contains('Terms and Conditions Apply')) {
                  detailWidget = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: RichText(
                            textAlign: TextAlign.justify,
                            text: TextSpan(
                              style: AppStyles.bodySmall(context)
                                  .copyWith(color: AppColors.secondaryTextColor),
                              children: [
                                TextSpan(
                                  text: detail.substring(
                                      0,
                                      detail.indexOf(
                                          'Terms and Conditions Apply'))
                                      .replaceFirst('Rs. ', widget.currencySymbol),
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions Apply',
                                  style: AppStyles.bodySmall(context).copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Global.privacyTermsUrl = "package";
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PrivacyPolicyTermsScreen()),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  detailWidget = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail,
                            textAlign: TextAlign.justify,
                            style: AppStyles.bodySmall(context)
                                .copyWith(color: AppColors.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return detailWidget;
              }),
              if (widget.details.length > 2)
                InkWell(
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                      _visibleDetails = _expanded
                          ? widget.details
                          : widget.details.sublist(0, 2);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _expanded ? 'Show Less' : 'Read More',
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (SharedPreferencesManager.getBool('isPackageActivated') ??
                        false) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                          Text('You are already subscribed to a package!')));
                      return;
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            packageId: widget.packageId,
                            packageName: widget.packageName,
                            packagePrice: widget.packagePrice,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding:  EdgeInsets.symmetric(
                        horizontal: 20, vertical: 5),
                    textStyle: TextStyle(fontSize: AppStyles.bodyMedium(context).fontSize,fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Subscribe'),
                ),
              ),
            ],
          ),
        ),

        // "Free Health Insurance" Tag - Conditionally Displayed
        if (widget.showFreeHealthInsuranceTag)
          Positioned(
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.blue, // Or any color you prefer
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Free Health Insurance',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        // "Recommended" Tag - Conditionally Displayed
        if (widget.showRecommendedTag)
          Positioned(
            left: 0, // Adjust position as needed
            top: 0,   // Adjust position as needed (e.g., below "Free Health Insurance")
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.black, // Or any color you prefer for "Recommended"
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Recommended',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        // Discount Tag
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
            ),
            child: Text(
              '${widget.discountTag} OFF',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}




/*import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:Webdoc/screens/payment_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';

class PackageScreen extends StatelessWidget {
  const PackageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phoneNumber = SharedPreferencesManager.getString('mobileNumber');
    final isPakistanNumber = phoneNumber != null &&
        (phoneNumber.startsWith('0') || phoneNumber.startsWith('+92'));

    int oneTimePackageId = isPakistanNumber ? 1123 : 1126;
    String oneTimePackagePrice = isPakistanNumber ? "300" : "10";
    String oneTimeOriginalPrice = isPakistanNumber ? "1500" : "50";
    String oneTimeDiscount = isPakistanNumber ? "80%" : "80%";

    int monthlyPackageId = isPakistanNumber ? 1124 : 1125;
    String monthlyPackagePrice = isPakistanNumber ? "999" : "14";
    String monthlyOriginalPrice = isPakistanNumber ? "4000" : "56";
    String monthlyDiscount = isPakistanNumber ? "75%" : "75%";

    String currencySymbol = isPakistanNumber ? 'Rs. ' : '\$';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 16),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Packages",
          style: AppStyles.bodyLarge(context)
              .copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Get Premium',
              style: AppStyles.titleLarge(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock premium access to expert digital consultations and elevate your healthcare experience like never before—smarter, faster, and right at your',
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: AppColors.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/package_icon.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            PackageOption(
              title: 'One Time Instant Doctor',
              price: '$currencySymbol$oneTimePackagePrice',
              originalPrice: '$currencySymbol$oneTimeOriginalPrice',
              discountTag: oneTimeDiscount,
              details: const [
                'FREE Health insurance up to Rs. 50,000 Terms and Conditions Apply',
                'Audio/Video Call to Doctor',
                'Instant Prescription via SMS and App',
                'One-time Payment',
              ],
              packageId: oneTimePackageId,
              packagePrice: oneTimePackagePrice,
              packageName: "One Time Instant Doctors",
              showTermsAndConditions: true,
              currencySymbol: currencySymbol,
              showFreeHealthInsuranceTag: true, // Add this line
            ),
            const SizedBox(height: 16),
            PackageOption(
              title: 'Monthly',
              price: '$currencySymbol$monthlyPackagePrice',
              originalPrice: '$currencySymbol$monthlyOriginalPrice',
              discountTag: monthlyDiscount,
              details: const [
                'Video Call to Doctor Anytime',
                'Maintains Full Medical History',
                'Instant Prescription via SMS and App',
                'Monthly Subscription',
                'Unlimited Video Calls',
              ],
              packageId: monthlyPackageId,
              packagePrice: monthlyPackagePrice,
              packageName: "Monthly Premium",
              showTermsAndConditions: false,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class PackageOption extends StatefulWidget {
  final String title;
  final String price;
  final String originalPrice;
  final String discountTag;
  final List<String> details;
  final int packageId;
  final String packageName;
  final String packagePrice;
  final bool showTermsAndConditions;
  final String currencySymbol;
  final bool showFreeHealthInsuranceTag; // Add this line

  const PackageOption({
    Key? key,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.discountTag,
    required this.details,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
    this.showTermsAndConditions = false,
    required this.currencySymbol,
    this.showFreeHealthInsuranceTag = false, // Initialize to false
  }) : super(key: key);

  @override
  _PackageOptionState createState() => _PackageOptionState();
}

class _PackageOptionState extends State<PackageOption> {
  bool _expanded = false;
  List<String> _visibleDetails = [];

  @override
  void initState() {
    super.initState();
    _visibleDetails = widget.details.sublist(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryColorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Price Row with Strikethrough
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppStyles.bodyLarge(context).copyWith(
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.originalPrice,
                        style: AppStyles.bodySmall(context).copyWith(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        widget.price,
                        style: AppStyles.bodyLarge(context).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._visibleDetails.map((detail) {
                Widget detailWidget;

                if (widget.showTermsAndConditions &&
                    detail.contains('Terms and Conditions Apply')) {
                  detailWidget = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: RichText(
                            textAlign: TextAlign.justify,
                            text: TextSpan(
                              style: AppStyles.bodySmall(context)
                                  .copyWith(color: AppColors.secondaryTextColor),
                              children: [
                                TextSpan(
                                  text: detail.substring(
                                      0,
                                      detail.indexOf(
                                          'Terms and Conditions Apply'))
                                      .replaceFirst('Rs. ', widget.currencySymbol),
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions Apply',
                                  style: AppStyles.bodySmall(context).copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Global.privacyTermsUrl = "package";
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PrivacyPolicyTermsScreen()),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  detailWidget = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail,
                            textAlign: TextAlign.justify,
                            style: AppStyles.bodySmall(context)
                                .copyWith(color: AppColors.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return detailWidget;
              }),
              if (widget.details.length > 2)
                InkWell(
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                      _visibleDetails = _expanded
                          ? widget.details
                          : widget.details.sublist(0, 2);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _expanded ? 'Show Less' : 'Read More',
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (SharedPreferencesManager.getBool('isPackageActivated') ??
                        false) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                          Text('You are already subscribed to a package!')));
                      return;
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            packageId: widget.packageId,
                            packageName: widget.packageName,
                            packagePrice: widget.packagePrice,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Subscribe'),
                ),
              ),
            ],
          ),
        ),

        // "Free Health Insurance" Tag - Conditionally Displayed
        if (widget.showFreeHealthInsuranceTag)
          Positioned(
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.blue, // Or any color you prefer
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Free Health Insurance',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        // Discount Tag
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
            ),
            child: Text(
              '${widget.discountTag} OFF',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}*/





/*
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:Webdoc/screens/payment_screen.dart';
import 'package:Webdoc/screens/privacy_policy_terms_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';

class PackageScreen extends StatelessWidget {
  const PackageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phoneNumber = SharedPreferencesManager.getString('mobileNumber');
    final isPakistanNumber = phoneNumber != null &&
        (phoneNumber.startsWith('0') || phoneNumber.startsWith('+92'));

    int oneTimePackageId = isPakistanNumber ? 1123 : 1126;
    String oneTimePackagePrice = isPakistanNumber ? "300" : "10";
    String oneTimeOriginalPrice = isPakistanNumber ? "1500" : "50";
    String oneTimeDiscount = isPakistanNumber ? "80%" : "80%";

    int monthlyPackageId = isPakistanNumber ? 1124 : 1125;
    String monthlyPackagePrice = isPakistanNumber ? "999" : "14";
    String monthlyOriginalPrice = isPakistanNumber ? "4000" : "56";
    String monthlyDiscount = isPakistanNumber ? "75%" : "75%";

    String currencySymbol = isPakistanNumber ? 'Rs. ' : '\$';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 16),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Packages",
          style: AppStyles.bodyLarge(context)
              .copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Get Premium',
              style: AppStyles.titleLarge(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock premium access to expert digital consultations and elevate your healthcare experience like never before—smarter, faster, and right at your',
              style: AppStyles.bodyMedium(context)
                  .copyWith(color: AppColors.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/package_icon.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            PackageOption(
              title: 'One Time Instant Doctor',
              price: '$currencySymbol$oneTimePackagePrice',
              originalPrice: '$currencySymbol$oneTimeOriginalPrice',
              discountTag: oneTimeDiscount,
              details: const [
                'FREE Health insurance up to Rs. 50,000 Terms and Conditions Apply',
                'Audio/Video Call to Doctor',
                'Instant Prescription via SMS and App',
                'One-time Payment',
              ],
              packageId: oneTimePackageId,
              packagePrice: oneTimePackagePrice,
              packageName: "One Time Instant Doctors",
              showTermsAndConditions: true,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: 16),
            PackageOption(
              title: 'Monthly',
              price: '$currencySymbol$monthlyPackagePrice',
              originalPrice: '$currencySymbol$monthlyOriginalPrice',
              discountTag: monthlyDiscount,
              details: const [
                'Video Call to Doctor Anytime',
                'Maintains Full Medical History',
                'Instant Prescription via SMS and App',
                'Monthly Subscription',
                'Unlimited Video Calls',
              ],
              packageId: monthlyPackageId,
              packagePrice: monthlyPackagePrice,
              packageName: "Monthly Premium",
              showTermsAndConditions: false,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class PackageOption extends StatefulWidget {
  final String title;
  final String price;
  final String originalPrice;
  final String discountTag;
  final List<String> details;
  final int packageId;
  final String packageName;
  final String packagePrice;
  final bool showTermsAndConditions;
  final String currencySymbol;

  const PackageOption({
    Key? key,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.discountTag,
    required this.details,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
    this.showTermsAndConditions = false,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _PackageOptionState createState() => _PackageOptionState();
}

class _PackageOptionState extends State<PackageOption> {
  bool _expanded = false;
  List<String> _visibleDetails = [];

  @override
  void initState() {
    super.initState();
    _visibleDetails = widget.details.sublist(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryColorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Price Row with Strikethrough
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppStyles.bodyLarge(context).copyWith(
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.originalPrice,
                        style: AppStyles.bodySmall(context).copyWith(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        widget.price,
                        style: AppStyles.bodyLarge(context).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._visibleDetails.map((detail) {
                Widget detailWidget;

                if (widget.showTermsAndConditions &&
                    detail.contains('Terms and Conditions Apply')) {
                  detailWidget = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: RichText(
                            textAlign: TextAlign.justify,
                            text: TextSpan(
                              style: AppStyles.bodySmall(context)
                                  .copyWith(color: AppColors.secondaryTextColor),
                              children: [
                                TextSpan(
                                  text: detail.substring(
                                      0,
                                      detail.indexOf(
                                          'Terms and Conditions Apply'))
                                      .replaceFirst('Rs. ', widget.currencySymbol),
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions Apply',
                                  style: AppStyles.bodySmall(context).copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Global.privacyTermsUrl = "package";
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PrivacyPolicyTermsScreen()),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  detailWidget = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail,
                            textAlign: TextAlign.justify,
                            style: AppStyles.bodySmall(context)
                                .copyWith(color: AppColors.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return detailWidget;
              }),
              if (widget.details.length > 2)
                InkWell(
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                      _visibleDetails = _expanded
                          ? widget.details
                          : widget.details.sublist(0, 2);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _expanded ? 'Show Less' : 'Read More',
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (SharedPreferencesManager.getBool('isPackageActivated') ??
                        false) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                          Text('You are already subscribed to a package!')));
                      return;
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            packageId: widget.packageId,
                            packageName: widget.packageName,
                            packagePrice: widget.packagePrice,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Subscribe'),
                ),
              ),
            ],
          ),
        ),
        // Discount Tag
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
            ),
            child: Text(
              '${widget.discountTag} OFF',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
*/





