
import 'dart:convert';
import 'dart:io';
import 'package:Webdoc/screens/doctor_list_screen.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';
import '../models/easypaisa_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'package:flutter/widgets.dart' as widgets;

class EasyPaisaScreen extends StatefulWidget {
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

  const EasyPaisaScreen({
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
  _EasyPaisaScreenState createState() => _EasyPaisaScreenState();
}

class _EasyPaisaScreenState extends State<EasyPaisaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  String? transactionDate;
  String? transactionID;
  final ScreenshotController screenshotController = ScreenshotController();

  static const String publicKeyPEM = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqt1+NSNBc76lyioGThoc
1S/cJ+tPSBLNV4/yXIjBanW5qUBdWkAoJOTgUOl20tn9jgb6QJDbd32rINM7UPvh
YVdsd6W2BkFkWP6ufkiQQZOlGu3nDq+f2ftEGt9hV5/5Ma5nHh3FP1xyB616A7g9
xfw4KMJb/9WXaXYUC+CJvNt48pmStHZe/on4+S5qaWLXgMFB6TVrPTGZYUVWjJlL
fAGOlyRYVZur0MdM75tYZltgIQF6j+jd40fT3ZbZvRDeYKWNUHAczmJphKlL11DY
SWaCXdqWrWsw8eaVxO4sLR6jPNRT78OLaTHxAmmKnuH++stk9iFLSAZ8bkfZQYkY
LwIDAQAB
-----END PUBLIC KEY-----''';

  @override
  void dispose() {
    _accountNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleEasyPaisaPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // 1. Construct JSON Payload

        String amount = (widget.doctorId != null && widget.fees != null)
            ? widget.fees! // Use Appointment Fee
            : widget.packagePrice ?? "0"; // Use Package Price, default to "0"
        final Map<String, dynamic> postParams = {
          "store_name": "StudentFeeCollectionStore",
          "msisdn": _accountNumberController.text,
          "email": _emailController.text,
          "amount": amount, //widget.fees != null ? widget.fees : widget.packagePrice, //Use Actual amount here
         // "amount": "1", //widget.fees != null ? widget.fees : widget.packagePrice, //Use Actual amount here
        };
        final String jsonData = json.encode(postParams);

        // 2. Encrypt the JSON Data
        final String? encryptedJson =
        await rsaEncrypt(jsonData.toString(), publicKeyPEM.toString());

        if (encryptedJson == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Encryption failed.';
          });
          return;
        }
        // Replace this with your actual user ID retrieval logic
        String patientId = SharedPreferencesManager.getString('id') ?? "N/A";

        // 3. Make the API Call (using the new service method)
        final EasyPaisaResponse? easyPaisaResponse =
        await ApiService().easypaisaPayment(context, encryptedJson);

        if (easyPaisaResponse != null && easyPaisaResponse.statusCode == '0000') {
          setState(() {
            transactionDate = easyPaisaResponse.payLoad?.transactionDateTime ?? '';
            transactionID = easyPaisaResponse.payLoad?.transactionId ?? '';
          });

          // Determine which API to call based on the presence of doctorId
          if (widget.doctorId != null &&
              widget.appointmentDate != null &&
              widget.appointmentTime != null &&
              widget.slotNumber != null) {
            await _bookSlotAndShowReceipt(easyPaisaResponse);
          } else {
            // Activate the package FIRST
            await _activatePackageAndThenLogin(easyPaisaResponse);
          }
        } else {
          // EasyPaisa Payment Failed
          setState(() {
            _isLoading = false;
            _errorMessage = easyPaisaResponse?.payLoad?.responseDesc ??
                'EasyPaisa payment failed.';
          });
        }
      } catch (e) {
        print('Exception during payment: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      } finally {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Activate package and THEN call Login API
  Future<void> _activatePackageAndThenLogin(
      EasyPaisaResponse easyPaisaResponse) async {
    final apiService = ApiService();

    final String? userId = SharedPreferencesManager.getString('id');
    final String? phoneNo = SharedPreferencesManager.getString('mobileNumber');
    final String? pin = SharedPreferencesManager.getString('pin');
    final int safePackageId =
        widget.packageId ?? 0; // Or another appropriate default
    final String safePackagePrice = widget.packagePrice ?? "0";

    // Activate Package API Call - Show loading overlay
    showLoadingOverlay(context, "Activating Package...");

    try {
      final activatePackageResponse = await apiService.activatePackage(
        context: context,
        user_id: SharedPreferencesManager.getString("id") ??
            "ID",
        packageId:safePackageId.toString()
      );

      // Dismiss loading overlay
      Navigator.of(context).pop();

      if (activatePackageResponse != null &&
          activatePackageResponse.statusCode == 1) {
        // Package activated successfully -> Call Login API
        await _loginAfterActivatePackage(easyPaisaResponse);

      } else {

        String errorMessage = "Package activation failed";

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

        errorMessage = activatePackageResponse!.statusMessage!.join(', ');
        _showErrorDialog(
                errorMessage);
      }
    } catch (error) {
      // Dismiss loading overlay
      Navigator.of(context).pop();
      _showErrorDialog("An error occurred: $error");
    }
  }

  //Call Login API *after* activating package
  Future<void> _loginAfterActivatePackage(
      EasyPaisaResponse easyPaisaResponse) async {
    final apiService = ApiService();
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
          paymentMedium: 'EasyPaisa',
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

  // Helper function to show a generic dialog
  void showGenericDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookSlotAndShowReceipt(
      EasyPaisaResponse easyPaisaResponse) async {
    final apiService = ApiService();

    final String? userId = SharedPreferencesManager.getString('id');

    // Activate Package API Call - Show loading overlay
    showLoadingOverlay(context, "Booking Slot...");

    try {
      final bookSlotResponse = await apiService.bookSlot(
        context: context,
        patientId: userId ?? "", // Replace with actual patient ID if available
        doctorId: widget.doctorId!,
        appointmentDate: widget.appointmentDate!,
        appointmentTime: widget.appointmentTime!,
        slotNumber: widget.slotNumber!,
          paymentMethod:Global.paymentMethod,
          price:widget.fees.toString(),
          couponCode: widget.couponCode.toString()
      );

      // Dismiss loading overlay
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
          paymentMedium: 'EasyPaisa',
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

  String rsaEncrypt(String plainText, String publicKeyPem) {
    final parser = encrypt.RSAKeyParser();
    final RSAPublicKey publicKey = parser.parse(publicKeyPem) as RSAPublicKey;

    final encrypter = encrypt.Encrypter(encrypt.RSA(
      publicKey: publicKey,
      encoding: encrypt.RSAEncoding.PKCS1,
    ));

    final encrypted = encrypter.encrypt(plainText);
    return encrypted.base64;
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
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
                      Text(
                        packageName == "Appointment Booking"
                            ? "Appointment Booked Successfully\nReceipt"
                            : "Package Activated Successfully\nReceipt",
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
                        value: paymentDate,
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
                        value: transactionId,
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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


  /* Future<void> showBookingReceiptDialog(
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
                        value: paymentDate,
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
                        value: transactionId,
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
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => _saveReceiptToGallery(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  }*/



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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
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

  Widget _buildOrderSummary() {
    if (widget.doctorId != null &&
        widget.appointmentDate != null &&
        widget.appointmentTime != null &&
        widget.slotNumber != null &&
        widget.fees != null) {
      // Appointment Flow
      return Column(
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
      );
    } else if (widget.packageName != null && widget.packagePrice != null) {
      // Package Flow
      return Column(
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
                      'Rs.${widget.packagePrice}',
                      style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
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
          "EasyPaisa",
          style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Summary Section
              _buildOrderSummary(),

              // EasyPaisa Mobile Number Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(11)],
                  decoration: InputDecoration(
                    labelText: 'EasyPaisa Mobile Number',
                    hintText: 'Enter your 11-digit mobile number',
                    prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter mobile number';
                    if (value.length != 11)
                      return 'Mobile number must be 11 digits';
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 32),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              // Instructions
              Container(  // Use Container for better styling
                padding: const EdgeInsets.all(16.0), // Add padding around the entire block
                margin: const EdgeInsets.only(bottom: 16.0), // Add margin below
                decoration: BoxDecoration( // Decorate the container
                  color: Colors.white, // Set a background color
                  borderRadius: BorderRadius.circular(8.0), // Round corners
                  boxShadow: [  // Add a subtle shadow
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column( // Use Column to stack title and instructions
                  children: [
                    Text(
                      "Payment Instructions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8), // Add some space between title and instructions
                    Container( // Added a Container for the line
                      width: double.infinity, // Make the line span the entire width
                      height: 1,   // Set the height of the line
                      color: Colors.grey[300],  // Set the color of the line (light grey)
                    ),
                    SizedBox(height: 8),
                    Text(
                      "1. Open your EasyPaisa app.\n"
                          "2. Go to \"My Account\".\n"
                          "3. Select \"My Approvals\".\n"
                          "4. Find the pending payment and click \"Accept\".",
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.left, // Align instructions to the left
                    ),
                  ],
                ),
              ),
              // Pay Now Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEasyPaisaPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Pay Now', style: AppStyles.bodyLarge(context).copyWith(color: AppColors.backgroundColor,fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:screenshot/screenshot.dart';
import '../models/easypaisa_response.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'package:flutter/widgets.dart' as widgets;
class EasyPaisaScreen extends StatefulWidget {
  final int packageId;
  final String packageName;
  final String packagePrice;

  const EasyPaisaScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
  }) : super(key: key);

  @override
  _EasyPaisaScreenState createState() => _EasyPaisaScreenState();
}

class _EasyPaisaScreenState extends State<EasyPaisaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  String? transactionDate;
  String? transactionID;
  final ScreenshotController screenshotController = ScreenshotController();

  static const String publicKeyPEM ='''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqt1+NSNBc76lyioGThoc
1S/cJ+tPSBLNV4/yXIjBanW5qUBdWkAoJOTgUOl20tn9jgb6QJDbd32rINM7UPvh
YVdsd6W2BkFkWP6ufkiQQZOlGu3nDq+f2ftEGt9hV5/5Ma5nHh3FP1xyB616A7g9
xfw4KMJb/9WXaXYUC+CJvNt48pmStHZe/on4+S5qaWLXgMFB6TVrPTGZYUVWjJlL
fAGOlyRYVZur0MdM75tYZltgIQF6j+jd40fT3ZbZvRDeYKWNUHAczmJphKlL11DY
SWaCXdqWrWsw8eaVxO4sLR6jPNRT78OLaTHxAmmKnuH++stk9iFLSAZ8bkfZQYkY
LwIDAQAB
-----END PUBLIC KEY-----''';

  @override
  void dispose() {
    _accountNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0, // Remove shadow
        iconTheme: IconThemeData(color: Colors.black), // Black back arrow
        title: Text(
          'EasyPaisa',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Summary Section
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
                padding: const EdgeInsets.all(18.0),
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
                      widget.packageName,
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
                            Icon(Icons.local_offer_outlined, color: Colors.black54, size: 20),
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
                          'Rs.${widget.packagePrice}',
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
              SizedBox(height: 24),

              // JazzCash Mobile Number Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(11)],
                  decoration: InputDecoration(
                    labelText: 'EasyPaisa Mobile Number',
                    hintText: 'Enter your 11-digit mobile number',
                    prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter mobile number';
                    if (value.length != 11) return 'Mobile number must be 11 digits';
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // CNIC Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 32),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              // Pay Now Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEasyPaisaPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Pay Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEasyPaisaPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // 1. Construct JSON Payload
        final Map<String, dynamic> postParams = {
          "store_name": "StudentFeeCollectionStore",
          "msisdn": _accountNumberController.text,
          "email": _emailController.text,
          "amount": "1",
        };
        final String jsonData = json.encode(postParams);

        // 2. Encrypt the JSON Data
        final String? encryptedJson = await rsaEncrypt(jsonData.toString(),publicKeyPEM.toString());

        if (encryptedJson == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Encryption failed.';
          });
          return;
        }
        // Replace this with your actual user ID retrieval logic
         String patientId = SharedPreferencesManager.getString('id')?? "N/A"; // Example user ID

        // 3. Make the API Call (using the new service method)
        final EasyPaisaResponse? easyPaisaResponse =
        await ApiService().easypaisaPayment(context, encryptedJson);

        if (easyPaisaResponse != null && easyPaisaResponse.statusCode == '0000') {

          setState(() {
            transactionDate = easyPaisaResponse.payLoad?.transactionDateTime ?? '';
            transactionID = easyPaisaResponse.payLoad?.transactionId ?? '';
          });

          // Directly call activation and then show receipt in the same function
          await _activatePackageAndShowReceipt(easyPaisaResponse);
        } else {
          // EasyPaisa Payment Failed
          setState(() {
            _isLoading = false;
            _errorMessage = easyPaisaResponse?.payLoad?.responseDesc ?? 'EasyPaisa payment failed.';
          });
        }
      } catch (e) {
        print('Exception during payment: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      } finally {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  String rsaEncrypt(String plainText, String publicKeyPem) {
    final parser = encrypt.RSAKeyParser();
    final RSAPublicKey publicKey = parser.parse(publicKeyPem) as RSAPublicKey;

    final encrypter = encrypt.Encrypter(encrypt.RSA(
      publicKey: publicKey,
      encoding: encrypt.RSAEncoding.PKCS1,
    ));

    final encrypted = encrypter.encrypt(plainText);
    return encrypted.base64;
  }


  //Helper function to show a generic dialog
  void showGenericDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _activatePackageAndShowReceipt(
      EasyPaisaResponse easyPaisaResponse) async {
    final apiService = ApiService();

    final String? userId = SharedPreferencesManager.getString('id');
    final String? phoneNo = SharedPreferencesManager.getString('mobileNumber');
    final String? pin = SharedPreferencesManager.getString('pin');

    // Activate Package API Call - Show loading overlay
    showLoadingOverlay(context, "Activating Package...");

    try {
      final activatePackageResponse = await apiService.activatePackage(
        context: context,
        packageId: widget.packageId,
        paidAmount: widget.packagePrice,
        accountNumber: SharedPreferencesManager.getString("mobileNumber") ??
            "Phone Number",
        mobileNumber: SharedPreferencesManager.getString("mobileNumber") ??
            "Phone Number",
        transactionType: "Online",
        transactionReferenceNo: easyPaisaResponse.payLoad?.transactionId ?? '',
        bank: "EasyPaisa",
      );

      // Dismiss loading overlay
      Navigator.of(context).pop();

      if (activatePackageResponse != null &&
          activatePackageResponse.responseCode == "0000") {
        // Package activated successfully - Show receipt dialog
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'EasyPaisa',
          totalPayment: widget.packagePrice,
          transactionId: transactionID ?? '',
          packageName: widget.packageName,
          activatedOn: SharedPreferencesManager.getString("activeDate") ?? 'N/A',
          expiryOn: SharedPreferencesManager.getString("expiryDate") ?? 'N/A',
          onOk: () async {
            await _loginAndNavigate(context);
          },
        );
      } else {
        _showErrorDialog(activatePackageResponse?.message ?? "Package activation failed");
      }
    } catch (error) {
      // Dismiss loading overlay
      Navigator.of(context).pop();
      _showErrorDialog("An error occurred: $error");
    }
  }


//Helper function for login and navigate
  Future<void> _loginAndNavigate(BuildContext context) async {
    final apiService = ApiService();
    final String? mobileNumber =
        SharedPreferencesManager.getString("mobileNumber") ?? "Phone Number";
    final String? pin = SharedPreferencesManager.getString("pin") ?? "Pin";

    // Show loading indicator while making API call
    showLoadingOverlay(context, "Logging In...");

    try {
      final loginResponse = await apiService.login(context, mobileNumber!, pin!);
      Navigator.of(context).pop(); // Dismiss loading dialog
      if (loginResponse != null &&
          loginResponse.responseCode == "0000") //Constants.WEBDOC_SUCCESS_CODE)
          {
        SharedPreferencesManager.putBool("isPackageActivated",
            loginResponse.loginData!.isPackageActivated!);
        if (loginResponse.loginData!.isPackageActivated!) {
          SharedPreferencesManager.putString(
              "expiryDate", loginResponse.loginData!.expiryDate!);
          SharedPreferencesManager.putString(
              "activeDate", loginResponse.loginData!.activeDate!);
          SharedPreferencesManager.putString(
              "PackageName", loginResponse.loginData!.packageName!);
        }
        if (Global.fromProfile == 'dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
      } else {
        showGenericDialog("Login Failed", "Failed to login after activation.");
      }
    } catch (error) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      showGenericDialog("Login Error", "An error occurred during login: $error");
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
                      Text(
                        "Activated Successfully\nReceipt",
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
                        value: paymentDate,
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
                        value: transactionId,
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
                          // ElevatedButton(
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.grey[700],
                          //     foregroundColor: Colors.white,
                          //     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          //     textStyle: TextStyle(fontSize: 16),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(20),
                          //     ),
                          //   ),
                          //   onPressed: () async {
                          //
                          //   },
                          //   child: Text("Save to Gallery"),
                          // ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
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

  Widget _buildReceiptRowWithGreyIcon(BuildContext context,
      {required String label, required String value, IconData? icon}) {
    return  Column(
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
                      color: Colors.grey,
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

  //Helper function to show loading screen
  void showLoadingOverlay(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(text),
            ],
          ),
        );
      },
    );
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
}*/


