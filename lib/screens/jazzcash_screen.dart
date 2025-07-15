
import 'dart:convert';
import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/utils/global.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../models/jazz_cash_response.dart';
import '../services/api_service.dart';

class JazzCashScreen extends StatefulWidget {
  final int? packageId;
  final String? packageName;
  final String? packagePrice;
  final String? fromProfile;

  final String? doctorId;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? slotNumber;
  final String? fees;

  const JazzCashScreen({
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
  }) : super(key: key);

  @override
  _JazzCashScreenState createState() => _JazzCashScreenState();
}

class _JazzCashScreenState extends State<JazzCashScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  bool _isLoading = false;
  String? transactionDate;
  String? transactionID;
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await callJazzCashApi(
          _cnicController.text.trim(),
          _accountNoController.text.trim(),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> callJazzCashApi(String cnic, String mobileNumber) async {
    //final String securityKey = "0bhsfauwu8";//testing
    final String securityKey = "xtxgbut94c"; //production
    // final String merchantID = "MC55362";//testing
    final String merchantID = "55668833"; //production
    // final String password = "6yy81y93ww";//testing
    final String password = "8y9u1u20zd";//production
    const String description = "pp_Description";
    const String billRef = "billRef";
    const String currency = "PKR";

    String dateTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String expiryDateTime = DateFormat('yyyyMMddHHmmss')
        .format(DateTime.now().add(const Duration(days: 1)));
    String txnRefNo = "T$dateTime";

    //Determine the amount based on the flow
    final double amount;
    if (widget.fees != null) {
      amount = double.parse(widget.fees!);
    } else {
      //amount = double.parse(widget.packagePrice ?? '0');
      amount = double.parse("1" ?? '0');
    }

    final int amountInPaisa = (amount * 100).round();

    String secureHashInput = "$securityKey&"
        "$amountInPaisa&"
        "$billRef&"
        "$cnic&"
        "$description&"
        "EN&"
        "$merchantID&"
        "$mobileNumber&"
        "$password&"
        "$currency&"
        "$dateTime&"
        "$expiryDateTime&"
        "$txnRefNo";

    final key = utf8.encode(securityKey);
    final bytes = utf8.encode(secureHashInput);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final secureHash = digest.toString();

    Map<String, String> body = {
      "pp_Language": "EN",
      "pp_MerchantID": merchantID,
      "pp_SubMerchantID": "",
      "pp_Password": password,
      "pp_DiscountedAmount": "",
      "pp_BankID": "",
      "pp_ProductID": "",
      "pp_TxnRefNo": txnRefNo,
      "pp_Amount": amountInPaisa.toString(),
      "pp_TxnCurrency": currency,
      "pp_TxnDateTime": dateTime,
      "pp_BillReference": billRef,
      "pp_Description": description,
      "pp_TxnExpiryDateTime": expiryDateTime,
      "pp_SecureHash": secureHash,
      "ppmpf_1": "",
      "ppmpf_2": "",
      "ppmpf_3": "",
      "ppmpf_4": "",
      "ppmpf_5": "",
      "pp_MobileNumber": mobileNumber,
      "pp_CNIC": cnic,
    };

    final url = Uri.parse(
        "https://payments.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final jazzCashResponse = JazzCashResponse.fromJson(json);

        if (jazzCashResponse.ppResponseCode == "000") {
          setState(() {
            transactionDate = jazzCashResponse.ppTxnDateTime;
            transactionID = jazzCashResponse.ppTxnRefNo;
          });

          // Determine which API to call based on the presence of doctorId
          if (widget.doctorId != null &&
              widget.appointmentDate != null &&
              widget.appointmentTime != null &&
              widget.slotNumber != null) {
            await _bookSlotAndShowReceipt(jazzCashResponse);
          } else {
            // Activate the package FIRST
            await _activatePackageAndThenLogin(jazzCashResponse);
          }
        } else {
          _showErrorDialog(
              jazzCashResponse.ppResponseMessage ?? "Payment failed.");
        }
      } else {
        _showErrorDialog("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
    }
  }

  // Activate package and THEN call Login API
  Future<void> _activatePackageAndThenLogin(
      JazzCashResponse jazzCashResponse) async {
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
        await _loginAfterActivatePackage(jazzCashResponse);

      } else {
        _showErrorDialog(
            (activatePackageResponse?.statusMessage is String && activatePackageResponse?.statusMessage != null)
                ? activatePackageResponse!.statusMessage as String
                : "Package activation failed");
      }
    } catch (error) {
      // Dismiss loading overlay
      Navigator.of(context).pop();
      _showErrorDialog("An error occurred: $error");
    }
  }

  //Call Login API *after* activating package
  Future<void> _loginAfterActivatePackage(
      JazzCashResponse jazzCashResponse) async {
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
              "PackageName", loginResponse.payLoad?.user?.packageName ?? '');


        // Now show the receipt dialog
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'JazzCash',
          totalPayment: widget.fees ?? widget.packagePrice ?? '',
          transactionId: transactionID ?? '',
          packageName: widget.packageName ?? 'Consultation',
          activatedOn: SharedPreferencesManager.getString("activeDate") ?? 'N/A',
          expiryOn: SharedPreferencesManager.getString("expiryDate") ?? 'N/A',
          onOk: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        );
      } else {
        _showErrorDialog("Login Failed: ${loginResponse?.statusMessage}");
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
      JazzCashResponse jazzCashResponse) async {
    final apiService = ApiService();

    final String? userId = SharedPreferencesManager.getString('id');

    // Activate Package API Call - Show loading overlay
    showLoadingOverlay(context, "Booking Slot...");

    try {
      final bookSlotResponse = await apiService.bookSlot(
        context: context,
        patientId: userId ?? "", // Replace with actual patient ID if available
        doctorId: widget.doctorId!,
        // doctorId: "1f86f06e-1a17-48ea-870a-cad92b23c30d",
        appointmentDate: widget.appointmentDate!,
        //appointmentDate: "2025-04-29",
        appointmentTime: widget.appointmentTime!,
        // appointmentTime: "19:40",
        slotNumber: widget.slotNumber!,
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
          paymentMedium: 'JazzCash',
          totalPayment: widget.fees ?? widget.packagePrice ?? '',
          transactionId: transactionID ?? '',
          // packageName: widget.packageName ?? 'Consultation',
          packageName: 'Appointment Booking',
          activatedOn: widget.appointmentDate!, //set here
          expiryOn: '${widget.appointmentDate} $formattedTimeSlot',
          onOk: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        );
      } else {
        _showErrorDialog((bookSlotResponse?.statusMessage is String)
            ? bookSlotResponse!.statusMessage as String
            : "Slot Booking failed");
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
                    maxWidth: MediaQuery.of(context).size.width * 0.9),
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
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
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
    return Column(
      children: [
        Divider(color: Colors.grey),
        Padding(
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
                  'Date: ${widget.appointmentDate}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Time: ${widget.appointmentTime}',
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
                      'Rs. ${widget.fees}',
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
        ],
      );
    } else if (widget.packageName != null && widget.packagePrice != null) {
      // Package Flow
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
                  widget.packageName!,
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
        ],
      );
    } else {
      return SizedBox.shrink(); // Or display a default message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'JazzCash',
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
              _buildOrderSummary(),

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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _accountNoController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(11)],
                  decoration: const InputDecoration(
                    labelText: 'JazzCash Mobile Number',
                    hintText: 'Enter your 11-digit mobile number',
                    prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _cnicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(6)],
                  decoration: const InputDecoration(
                    labelText: 'CNIC (Last 6 digits)',
                    hintText: 'Enter the last 6 digits of your CNIC',
                    prefixIcon: Icon(Icons.credit_card, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter CNIC (last 6 digits)';
                    if (value.length != 6) return 'CNIC must be 6 digits';
                    return null;
                  },
                ),
              ),
              SizedBox(height: 32),

              // Pay Now Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
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
                    ? const CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Pay Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*import 'dart:convert';
