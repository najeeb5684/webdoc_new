import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/screens/payment_screen.dart';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import '../services/api_service.dart'; // Import your ApiService

class GenericPaymentGatewayScreen extends StatefulWidget {
  final int packageId;
  final String packageName;
  final String packagePrice;
  final String bankName;
  final String? paymentUrl; // e.g., 'alfalahDc', 'alfalahAc', 'alfalahWl', or null for JazzCash/EasyPaisa
  final String? fromScreen; // Optional: To know where navigation should go after success

  const GenericPaymentGatewayScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
    required this.bankName,
    this.paymentUrl, // Can be null
    this.fromScreen, // Add this field
  }) : super(key: key);

  @override
  State<GenericPaymentGatewayScreen> createState() =>
      _GenericPaymentGatewayScreenState();
}

class _GenericPaymentGatewayScreenState
    extends State<GenericPaymentGatewayScreen> {
  late final WebViewController _controller;
  double _loadingPercentage = 0.0; // For linear progress bar
  bool _isLoadingWebView = true; // Initial loading state
  bool _isApiLoading = false; // Loading state for API calls after payment
  bool _apiCallMade = false; // Flag to prevent duplicate API calls
  late String _orderId; // Generated order ID

  // Payment success/failure URL patterns to listen for
  // These need to match the actual URLs your gateway redirects to!
  // Use lower case for comparison as URLs are case-insensitive in domain/path part
  static const String _successUrlPattern =
      'successpayment/00'; // Based on Kotlin: merchatns.bankalfalah.com/Payments/Payments/SuccessPayment/00
  static const String _failureUrlPattern1 =
      '?rc='; // Based on Kotlin: www.webdoc.com.pk/?RC (compare lowercase)
  static const String _failureUrlPattern2 =
      '/sso/invalidrequest'; // Based on Kotlin (compare lowercase)
  static const String _initialLoadPattern =
      'portal.webdoc.com.pk/transection/a/webdoc.php'; // Pattern for the initial page loading

  @override
  void initState() {
    super.initState();

    // Generate Order ID (timestamp based)
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmmss');
    _orderId = formatter.format(now);

    // Determine the initial URL based on the payment method
    String initialUrl = '';
    if (widget.paymentUrl == 'alfalahAc') {
      initialUrl =
      "https://portal.webdoc.com.pk/transection/A/webdoc.php?orderid=$_orderId&amount=${widget.packagePrice}&id=2"; // ID 2 for Account
    } else if (widget.paymentUrl == 'alfalahWl') {
      initialUrl =
      "https://portal.webdoc.com.pk/transection/A/webdoc.php?orderid=$_orderId&amount=${widget.packagePrice}&id=1"; // ID 1 for Wallet
    } else if (widget.paymentUrl == 'alfalahDc') {
      initialUrl =
      "https://portal.webdoc.com.pk/transection/A/webdoc.php?orderid=$_orderId&amount=${widget.packagePrice}&id=3"; // ID 3 for Debit/Credit Card
    } else {
      // Handle other payment methods (JazzCash, EasyPaisa) if they don't use a WebView this way
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payment method not supported via WebView')),
        );
        // Use pop to go back to the previous screen (PaymentScreen)
        Navigator.of(context).pop();
      });
      // We return here as there's no URL to load the WebView with
      return;
    }

    // Initialize the WebView controller parameters
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    // Configure controller settings and navigation delegate (cross-platform)
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(Colors.white) // Set white background
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingPercentage = progress / 100.0;
              if (_loadingPercentage > 0 && _isLoadingWebView) {
                _isLoadingWebView = false;
              }
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _loadingPercentage = 0.0;
              if (url.toLowerCase().contains(_initialLoadPattern.toLowerCase())) {
                _isLoadingWebView = true;
              } else {
                _isLoadingWebView = false;
              }
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _loadingPercentage = 1.0;
              _isLoadingWebView = false;
            });

            final lowerCaseUrl = url.toLowerCase();

            if (lowerCaseUrl.contains(_successUrlPattern)) {
              if (!_apiCallMade) {
                setState(() {
                  _apiCallMade = true;
                }); // Set flag immediately
                _handlePaymentSuccess();
              }
            } else if (lowerCaseUrl.contains(_failureUrlPattern1) ||
                lowerCaseUrl.contains(_failureUrlPattern2)) {
              if (!_apiCallMade) {
                setState(() {
                  _apiCallMade = true;
                });
                _handlePaymentFailure('Payment failed or cancelled.');
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            if ((error.isForMainFrame ?? true) && !_apiCallMade) {
              setState(() {
                _apiCallMade = true;
              });
              _handlePaymentFailure(
                  'Webpage error: ${error.description} (Code: ${error.errorCode})');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl)); // Load the initial URL

    _controller = controller;

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      try {
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      } catch (e) {
        debugPrint('Could not set Android WebView specific settings: $e');
      }
    }
  }

  Future<void> _handlePaymentSuccess() async {
    _showApiLoadingDialog("Activating Package..."); // Show loading overlay

    final patientId = SharedPreferencesManager.getString('id');
    final mobileNumber = SharedPreferencesManager.getString('phoneNo');
    final pin = SharedPreferencesManager.getString('pin');

    if (patientId == null || mobileNumber == null || pin == null) {
      _hideApiLoadingDialog();
      _showErrorDialog(
          "User data not found. Please login again."); // Use showErrorDialog
      return;
    }

    try {
      final activatePackageResponse = await ApiService().activatePackage(
          context: context,
          user_id: SharedPreferencesManager.getString("id") ??
              "ID",
          packageId:widget.packageId.toString()
      );

      _hideApiLoadingDialog();

      if (activatePackageResponse != null &&
          activatePackageResponse.statusCode == 1) {
        // Call login API after successful activation
        _showApiLoadingDialog("Logging In..."); // Update loading message
        final loginResponse = await ApiService().login(context, mobileNumber, pin);
        _hideApiLoadingDialog();

        if (loginResponse != null && loginResponse.statusCode == 1) {
          SharedPreferencesManager.putBool(
              'isPackageActivated', loginResponse.payLoad?.user?.isPackageActivated ?? false);
          SharedPreferencesManager.putString(
              "expiryDate", loginResponse.payLoad?.user?.expiryDate ?? 'N/A');
          SharedPreferencesManager.putString(
              "activeDate", loginResponse.payLoad?.user?.activeDate ?? 'N/A');
          SharedPreferencesManager.putString(
              "PackageName", loginResponse.payLoad?.user?.packageName ?? 'N/A');
          _showBookingReceiptDialog(
            paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            paymentMedium: widget.bankName,
            totalPayment: widget.packagePrice,
            transactionId: _orderId,
            packageName: widget.packageName,
            activatedOn: SharedPreferencesManager.getString("activeDate") ?? 'N/A',
            expiryOn: SharedPreferencesManager.getString("expiryDate") ?? 'N/A',
            onOk: () {
              _navigateToDashboard(); // Navigate to dashboard
            },
          );
        } else {
          String errorMessage = "Package activated, but failed to refresh user status.";

          // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

          errorMessage = loginResponse!.statusMessage!.join(', ');
          _showErrorDialog(errorMessage);
        }
      } else {
        String errorMessage = "Package activation failed";

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

        errorMessage = activatePackageResponse!.statusMessage!.join(', ');
        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      _hideApiLoadingDialog();
      _showErrorDialog("An error occurred: $error"); // Use showErrorDialog
    }
  }

  void _handlePaymentFailure(String message) {
    _hideApiLoadingDialog();
    _showErrorDialog(message); // Use showErrorDialog
  }

  //Helper function to show error screen
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
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => PaymentScreen(packageId: widget.packageId, packageName: widget.packageName, packagePrice: widget.packagePrice))); // Go to dashboard
              },
            ),
          ],
        );
      },
    );
  }

  //Helper function for login and navigate
  Future<void> _navigateToDashboard() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }

  //Helper function to show loading screen
  void _showApiLoadingDialog(String text) {
    if (!_isApiLoading) {
      // Prevent showing multiple dialogs
      setState(() {
        _isApiLoading = true;
      });
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
  }

  void _hideApiLoadingDialog() {
    if (_isApiLoading) {
      setState(() {
        _isApiLoading = false;
      });
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _showBookingReceiptDialog({
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
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width *
                      0.9), // Increased width
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

  @override
  Widget build(BuildContext context) {
    if (widget.paymentUrl == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Error')),
        body: const Center(
          child: Text('Invalid payment method selected.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Set white background
      appBar: AppBar(
        title: Text('${widget.bankName} Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Builder(builder: (BuildContext context) {
            return Visibility(
              visible: !_isLoadingWebView, // Show WebView when loading is complete
              child: WebViewWidget(controller: _controller),
            );
          }),
          if (_loadingPercentage > 0 && _loadingPercentage < 1.0)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                value: _loadingPercentage,
                backgroundColor: Colors.grey[300],
                valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.blue), // Use your app's theme color
              ),
            ),
          if (_isLoadingWebView)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

/*
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:intl/intl.dart'; // Needed for date formatting

import '../services/api_service.dart'; // Import your ApiService

class BookingDetails {
  final String doctorId;
  final String appointmentDate; // yyyy-MM-dd
  final String appointmentTime; // HH:mm
  final String slotNumber; // String
  final String? fromScreen; // Optional: To know where navigation should go after success

  BookingDetails({
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.slotNumber,
    this.fromScreen, // Add this field
  });
}

class GenericPaymentGatewayScreen extends StatefulWidget {
  final int packageId;
  final String packageName;
  final String packagePrice;
  final String bankName;
  final String? paymentUrl; // e.g., 'alfalahDc', 'alfalahAc', 'alfalahWl', or null for JazzCash/EasyPaisa
  final BookingDetails? bookingDetails; // Pass this if booking a slot
  final String? fromScreen; // Optional: To know where navigation should go after success (for package activation)


  const GenericPaymentGatewayScreen({
    Key? key,
    required this.packageId,
    required this.packageName,
    required this.packagePrice,
    required this.bankName,
    this.paymentUrl, // Can be null
    this.bookingDetails, // Can be null
    this.fromScreen, // Add this field
  }) : super(key: key);

  @override
  State<GenericPaymentGatewayScreen> createState() =>
      _GenericPaymentGatewayScreenState();
}

class _GenericPaymentGatewayScreenState
    extends State<GenericPaymentGatewayScreen> {
  late final WebViewController _controller;
  double _loadingPercentage = 0.0; // For linear progress bar
  bool _isLoadingWebView = true; // Initial loading state
  bool _isApiLoading = false; // Loading state for API calls after payment
  bool _apiCallMade = false; // Flag to prevent duplicate API calls
  late String _orderId; // Generated order ID

  // Payment success/failure URL patterns to listen for
  // These need to match the actual URLs your gateway redirects to!
  // Use lower case for comparison as URLs are case-insensitive in domain/path part
  static const String _successUrlPattern = 'successpayment/00'; // Based on Kotlin: merchatns.bankalfalah.com/Payments/Payments/SuccessPayment/00
  static const String _failureUrlPattern1 = '?rc='; // Based on Kotlin: www.webdoc.com.pk/?RC (compare lowercase)
  static const String _failureUrlPattern2 = '/sso/invalidrequest'; // Based on Kotlin (compare lowercase)
  static const String _initialLoadPattern = 'portal.webdoc.com.pk/transection/a/webdoc.php'; // Pattern for the initial page loading

  @override
  void initState() {
    super.initState();

    // Generate Order ID (timestamp based)
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmmss');
    _orderId = formatter.format(now);

    // Determine the initial URL based on the payment method
    String initialUrl = '';
    if (widget.paymentUrl == 'alfalahAc') {
      initialUrl =
      "https://portal.webdoc.com.pk/transection/A/webdoc.php?orderid=$_orderId&amount=${widget.packagePrice}&id=2"; // ID 2 for Account
    } else if (widget.paymentUrl == 'alfalahWl') {
      initialUrl =
      "https://portal.webdoc.com.pk/transection/A/webdoc.php?orderid=$_orderId&amount=${widget.packagePrice}&id=1"; // ID 1 for Wallet
    } else if (widget.paymentUrl == 'alfalahDc') {
      initialUrl =
      "https://portal.webdoc.com.pk/transection/A/webdoc.php?orderid=$_orderId&amount=${widget.packagePrice}&id=3"; // ID 3 for Debit/Credit Card
    } else {
      // Handle other payment methods (JazzCash, EasyPaisa) if they don't use a WebView this way
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method not supported via WebView')),
        );
        // Use pop to go back to the previous screen (PaymentScreen)
        Navigator.of(context).pop();
      });
      // We return here as there's no URL to load the WebView with
      return;
    }

    // Initialize the WebView controller parameters
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
      // Android-specific settings (like mixed content) are often set on the controller
      // instance itself after creation, or via a custom Android view client if needed.
      // We will attempt to set mixed content mode below if the controller is Android.
    } else if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params =  WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        // allowsBackForwardNavigationGestures: true, // Set here if needed
      );
    } else {
      // Default params for other platforms (Linux, Windows, etc.)
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    // Configure controller settings and navigation delegate (cross-platform)
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
            debugPrint('WebView loading: $progress%');
            setState(() {
              _loadingPercentage = progress / 100.0;
              // Hide initial loading indicator once progress starts
              if (_loadingPercentage > 0 && _isLoadingWebView) {
                _isLoadingWebView = false;
              }
            });
          },
          onPageStarted: (String url) {
            // Page started loading, show loading indicator
            debugPrint('Page started loading: $url');
            setState(() {
              _loadingPercentage = 0.0; // Reset progress
              // Only show initial loading if we are navigating to the actual payment page,
              // not if it's a very quick internal redirect.
              if(url.toLowerCase().contains(_initialLoadPattern.toLowerCase())) {
                _isLoadingWebView = true;
              } else {
                // For subsequent redirects, just rely on the linear progress bar
                _isLoadingWebView = false;
              }
            });
          },
          onPageFinished: (String url) async {
            // Page finished loading, hide loading indicator
            debugPrint('Page finished loading: $url');
            setState(() {
              _loadingPercentage = 1.0; // Set progress to full
              _isLoadingWebView = false; // Hide loading indicator
            });

            // Check if this is a success or failure redirect URL
            // Use toLowerCase() for case-insensitive comparison of URL parts
            final lowerCaseUrl = url.toLowerCase();

            if (lowerCaseUrl.contains(_successUrlPattern)) {
              debugPrint('Payment Success URL detected!');
              // Prevent calling API multiple times if WebView redirects again
              if (!_apiCallMade) {
                setState(() { _apiCallMade = true; }); // Set flag immediately
                _handlePaymentSuccess();
              }
            } else if (lowerCaseUrl.contains(_failureUrlPattern1) || lowerCaseUrl.contains(_failureUrlPattern2)) {
              debugPrint('Payment Failure URL detected!');
              // Prevent showing multiple failure messages/navigations
              if (!_apiCallMade) { // Use the same flag to prevent multiple failure handlers
                setState(() { _apiCallMade = true; }); // Set flag
                _handlePaymentFailure('Payment failed or cancelled.');
              }
            }
            // For other URLs, the WebView just continues loading
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            // Optionally show an error message to the user
            // Check if it's a critical error for the main frame and not already handled
            if ((error.isForMainFrame ?? true) && !_apiCallMade) { // Added null check for isForMainFrame
              setState(() { _apiCallMade = true; }); // Set flag
              _handlePaymentFailure('Webpage error: ${error.description} (Code: ${error.errorCode})');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Allowing navigation to ${request.url}');
            return NavigationDecision.navigate; // Allow all navigation requests
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl)); // Load the initial URL

    _controller = controller;

    // Platform-specific post-creation setup
    if (controller.platform is AndroidWebViewController) {
      // Enable debugging if needed (can be removed for release)
      AndroidWebViewController.enableDebugging(true);
      // Attempt to set mixed content mode after the controller is created
      // This method might not be available in all v4+ minor versions.
      // If this line causes an error, you might need a different approach
      // or rely on default browser behavior + server configuration.
      try {
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false); // Example of another setter
        // Check docs for mixed content mode setter if needed:
        // (controller.platform as AndroidWebViewController).setMixedContentMode(AndroidViewControllerMixedContentMode.alwaysAllow);
        // If the line above gave error, the setter might be gone or renamed.
        // You might need to handle mixed content by intercepting requests
        // or using a custom Android WebView configuration outside the plugin.
      } catch (e) {
        debugPrint('Could not set Android WebView specific settings: $e');
      }
    }
    // allowsBackForwardNavigationGestures is set in WebKitWebViewControllerCreationParams
  }


  Future<void> _handlePaymentSuccess() async {
    // Show API loading indicator
    _showApiLoadingDialog();

    // Retrieve required user data from SharedPreferences

    final patientId = SharedPreferencesManager.getString('id'); // Assuming 'id' is patientId
    final mobileNumber = SharedPreferencesManager.getString('phoneNo');
    final pin = SharedPreferencesManager.getString('pin');


    if (patientId == null || mobileNumber == null || pin == null) {
      // Handle missing user data - this is a critical error
      _hideApiLoadingDialog();
      _showMessageDialog(
          title: 'Error',
          message: 'User data not found for API calls. Please log in again.',
          isSuccess: false,
          onOk: () {
            // Navigate to login or handle appropriately
            // Example: Go back to root (assuming login is near root)
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
      );
      return;
    }


    if (widget.bookingDetails != null) {
      // It's a slot booking
      final details = widget.bookingDetails!;
      final response = await ApiService().bookSlot(
        context: context,
        patientId: patientId,
        doctorId: details.doctorId,
        appointmentDate: details.appointmentDate,
        appointmentTime: details.appointmentTime,
        slotNumber: details.slotNumber,
      );

      _hideApiLoadingDialog();

      if (response != null && response.statusCode == 1) { // Assuming status code 1 means success
        _showBookingReceiptDialog(
          date: response.payLoad?.appointmentDate ?? details.appointmentDate,
          time: response.payLoad?.appointmentTime ?? details.appointmentTime,
          transactionId: _orderId, // Using the generated orderId for the receipt
          isBooking: true,
          fromScreen: details.fromScreen, // Pass navigation info
        );
        // TODO: Implement Notification Scheduling using flutter_local_notifications
        // scheduleNotification(details.appointmentDate, details.appointmentTime);
      } else {
        _handlePaymentFailure(response?.statusMessage?.join('\n') ?? 'Failed to book slot.');
      }

    } else {
      // It's a package activation
      final response = await ApiService().activatePackage(
        context: context,
        packageId: widget.packageId,
        paidAmount: widget.packagePrice,
        accountNumber: mobileNumber, // Assuming account number is mobile number based on curl
        mobileNumber: mobileNumber,
        transactionType: 'Online', // Based on Kotlin code
        transactionReferenceNo: _orderId, // Use the generated orderId
        bank: widget.bankName, // Use the bank name from args
      );

      _hideApiLoadingDialog();

      // Assuming '0000' is success code for ActivatePackage based on curl response structure
      if (response != null && response.responseCode == '0000') {
        // Call login API after successful activation (as in Kotlin)
        _showApiLoadingDialog();
        final loginResponse = await ApiService().login(context, mobileNumber, pin);
        _hideApiLoadingDialog();

        // Assuming '0000' is success code for Login
        if (loginResponse != null && loginResponse.responseCode == '0000') {
          // Update package status in SharedPreferences
          SharedPreferencesManager.putBool('isPackageActivated', loginResponse.loginData?.isPackageActivated ?? false);
          // Update other user data if necessary
          _showBookingReceiptDialog(
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()), // Use current date for package activation receipt
            time: DateFormat('HH:mm').format(DateTime.now()), // Use current time
            transactionId: _orderId,
            isBooking: false,
            fromScreen: widget.fromScreen, // Pass navigation info
          );
        } else {
          // Even if login fails, activation might be successful.
          // Decide if you show activation success then alert about login refresh failure,
          // or treat the whole flow as failed if login fails.
          // Current approach: Alert about login refresh failure.
          _showMessageDialog(
            title: 'Activation Success, Info Refresh Failed',
            message: loginResponse?.message ?? 'Package activated, but failed to refresh user status. Please re-login.',
            isSuccess: true, // Activation was success, but login refresh failed
            onOk: () {
              // Navigate based on original intent (package activation)
              _navigateAfterSuccess(false, widget.fromScreen);
            },
          );
        }

      } else {
        _handlePaymentFailure(response?.message ?? 'Failed to activate package.');
      }
    }
  }

  void _handlePaymentFailure(String message) {
    // Hide any loading indicators
    _hideApiLoadingDialog();
    // Show a failure message dialog
    _showMessageDialog(
        title: 'Payment Failed',
        message: message,
        isSuccess: false,
        onOk: () {
          // Navigate back to the payment options or previous screen
          // Go back to the PaymentScreen
          Navigator.of(context).pop();
          // Consider if you need to navigate further back if the failure
          // invalidates the entire flow.
        }
    );
  }


  // Custom Loading Dialog for API calls
  void _showApiLoadingDialog() {
    if (!_isApiLoading) { // Prevent showing multiple dialogs
      setState(() { _isApiLoading = true; });
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing by tapping outside
        builder: (BuildContext context) {
          return  AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min, // <-- Corrected from .size to .min
              children: const [ // <-- Added const for potential optimization
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Processing payment result...", textAlign: TextAlign.center,),
              ],
            ),
          ); // <-- Corrected brackets here
        },
      );
    }
  }

    void _hideApiLoadingDialog() {
      if (_isApiLoading) {
        setState(() { _isApiLoading = false; });
        // Check if the loading dialog is currently shown before popping
        // This prevents errors if called when dialog isn't active
        // Use rootNavigator: true to ensure we pop the dialog on the root stack
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    // Custom Booking/Activation Receipt Dialog
    void _showBookingReceiptDialog({
      required String date,
      required String time,
      required String transactionId,
      required bool isBooking, // true for booking, false for package activation
      String? fromScreen, // Info about where to navigate from
    }) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset( // Assuming a success icon image exists
                    'assets/images/success_icon.png', // Replace with your actual success icon path
                    height: 60,
                    width: 60,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isBooking ? 'Appointment Booked Successfully' : 'Package Activated Successfully',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Or a suitable success color
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildReceiptRow('Date:', date),
                  if(isBooking) _buildReceiptRow('Time:', time), // Show time only for booking
                  _buildReceiptRow('Payment Medium:', widget.bankName),
                  _buildReceiptRow('Reference No:', transactionId),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _navigateAfterSuccess(isBooking, fromScreen); // Navigate based on success type and origin
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Use your app's primary color
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Helper function to build a receipt row
    Widget _buildReceiptRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start, // Align text nicely
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(width: 8), // Add a small space
            Expanded( // Use Expanded instead of Flexible if you want it to take remaining space
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }


    // Generic Message Dialog (for failure or other messages)
    void _showMessageDialog({
      required String title,
      required String message,
      required bool isSuccess,
      required VoidCallback onOk,
    }) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog first
                    onOk(); // Execute the provided OK action (e.g., navigate)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.blue : Colors.redAccent, // Use appropriate color
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          );
        },
      );
    }

    // Helper function to handle navigation after a successful transaction
    void _navigateAfterSuccess(bool isBooking, String? fromScreen) {
      // This is where you replicate the Kotlin navigation logic based on 'Global.fromProfile'
      // You passed this information via bookingDetails.fromScreen or widget.fromScreen

      if (isBooking) {
        // Navigation after successful booking
        if (fromScreen == "specialprofile") {
          // Navigate back to Special Doctors Tab, set flags etc.
          // You need to define your navigation routes.
          // Example: pop this screen, then pop the previous screen, then push the new screen
          // Navigator.of(context).pop(); // Pop GenericPaymentGatewayScreen is already done by dialog close
          // Navigator.of(context).pop(); // Pop the screen that launched this one (e.g., DoctorProfile/Slot selection)
          // Assuming you have named routes or a navigation service:
          // Navigator.pushNamedAndRemoveUntil(context, '/specialDoctorsTabs', (route) => route.isFirst); // Example for named route
          // Or just pop back to a known point:
          // Replace '/specialDoctorsTabsRouteName' with your actual route name
          Navigator.popUntil(context, ModalRoute.withName('/specialDoctorsTabsRouteName'));
        } else {
          // Handle other booking scenarios if any
          Navigator.of(context).popUntil((route) => route.isFirst); // Go back to root/dashboard
        }
      } else {
        // Navigation after successful package activation
        if (fromScreen == "profile") {
          // Replace '/doctorProfileRouteName' with your actual route name
          Navigator.popUntil(context, ModalRoute.withName('/doctorProfileRouteName'));
        } else if (fromScreen == "dashboard") {
          Navigator.of(context).popUntil((route) => route.isFirst); // Go back to root/dashboard
        } else if (fromScreen == "list") {
          // Replace '/doctorListRouteName' with your actual route name
          Navigator.popUntil(context, ModalRoute.withName('/doctorListRouteName'));
        } else {
          // Default navigation after activation
          Navigator.of(context).popUntil((route) => route.isFirst); // Go back to root/dashboard
        }
      }
      // You might need to set global flags or state here similar to Kotlin Global variables
      // Global.fromProfile = "";
      // Global.showbooked = "show"; // If booking
      // Global.bookedList.clear(); // If booking
    }


    // TODO: Implement Notification Scheduling using flutter_local_notifications
    // void scheduleNotification(String date, String time) {
    //   // Use flutter_local_notifications package here
    //   // Parse date and time, calculate scheduled time, and use plugin API
    //   // Refer to flutter_local_notifications documentation
    //   debugPrint("Scheduling notification for $date at $time (NOT IMPLEMENTED)");
    // }


    @override
    Widget build(BuildContext context) {
      // Handle cases where the payment method was invalid and initState popped
      // This check might be redundant if initState correctly navigates away,
      // but serves as a fallback.
      if (widget.paymentUrl == null && widget.bookingDetails == null) {
        // This code might not be reached if initState pops the screen.
        // Consider showing an error state here if initState doesn't pop.
        return Scaffold(
          appBar: AppBar(title: const Text('Payment Error')),
          body: const Center(
            child: Text('Invalid payment method selected.'),
          ),
        );
      }

      // If initState returned early because paymentUrl was null,
      // the controller might not be initialized.
      // Add a check or ensure build isn't called in that case.
      // Assuming for valid URLs, _controller is always initialized.

      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.bankName} Payment'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Stack( // Use Stack to overlay loading indicators on the WebView
          children: [
            // The WebView
            // Use a Builder to get a context below the Scaffold for the WebView,
            // although it's often not strictly necessary for basic WebViewWidget.
            Builder(
                builder: (BuildContext context) {
                  return WebViewWidget(controller: _controller);
                }
            ),


            // Linear Progress Indicator at the top
            // Show while loading progress is less than 100% and not in initial loading state
            if (_loadingPercentage > 0 && _loadingPercentage < 1.0)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: _loadingPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), // Use your app's theme color
                ),
              ),

            // Initial Loading Indicator (Centered)
            if (_isLoadingWebView) // Show initially before progress starts
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Note: API loading dialog handles its own overlay, so no need for a Stack layer here.
          ],
        ),
      );
    }

    // Clean up the webview controller when the widget is removed
    @override
    void dispose() {
      // Dispose the controller if needed. In newer versions, automatic cleanup
      // might handle this, but explicitly clearing resources is safer.
      // WebViewController doesn't have a public dispose/destroy.
      // You might need platform-specific code or rely on garbage collection.
      // For example, you could call platform-specific destroy if you had access:
      // if (_controller.platform is AndroidWebViewController) {
      //    (_controller.platform as AndroidWebViewController).destroy(); // Doesn't exist publicly
      // }
      super.dispose();
    }
  }*/
