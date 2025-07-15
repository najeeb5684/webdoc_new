
// lib/screens/payment_screen.dart

import 'package:Webdoc/screens/easypaisa_payment_screen.dart';
import 'package:Webdoc/screens/stripe_payment_screen.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'generic_payment_gateway_screen.dart';
import 'jazzcash_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int? packageId;
  final String? packageName;
  final String? packagePrice;
  final String? doctorId;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? slotNumber;
  final String? fees;

  const PaymentScreen({
    Key? key,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.doctorId,
    this.appointmentDate,
    this.appointmentTime,
    this.slotNumber,
    this.fees,
  }) : super(key: key);

  const PaymentScreen.appointment({
    Key? key,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.slotNumber,
    required this.fees,
  })  : packageId = null,
        packageName = null,
        packagePrice = null,
        super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    const double imageAssetHeight = 30.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 16),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Payments",
          style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 0,
          bottom: 10 + MediaQuery.of(context).padding.bottom, // Add bottom padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            Text(
              'Select Method',
              style: AppStyles.titleMedium(context).copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            /*_buildPaymentOption(
              title: 'Debit Card',
              value: 'debit',
              image: 'assets/images/alfalah.png',
              height: imageAssetHeight,
              onTap: () {
                setState(() {
                  _selectedMethod = 'debit';
                });
              },
            ),
            const SizedBox(height: 10),
            _buildPaymentOption(
              title: 'Bank Alfalah Account',
              value: 'credit',
              image: 'assets/images/alfalah.png',
              height: imageAssetHeight,
              onTap: () {
                setState(() {
                  _selectedMethod = 'credit';
                });
              },
            ),*/
            //const SizedBox(height: 10),
            _buildPaymentOption(
              title: 'Debit/Credit Card',
              value: 'stripe',
              image: 'assets/images/stripe.png',
              height: imageAssetHeight,
              onTap: () {
                setState(() {
                  _selectedMethod = 'stripe';
                });
              },
            ),
            /*const SizedBox(height: 10),
            _buildPaymentOption(
              title: 'JazzCash',
              value: 'jazzcash',
              image: 'assets/images/jazzcash.png',
              height: imageAssetHeight,
              onTap: () {
                setState(() {
                  _selectedMethod = 'jazzcash';
                });
              },
            ),*/
            const SizedBox(height: 10),
            if (widget.packagePrice != "10" && widget.packagePrice != "14")
              _buildPaymentOption(
                title: 'easypaisa',
                value: 'easypaisa',
                image: 'assets/images/easypaisa.png',
                height: imageAssetHeight,
                onTap: () {
                  setState(() {
                    _selectedMethod = 'easypaisa';
                  });
                },
              ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMethod == null
                    ? null
                    : () {
                  if (_selectedMethod == 'debit' || _selectedMethod == 'credit') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenericPaymentGatewayScreen(
                          packageId: widget.packageId ?? 0,
                          packageName: widget.packageName ?? "",
                          packagePrice: widget.packagePrice ?? "0",
                          bankName: _selectedMethod == 'debit' ? 'Credit/Debit' : 'Bank Alfalah Account',
                          paymentUrl: _selectedMethod == 'debit' ? 'alfalahDc' : 'alfalahAc',
                        ),
                      ),
                    );
                  } else if (_selectedMethod == 'jazzcash') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JazzCashScreen(
                          packageId: widget.packageId ?? 0,
                          packageName: widget.packageName ?? "",
                          packagePrice: widget.packagePrice ?? "0",
                          doctorId: widget.doctorId,
                          appointmentDate: widget.appointmentDate,
                          appointmentTime: widget.appointmentTime,
                          slotNumber: widget.slotNumber,
                          fees: widget.fees,
                        ),
                      ),
                    );
                  } else if (_selectedMethod == 'easypaisa') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EasyPaisaScreen(
                          packageId: widget.packageId ?? 0,
                          packageName: widget.packageName ?? "",
                          packagePrice: widget.packagePrice ?? "0",
                          doctorId: widget.doctorId,
                          appointmentDate: widget.appointmentDate,
                          appointmentTime: widget.appointmentTime,
                          slotNumber: widget.slotNumber,
                          fees: widget.fees,
                        ),
                      ),
                    );
                  }
                  else if (_selectedMethod == 'stripe') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StripePaymentScreen(
                          packageId: widget.packageId ?? 0,
                          packageName: widget.packageName ?? "",
                          packagePrice: widget.packagePrice ?? "0",
                          doctorId: widget.doctorId,
                          appointmentDate: widget.appointmentDate,
                          appointmentTime: widget.appointmentTime,
                          slotNumber: widget.slotNumber,
                          fees: widget.fees,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Next', style: AppStyles.bodyLarge(context).copyWith(color: Colors.white,fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    required String image,
    required double height,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selectedMethod == value
                ? AppColors.primaryColor
                : AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMethod = newValue;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(title, style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor,fontWeight: FontWeight.bold)),
            const Spacer(),
            Image.asset(image, height: height),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    if (widget.packageName != null && widget.packagePrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppStyles.titleMedium(context).copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor,
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.packageName!,
                  style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: Colors.black54, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Amount:',
                          style: AppStyles.bodyLarge(context).copyWith(color: AppColors.secondaryTextColor,fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      widget.packagePrice == "10" || widget.packagePrice == "14" ? '\$${widget.packagePrice!}' : 'Rs.${widget.packagePrice!}',
                      style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    } else if (widget.doctorId != null &&
        widget.appointmentDate != null &&
        widget.appointmentTime != null &&
        widget.slotNumber != null &&
        widget.fees != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Summary',
            style: AppStyles.titleMedium(context).copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor,
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Booking',
                  style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  'Date: ${widget.appointmentDate}',
                  style: AppStyles.bodyLarge(context).copyWith(color: AppColors.secondaryTextColor,fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: ${widget.appointmentTime}',
                  style: AppStyles.bodyLarge(context).copyWith(color: AppColors.secondaryTextColor,fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments, color: Colors.black54, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Fees:',
                          style: AppStyles.bodyLarge(context).copyWith(color: AppColors.secondaryTextColor,fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${widget.fees}',
                      style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}



/*import 'package:Webdoc/screens/easypaisa_payment_screen.dart';
import 'package:flutter/material.dart';

import '../widgets/payment_method_tile.dart';
import 'generic_payment_gateway_screen.dart';
import 'jazzcash_screen.dart'; // Import the payment method tile widget

class PaymentScreen extends StatelessWidget {
  // Accept package details as arguments
  final int? packageId; // Make nullable
  final String? packageName; // Make nullable
  final String? packagePrice; // Make nullable
  final String? doctorId;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? slotNumber;
  final String? fees;

  // Default Constructor (for package purchases)
  const PaymentScreen({
    Key? key,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.doctorId, // Make optional
    this.appointmentDate, // Make optional
    this.appointmentTime, // Make optional
    this.slotNumber, // Make optional
    this.fees, // Make optional
  }) : super(key: key);

  // Named Constructor (for appointment bookings)
  const PaymentScreen.appointment({
    Key? key,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.slotNumber,
    required this.fees,
  })  : packageId = null, // Set to null
        packageName = null, // Set to null
        packagePrice = null, // Set to null
        super(key: key);


  @override
  Widget build(BuildContext context) {
    // Recommended height for the Image.asset widgets.
    // This height should be less than or equal to the leadingWidgetSize (40.0)
    // defined in PaymentMethodTile.dart to ensure they fit inside the fixed box.
    const double imageAssetHeight = 30.0; // Adjust as needed, ensure <= 40.0

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Options'),
        backgroundColor: Colors.white, // Black AppBar
        foregroundColor: Colors.black, // White text/icons
      ),
      backgroundColor: Colors.white, // White background
      body: SingleChildScrollView( // Allows scrolling if content exceeds screen height
        padding: const EdgeInsets.all(20.0), // Padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Section - Moved to a separate method
            _buildOrderSummary(),

            // Payment Methods Title
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16), // Space before the list of tiles

            // List of Payment Method Tiles using Image.asset
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/alfalah.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain is optional but good for different aspect ratios
                // fit: BoxFit.contain,
              ),
              title: 'Credit / Debit Card',
              onTap: () {
                // Navigate to the payment gateway screen with details
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenericPaymentGatewayScreen(
                      packageId: packageId ?? 0, // Provide a default if null
                      packageName: packageName ?? "", // Provide a default if null
                      packagePrice: packagePrice ?? "0", // Provide a default if null
                      bankName: 'Credit/Debit', // Name for the next screen
                      paymentUrl: 'alfalahDc', // Corresponds to Global.paymentUrl = "alfalahDc"
                    ),
                  ),
                );
              },
            ),
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/alfalah.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'Bank Alfalah Account',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenericPaymentGatewayScreen(
                      packageId: packageId ?? 0, // Provide a default if null
                      packageName: packageName ?? "", // Provide a default if null
                      packagePrice: packagePrice ?? "0", // Provide a default if null
                      bankName: 'Alfalah Account', // Name for the next screen
                      paymentUrl: 'alfalahAc', // Corresponds to Global.paymentUrl = "alfalahAc"
                    ),
                  ),
                );
              },
            ),
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/alfalah.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'Bank Alfalah Wallet',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenericPaymentGatewayScreen(
                      packageId: packageId ?? 0, // Provide a default if null
                      packageName: packageName ?? "", // Provide a default if null
                      packagePrice: packagePrice ?? "0", // Provide a default if null
                      bankName: 'Alfalah Wallet', // Name for the next screen
                      paymentUrl: 'alfalahWl', // Corresponds to Global.paymentUrl = "alfalahWl"
                    ),
                  ),
                );
              },
            ),
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/jazzcash.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'JazzCash',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JazzCashScreen(
                        packageId: packageId ?? 0, // Provide a default if null
                        packageName: packageName ?? "", // Provide a default if null
                        packagePrice: packagePrice ?? "0", // Provide a default if null,
                        doctorId: doctorId,
                        appointmentDate: appointmentDate,
                        appointmentTime: appointmentTime,
                        slotNumber: slotNumber,
                        fees: fees
                    ),
                  ),
                );
              },
            ),

            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/easypaisa.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'EasyPaisa',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EasyPaisaScreen(
                        packageId: packageId ?? 0, // Provide a default if null
                        packageName: packageName ?? "", // Provide a default if null
                        packagePrice: packagePrice ?? "0", // Provide a default if null,
                        doctorId: doctorId,
                        appointmentDate: appointmentDate,
                        appointmentTime: appointmentTime,
                        slotNumber: slotNumber,
                        fees: fees
                    ),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  // Method to build the Order Summary section based on available data
  Widget _buildOrderSummary() {
    if (packageName != null && packagePrice != null) {
      // Show package details
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packageName!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_offer_outlined,
                            color: Colors.black54, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rs.${packagePrice!}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    } else if (doctorId != null &&
        appointmentDate != null &&
        appointmentTime != null &&
        slotNumber != null && fees != null) {
      // Show appointment details
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment Booking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  'Date: $appointmentDate',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Time: $appointmentTime',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on,
                            color: Colors.black54, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Fees:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rs. $fees',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    } else {
      // If none of the required parameters are available, return an empty SizedBox
      return const SizedBox.shrink();
    }
  }
}*/




/*
// lib/screens/payment_screen.dart

import 'package:Webdoc/screens/easypaisa_payment_screen.dart';
import 'package:flutter/material.dart';

import '../widgets/payment_method_tile.dart';
import 'generic_payment_gateway_screen.dart';
import 'jazzcash_screen.dart'; // Import the payment method tile widget

class PaymentScreen extends StatelessWidget {
  // Accept package details as arguments
  final int packageId; // Kept here just in case it's needed for the payment gateway itself
  final String packageName;
  final String packagePrice;

  const PaymentScreen({
    Key? key,
    required this.packageId, // Keep packageId in the constructor
    required this.packageName,
    required this.packagePrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Recommended height for the Image.asset widgets.
    // This height should be less than or equal to the leadingWidgetSize (40.0)
    // defined in PaymentMethodTile.dart to ensure they fit inside the fixed box.
    const double imageAssetHeight = 30.0; // Adjust as needed, ensure <= 40.0

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Options'),
        backgroundColor: Colors.white, // Black AppBar
        foregroundColor: Colors.black, // White text/icons
      ),
      backgroundColor: Colors.white, // White background
      body: SingleChildScrollView( // Allows scrolling if content exceeds screen height
        padding: const EdgeInsets.all(20.0), // Padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Redesigned "Paying For" Section
            const Text( // Title above the redesigned section
              'Order Summary', // Changed title for better clarity
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12), // Spacing below title

            Container( // Container for redesigned package details
              padding: const EdgeInsets.all(16.0), // Increased padding inside
              decoration: BoxDecoration(
                color: Colors.grey[50], // Very light grey background
                borderRadius: BorderRadius.circular(15.0), // Match tile corners
                // Removed border line
                boxShadow: [ // Subtle shadow for this container
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Lighter shadow than tiles
                    spreadRadius: 0,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column( // Use Column for vertical arrangement inside
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageName, // Package Name
                    style: const TextStyle(
                      fontSize: 18, // Slightly larger font for name
                      fontWeight: FontWeight.bold, // Bold name
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10), // Space between name and price

                  Row( // Row for Price with icon
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_offer_outlined, color: Colors.black54, size: 20), // Price icon
                          const SizedBox(width: 8),
                          const Text(
                            'Amount:', // Changed label to Amount
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rs.${packagePrice}', // Display price with Rs
                        style: const TextStyle(
                          fontSize: 20, // Larger price font
                          fontWeight: FontWeight.w900, // Extra bold price
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32), // More space before payment methods title

            // Payment Methods Title
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16), // Space before the list of tiles

            // List of Payment Method Tiles using Image.asset
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/alfalah.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain is optional but good for different aspect ratios
                // fit: BoxFit.contain,
              ),
              title: 'Credit / Debit Card',
              onTap: () {
                // Navigate to the payment gateway screen with details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenericPaymentGatewayScreen(
                      packageId: packageId,
                      packageName: packageName,
                      packagePrice: packagePrice,
                      bankName: 'Credit/Debit', // Name for the next screen
                      paymentUrl: 'alfalahDc', // Corresponds to Global.paymentUrl = "alfalahDc"
                    ),
                  ),
                );
              },
            ),
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/alfalah.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'Bank Alfalah Account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenericPaymentGatewayScreen(
                      packageId: packageId,
                      packageName: packageName,
                      packagePrice: packagePrice,
                      bankName: 'Alfalah Account', // Name for the next screen
                      paymentUrl: 'alfalahAc', // Corresponds to Global.paymentUrl = "alfalahAc"
                    ),
                  ),
                );
              },
            ),
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/alfalah.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'Bank Alfalah Wallet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenericPaymentGatewayScreen(
                      packageId: packageId,
                      packageName: packageName,
                      packagePrice: packagePrice,
                      bankName: 'Alfalah Wallet', // Name for the next screen
                      paymentUrl: 'alfalahWl', // Corresponds to Global.paymentUrl = "alfalahWl"
                    ),
                  ),
                );
              },
            ),
            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/jazzcash.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'JazzCash',
              onTap: () {
                // Navigate to JazzCashScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JazzCashScreen(
                      packageId: packageId,
                      packageName: packageName,
                      packagePrice: packagePrice,
                    ),
                  ),
                );
              },
            ),

            PaymentMethodTile(
              leadingWidget: Image.asset(
                'assets/images/easypaisa.png',
                height: imageAssetHeight,
                // fit: BoxFit.contain,
              ),
              title: 'EasyPaisa',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EasyPaisaScreen(
                      packageId: packageId,
                      packageName: packageName,
                      packagePrice: packagePrice,
                      // paymentUrl is null
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20), // Space at the bottom
          ],
        ),
      ),
    );
  }
}*/