import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/utils/global.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../models/jazz_cash_response.dart';
import '../services/api_service.dart';

class JazzCashScreen extends StatefulWidget {
  final int? packageId;
  final String? packageName;
  final String? packagePrice;
  final String? fromProfile;

  final String? doctorId;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? slotNumber;
  final String? fees;

  const JazzCashScreen({
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
  }) : super(key: key);

  @override
  _JazzCashScreenState createState() => _JazzCashScreenState();
}

class _JazzCashScreenState extends State<JazzCashScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  bool _isLoading = false;
  String? transactionDate;
  String? transactionID;
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await callJazzCashApi(
          _cnicController.text.trim(),
          _accountNoController.text.trim(),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> callJazzCashApi(String cnic, String mobileNumber) async {
    //final String securityKey = "0bhsfauwu8";//testing
    final String securityKey = "xtxgbut94c"; //production
    // final String merchantID = "MC55362";//testing
    final String merchantID = "55668833"; //production
    // final String password = "6yy81y93ww";//testing
    final String password = "8y9u1u20zd";//production
    const String description = "pp_Description";
    const String billRef = "billRef";
    const String currency = "PKR";

    String dateTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String expiryDateTime = DateFormat('yyyyMMddHHmmss')
        .format(DateTime.now().add(const Duration(days: 1)));
    String txnRefNo = "T$dateTime";

    //Determine the amount based on the flow
    final double amount;
    if (widget.fees != null) {
      amount = double.parse(widget.fees!);
    } else {
      //amount = double.parse(widget.packagePrice ?? '0');
      amount = double.parse("1" ?? '0');
    }

    final int amountInPaisa = (amount * 100).round();

    String secureHashInput = "$securityKey&"
        "$amountInPaisa&"
        "$billRef&"
        "$cnic&"
        "$description&"
        "EN&"
        "$merchantID&"
        "$mobileNumber&"
        "$password&"
        "$currency&"
        "$dateTime&"
        "$expiryDateTime&"
        "$txnRefNo";

    final key = utf8.encode(securityKey);
    final bytes = utf8.encode(secureHashInput);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final secureHash = digest.toString();

    Map<String, String> body = {
      "pp_Language": "EN",
      "pp_MerchantID": merchantID,
      "pp_SubMerchantID": "",
      "pp_Password": password,
      "pp_DiscountedAmount": "",
      "pp_BankID": "",
      "pp_ProductID": "",
      "pp_TxnRefNo": txnRefNo,
      "pp_Amount": amountInPaisa.toString(),
      "pp_TxnCurrency": currency,
      "pp_TxnDateTime": dateTime,
      "pp_BillReference": billRef,
      "pp_Description": description,
      "pp_TxnExpiryDateTime": expiryDateTime,
      "pp_SecureHash": secureHash,
      "ppmpf_1": "",
      "ppmpf_2": "",
      "ppmpf_3": "",
      "ppmpf_4": "",
      "ppmpf_5": "",
      "pp_MobileNumber": mobileNumber,
      "pp_CNIC": cnic,
    };

    final url = Uri.parse(
        "https://payments.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final jazzCashResponse = JazzCashResponse.fromJson(json);

        if (jazzCashResponse.ppResponseCode == "000") {
          setState(() {

            transactionDate = jazzCashResponse.ppTxnDateTime;
            transactionID = jazzCashResponse.ppTxnRefNo;
          });

          // Determine which API to call based on the presence of doctorId
          if (widget.doctorId != null &&
              widget.appointmentDate != null &&
              widget.appointmentTime != null &&
              widget.slotNumber != null) {
            await _bookSlotAndShowReceipt(jazzCashResponse);
          } else {
            await _activatePackageAndShowReceipt(jazzCashResponse);
          }
        } else {
          _showErrorDialog(
              jazzCashResponse.ppResponseMessage ?? "Payment failed.");
        }
      } else {
        _showErrorDialog("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
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

  Future<void> _activatePackageAndShowReceipt(
      JazzCashResponse jazzCashResponse) async {
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
        packageId: safePackageId,
        paidAmount: safePackagePrice,
        accountNumber: SharedPreferencesManager.getString("mobileNumber") ??
            "Phone Number",
        mobileNumber: SharedPreferencesManager.getString("mobileNumber") ??
            "Phone Number",
        transactionType: "Online",
        transactionReferenceNo: jazzCashResponse.ppTxnRefNo ?? '',
        bank: "JazzCash",
      );

      // Dismiss loading overlay
      Navigator.of(context).pop();

      if (activatePackageResponse != null &&
          activatePackageResponse.responseCode == "0000") {
        // Package activated successfully - Show receipt dialog
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'JazzCash',
          totalPayment: widget.fees ?? widget.packagePrice ?? '',
          transactionId: transactionID ?? '',
          packageName: widget.packageName ?? 'Consultation',
          activatedOn: SharedPreferencesManager.getString("activeDate") ?? 'N/A',
          expiryOn: SharedPreferencesManager.getString("expiryDate") ?? 'N/A',
          onOk: () async {
            await _loginAndNavigate(context);
          },
        );
      } else {
        _showErrorDialog(
            activatePackageResponse?.message ?? "Package activation failed");
      }
    } catch (error) {
      // Dismiss loading overlay
      Navigator.of(context).pop();
      _showErrorDialog("An error occurred: $error");
    }
  }

  Future<void> _bookSlotAndShowReceipt(
      JazzCashResponse jazzCashResponse) async {
    final apiService = ApiService();

    final String? userId = SharedPreferencesManager.getString('id');

    // Activate Package API Call - Show loading overlay
    showLoadingOverlay(context, "Booking Slot...");

    try {
      final bookSlotResponse = await apiService.bookSlot(
        context: context,
        patientId: userId ?? "", // Replace with actual patient ID if available
        doctorId: widget.doctorId!,
       // doctorId: "1f86f06e-1a17-48ea-870a-cad92b23c30d",
        appointmentDate: widget.appointmentDate!,
        //appointmentDate: "2025-04-29",
        appointmentTime: widget.appointmentTime!,
       // appointmentTime: "19:40",
        slotNumber: widget.slotNumber!,
      );

      // Dismiss loading overlay
      Navigator.of(context).pop();

      if (bookSlotResponse != null && bookSlotResponse.statusCode == 1) {
        // Package activated successfully - Show receipt dialog
        String formattedTimeSlot = 'Not Selected';
        if (widget.appointmentTime != null ) {
          try {
            final parsedTime = DateFormat('HH:mm').parse(widget.appointmentTime!);
            formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
          } catch (e) {
            formattedTimeSlot = 'Invalid Time';
            print('Error formatting time: $e');
          }
        }
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'JazzCash',
          totalPayment: widget.fees ?? widget.packagePrice ?? '',
          transactionId: transactionID ?? '',
         // packageName: widget.packageName ?? 'Consultation',
          packageName:  'Appointment Booking',
          activatedOn: widget.appointmentDate!, //set here
          expiryOn: '${widget.appointmentDate} $formattedTimeSlot',
          onOk: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        );
      } else {
        _showErrorDialog((bookSlotResponse?.statusMessage is String)
            ? bookSlotResponse!.statusMessage as String
            : "Slot Booking failed");
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
                    maxWidth: MediaQuery.of(context).size.width * 0.9),
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
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
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
    return Column(
      children: [
        Divider(color: Colors.grey),
        Padding(
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
                  'Date: ${widget.appointmentDate}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Time: ${widget.appointmentTime}',
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
                      'Rs. ${widget.fees}',
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
        ],
      );
    } else if (widget.packageName != null && widget.packagePrice != null) {
      // Package Flow
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
                  widget.packageName!,
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
        ],
      );
    } else {
      return SizedBox.shrink(); // Or display a default message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'JazzCash',
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
              _buildOrderSummary(),

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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _accountNoController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(11)],
                  decoration: const InputDecoration(
                    labelText: 'JazzCash Mobile Number',
                    hintText: 'Enter your 11-digit mobile number',
                    prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _cnicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(6)],
                  decoration: const InputDecoration(
                    labelText: 'CNIC (Last 6 digits)',
                    hintText: 'Enter the last 6 digits of your CNIC',
                    prefixIcon: Icon(Icons.credit_card, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter CNIC (last 6 digits)';
                    if (value.length != 6) return 'CNIC must be 6 digits';
                    return null;
                  },
                ),
              ),
              SizedBox(height: 32),

              // Pay Now Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
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
                    ? const CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Pay Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/



