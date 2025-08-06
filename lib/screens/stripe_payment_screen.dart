import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:flutter/cupertino.dart' as widgets;
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import 'doctor_list_screen.dart';

class StripePaymentScreen extends StatefulWidget {
  final int? packageId;
  final String? packageName;
  final String? packagePrice;
  final String? fromProfile;
  final String? doctorId;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? slotNumber;
  final String? fees;
  final String? couponCode;

  const StripePaymentScreen({
    Key? key,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.fromProfile,
    this.doctorId,
    this.appointmentDate,
    this.appointmentTime,
    this.slotNumber,
    this.fees,
    this.couponCode,
  }) : super(key: key);

  @override
  _StripePaymentScreenState createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  String? checkoutUrl;
  double _loadingProgress = 0;
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? transactionDate;
  String? transactionID;
  final ScreenshotController screenshotController = ScreenshotController();
  String _successUrl = "https://appointment.webdoc.com.pk/payment-success";
  String _appointmentsuccessUrl = "https://appointment.webdoc.com.pk/appointment-payment-success";
  String _appointmentcancelUrl = "https://appointment.webdoc.com.pk/appointment-payment-cancel";
  String _cancelUrl = "https://appointment.webdoc.com.pk/payment-cancel";

/*  String _successUrl = "https://appointment.webdoc.com.pk/payment-success";
  String _appointmentsuccessUrl = "https://appointment.6by6.co/appointment-payment-success";
  String _appointmentcancelUrl = "https://appointment.6by6.co/appointment-payment-cancel";
  String _cancelUrl = "https://appointment.webdoc.com.pk/payment-cancel";*/
  @override
  void initState() {
    super.initState();

    _getCheckoutUrl().then((_) {
      if (checkoutUrl != null) {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  _loadingProgress = progress / 100;
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  _loadingProgress = 0;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _loadingProgress = 1.0;
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _loadingProgress = 0;
                    });
                  }
                });
              },
              onWebResourceError: (WebResourceError error) {
                print('Web resource error: ${error.description}');
                setState(() {
                  _loadingProgress = 0;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith(_successUrl)) {
                  print("Success URL: ${request.url}");
                  _handlePaymentSuccess();
                  return NavigationDecision.prevent;
                } else if (request.url.startsWith(_cancelUrl)) {
                  print("Cancel URL: ${request.url}");
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                }else if (request.url.startsWith(_appointmentsuccessUrl)) {
                  print("Appointment Success URL: ${request.url}");
                  _handlePaymentSuccess();
                  return NavigationDecision.prevent;
                } else if (request.url.startsWith(_appointmentcancelUrl)) {
                  print("Appointment Cancel URL: ${request.url}");
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(checkoutUrl!))
          ..runJavaScript(
              'document.body.style.backgroundColor = "white";'); // Set background using javascript
      }
    });
  }

  Future<void> _getCheckoutUrl() async {
    String apiUrl ="";
    if(widget.packageId!=0){

      apiUrl = '${ApiService.irfanBaseUrl}stripe/payment?profile_id=${SharedPreferencesManager.getString('id')}&package_id=${widget.packageId}';
    //  apiUrl = 'https://digital.webdoc.com.pk/ci4webdocsite/public/api/v1/stripe/payment?profile_id=${SharedPreferencesManager.getString('id')}&package_id=${widget.packageId}';
    } else {
      apiUrl = '${ApiService.irfanBaseUrl}stripe/appointment-payment?profile_id=${SharedPreferencesManager.getString('id')}&price=${widget.fees}&couponCode=${widget.couponCode}';
     // apiUrl = 'https://digital.webdoc.com.pk/ci4webdocsite/public/api/v1/stripe/appointment-payment?profile_id=${SharedPreferencesManager.getString('id')}&price=${widget.fees}&couponCode=${widget.couponCode}';
    }


    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cookie = prefs.getString('ci_session');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Cookie': 'ci_session=$cookie'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          checkoutUrl = data['payLoad']['url'];
          _isLoading = false; // Set loading to false here after successful URL fetch
        });
      } else {
        setState(() {
          _errorMessage =
          'Failed to load payment URL: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to load payment URL: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> _handlePaymentSuccess() async {
    final apiService = ApiService();

    final String? userId = SharedPreferencesManager.getString('id');
    final String? phoneNo = SharedPreferencesManager.getString('mobileNumber');
    final String? pin = SharedPreferencesManager.getString('pin');
    final int safePackageId =
        widget.packageId ?? 0; // Or another appropriate default
    final String safePackagePrice = widget.packagePrice ?? "0";

    // Activate Package API Call - Show loading overlay
    if(widget.packageId != 0) {
      showLoadingOverlay(context, "Activating Package...");
    } else {
      showLoadingOverlay(context, "Appointment Booking...");
    }


    try {
      if (widget.doctorId != null &&
          widget.appointmentDate != null &&
          widget.appointmentTime != null &&
          widget.slotNumber != null) {
        await _bookSlot(apiService);
      } else {
        await _activatePackageAndLogin(apiService);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _activatePackageAndLogin(ApiService apiService) async {
    try {
      final activatePackageResponse = await apiService.activatePackage(
        context: context,
        user_id: SharedPreferencesManager.getString("id") ?? "ID",
        packageId: widget.packageId.toString(),
      );
      Navigator.of(context).pop();

      if (activatePackageResponse != null &&
          activatePackageResponse.statusCode == 1) {
        // Package activated successfully -> Call Login API
        await _loginAfterActivatePackage(apiService);
      } else {
        String errorMessage = "Package activation failed";

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

        errorMessage = activatePackageResponse!.statusMessage!.join(', ');
        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      // Dismiss loading overlay
      Navigator.of(context).pop();
      _showErrorDialog("An error occurred: $error");
    }
  }

  Future<void> _loginAfterActivatePackage(ApiService apiService) async {
    final String? mobileNumber =
        SharedPreferencesManager.getString("mobileNumber") ?? "Phone Number";
    final String? pin = SharedPreferencesManager.getString("pin") ?? "Pin";

    // Show loading indicator while making API call
    showLoadingOverlay(context, "Generating Receipt...");

    try {
      final loginResponse = await apiService.login(context, mobileNumber!, pin!);
      Navigator.of(context).pop(); // Dismiss loading dialog

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

        // Now show the receipt dialog
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'Stripe',
          totalPayment: widget.fees ?? widget.packagePrice ?? '',
          transactionId: transactionID ?? '',
          packageName: widget.packageName ?? 'Consultation',
          activatedOn: SharedPreferencesManager.getString("activeDate") ?? 'N/A',
          expiryOn: SharedPreferencesManager.getString("expiryDate") ?? 'N/A',
          onOk: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DoctorListScreen()),
            );
          },
        );
      } else {
        String errorMessage = "Login Failed";

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

        errorMessage = loginResponse!.statusMessage!.join(', ');
        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      _showErrorDialog("An error occurred during login: $error");
    }
  }

  Future<void> _bookSlot(ApiService apiService) async {
    final String? userId = SharedPreferencesManager.getString('id');

    try {
      final bookSlotResponse = await apiService.bookSlot(
        context: context,
        patientId: userId ?? "", // Replace with actual patient ID if available
        doctorId: widget.doctorId!,
        appointmentDate: widget.appointmentDate!,
        appointmentTime: widget.appointmentTime!,
        slotNumber: widget.slotNumber!,
          paymentMethod:Global.paymentMethod,
          price: widget.fees.toString(),
          couponCode: widget.couponCode.toString(),
      );
      Navigator.of(context).pop();

      if (bookSlotResponse != null && bookSlotResponse.statusCode == 1) {
        // Package activated successfully - Show receipt dialog
        String formattedTimeSlot = 'Not Selected';
        if (widget.appointmentTime != null) {
          try {
            final parsedTime =
            DateFormat('HH:mm').parse(widget.appointmentTime!);
            formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
          } catch (e) {
            formattedTimeSlot = 'Invalid Time';
            print('Error formatting time: $e');
          }
        }
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'Stripe',
          totalPayment: widget.fees ?? widget.packagePrice ?? '',
          transactionId: transactionID ?? '',
          packageName: 'Appointment Booking',
          activatedOn: widget.appointmentDate!, //set here
          expiryOn: '${widget.appointmentDate} $formattedTimeSlot',
          onOk: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PastAppointmentsScreen()),
            );
          },
        );
      } else {
        String errorMessage = "Slot Booking failed";

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

        errorMessage = bookSlotResponse!.statusMessage!.join(', ');

        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      // Dismiss loading overlay
      Navigator.of(context).pop();
      _showErrorDialog("An error occurred: $error");
    }
  }

  Future<void> showBookingReceiptDialog(
      BuildContext context, {
        required String paymentDate,
        required String paymentMedium,
        required String totalPayment,
        required String transactionId,
        required String packageName,
        required String activatedOn,
        required String expiryOn,
        required VoidCallback onOk,
      }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Make dialog non-dismissable
      builder: (BuildContext context) {
        // Disable back button press
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery
                        .of(context)
                        .size
                        .width * 0.9), // Increased width
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/booking_receipt_bg.png"),
                    fit: BoxFit.fill,
                  ),
                ),
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10),
                      packageName == "Appointment Booking"
                          ? Text(
                        "Appointment Booked Successfully\nReceipt",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      )
                          : Text(
                        "Package Activated Successfully\nReceipt",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.calendar_today,
                        label: "PAYMENT DATE",
                        value: activatedOn,
                      ),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.payment,
                        label: "PAYMENT MEDIUM",
                        value: paymentMedium,
                      ),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.attach_money,
                        label: "TOTAL PAYMENT",
                        value: "PKR $totalPayment /-",
                      ),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.confirmation_number,
                        label: "TRANSACTION ID",
                        value: "706968",
                      ),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.card_giftcard,
                        label: "PACKAGE",
                        value: packageName,
                      ),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.check_circle_outline,
                        label: "ACTIVATED ON",
                        value: activatedOn,
                      ),
                      _buildReceiptRowWithGreyIcon(
                        context,
                        icon: Icons.timer,
                        label: "EXPIRY ON",
                        value: expiryOn,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.download),
                            label: Text("Save"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () async {
                              final Uint8List? imageBytes = await screenshotController.capture();
                              if (imageBytes != null) {
                                await _saveScreenshotToDownloads(context, imageBytes);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to capture screenshot.')),
                                );
                              }
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              textStyle: TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onOk();
                            },
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveScreenshotToDownloads(BuildContext context, Uint8List imageBytes) async {
    try {
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = 'receipt_$timestamp.png';
      String? savedPath;

      if (Platform.isAndroid) {
        final params = SaveFileDialogParams(
          data: imageBytes,
          fileName: fileName,
        );
        savedPath = await FlutterFileDialog.saveFile(params: params);
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(imageBytes);
        savedPath = file.path;
      }

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Receipt saved successfully.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save cancelled or failed.")),
        );
      }
    } catch (e) {
      print("Error saving screenshot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving receipt: $e")),
      );
    }
  }



  Widget _buildReceiptRowWithGreyIcon(BuildContext context,
      {required String label, required String value, IconData? icon}) {
    return Column(
      children: [
        Divider(color: Colors.grey),
        widgets.Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                  SizedBox(width: icon != null ? 8 : 0),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColor,
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //Helper function to show loading screen
  void showLoadingOverlay(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryColor),
              SizedBox(height: 10),
              Text(text),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    if (widget.doctorId != null &&
        widget.appointmentDate != null &&
        widget.appointmentTime != null &&
        widget.slotNumber != null &&
        widget.fees != null) {
      // Appointment Flow
      return Padding( // Wrap in Padding
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Summary',
              style: AppStyles.titleMedium(context).copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18.0),
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
                    style: AppStyles.bodyLarge(context).copyWith(color: Colors.black87, fontWeight: FontWeight.bold),
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
                          Icon(Icons.payments_rounded,
                              color: Colors.black54, size: 20),
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
            SizedBox(height: 24),
          ],
        ),
      );
    } else if (widget.packageName != null && widget.packagePrice != null) {
      // Package Flow
      return Padding( // Wrap in Padding
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: AppStyles.titleMedium(context).copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18.0),
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
                          Icon(Icons.local_offer_outlined,
                              color: Colors.black54, size: 20),
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
            SizedBox(height: 24),
          ],
        ),
      );
    } else {
      return SizedBox.shrink(); // Or display a default message
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Stripe Payment",
          style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text('Loading payment...'),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      )
          : checkoutUrl == null
          ? Center(child: Text("Failed to load payment URL"))
          : Column(
        children: [
          _buildOrderSummary(),
          if (_loadingProgress > 0 && _loadingProgress < 1)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
            ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (checkoutUrl != null) // Make sure checkoutUrl is not null
                  WebViewWidget(controller: _controller),
                if (_loadingProgress > 0 && _loadingProgress < 1)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Loading...", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}