/*

import 'dart:convert';
import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/utils/global.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../models/jazz_cash_response.dart';
import '../services/api_service.dart';

class JazzCashScreen extends StatefulWidget {
  final int packageId;
  final String packageName;
  final String packagePrice;
  final String? fromProfile;

  const JazzCashScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
    this.fromProfile,
  }) : super(key: key);

  @override
  _JazzCashScreenState createState() => _JazzCashScreenState();
}

class _JazzCashScreenState extends State<JazzCashScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  bool _isLoading = false;
  String? transactionDate;
  String? transactionID;
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await callJazzCashApi(
          _cnicController.text.trim(),
          _accountNoController.text.trim(),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> callJazzCashApi(String cnic, String mobileNumber) async {
    //final String securityKey = "0bhsfauwu8";//testing
    final String securityKey = "xtxgbut94c"; //production
   // final String merchantID = "MC55362";//testing
    final String merchantID = "55668833"; //production
   // final String password = "6yy81y93ww";//testing
    final String password = "8y9u1u20zd";//production
    final String description = "pp_Description";
    final String billRef = "billRef";
    final String currency = "PKR";

    String dateTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String expiryDateTime = DateFormat('yyyyMMddHHmmss')
        .format(DateTime.now().add(const Duration(days: 1)));
    String txnRefNo = "T$dateTime";

    // String amount = widget.packagePrice.replaceAll(",", "");
    String amount = "100"; // Use package price

    String secureHashInput = "$securityKey&"
        "$amount&"
        "$billRef&"
        "$cnic&"
        "$description&"
        "EN&"
        "$merchantID&"
        "$mobileNumber&"
        "$password&"
        "$currency&"
        "$dateTime&"
        "$expiryDateTime&"
        "$txnRefNo";

    final key = utf8.encode(securityKey);
    final bytes = utf8.encode(secureHashInput);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final secureHash = digest.toString();

    Map<String, String> body = {
      "pp_Language": "EN",
      "pp_MerchantID": merchantID,
      "pp_SubMerchantID": "",
      "pp_Password": password,
      "pp_DiscountedAmount": "",
      "pp_BankID": "",
      "pp_ProductID": "",
      "pp_TxnRefNo": txnRefNo,
      "pp_Amount": amount,
      "pp_TxnCurrency": currency,
      "pp_TxnDateTime": dateTime,
      "pp_BillReference": billRef,
      "pp_Description": description,
      "pp_TxnExpiryDateTime": expiryDateTime,
      "pp_SecureHash": secureHash,
      "ppmpf_1": "",
      "ppmpf_2": "",
      "ppmpf_3": "",
      "ppmpf_4": "",
      "ppmpf_5": "",
      "pp_MobileNumber": mobileNumber,
      "pp_CNIC": cnic,
    };

    final url = Uri.parse("https://payments.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction");
// "https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final jazzCashResponse = JazzCashResponse.fromJson(json);

        if (jazzCashResponse.ppResponseCode == "000") {
          setState(() {
            transactionDate = jazzCashResponse.ppTxnDateTime;
            transactionID = jazzCashResponse.ppTxnRefNo;
          });
          // Directly call activation and then show receipt in the same function
          await _activatePackageAndShowReceipt(jazzCashResponse);
        } else {
          _showErrorDialog(
              jazzCashResponse.ppResponseMessage ?? "Payment failed.");
        }
      } else {
        _showErrorDialog("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
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

  Future<void> _activatePackageAndShowReceipt(
      JazzCashResponse jazzCashResponse) async {
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
        transactionReferenceNo: jazzCashResponse.ppTxnRefNo ?? '',
        bank: "JazzCash",
      );

      // Dismiss loading overlay
      Navigator.of(context).pop();

      if (activatePackageResponse != null &&
          activatePackageResponse.responseCode == "0000") {
        // Package activated successfully - Show receipt dialog
        await showBookingReceiptDialog(
          context,
          paymentDate: transactionDate ?? '',
          paymentMedium: 'JazzCash',
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
        _showErrorDialog(
            activatePackageResponse?.message ?? "Package activation failed");
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
    return Column(
      children: [
        Divider(color: Colors.grey),
        Padding(
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
          'JazzCash',
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
                  controller: _accountNoController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(11)],
                  decoration: InputDecoration(
                    labelText: 'JazzCash Mobile Number',
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
                  controller: _cnicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(6)],
                  decoration: InputDecoration(
                    labelText: 'CNIC (Last 6 digits)',
                    hintText: 'Enter the last 6 digits of your CNIC',
                    prefixIcon: Icon(Icons.credit_card, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter CNIC (last 6 digits)';
                    if (value.length != 6) return 'CNIC must be 6 digits';
                    return null;
                  },
                ),
              ),
              SizedBox(height: 32),

              // Pay Now Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
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
}







*/
