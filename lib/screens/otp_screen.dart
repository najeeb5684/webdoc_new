

import 'dart:async';
import 'package:Webdoc/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart'; // Import ApiService
import '../theme/app_colors.dart'; // Import AppColors
import '../theme/app_styles.dart'; // Import AppStyles
import 'package:sms_autofill/sms_autofill.dart'; // Import sms_autofill
import 'package:pin_code_fields/pin_code_fields.dart'; // For styled OTP input

// OTP Screen
class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // States
  bool _isLoading = false;
  bool _isResendButtonVisible = false; // To control visibility of resend Button
  int _start = 60; // 1 Minute Timer
  Timer? _timer;
  bool _otpSent = false;
  final ApiService _apiService = ApiService(); // Instance of ApiService
  String? _otpCode;

  //sms auto fill
  String? _appSignature;
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;
  StreamSubscription? _otpSubscription; // To manage the stream subscription

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtp(); // Send OTP when the screen loads
    _getAppSignature();
    _listenForOtp();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    _otpController.dispose();
    SmsAutoFill().unregisterListener();
    _otpSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }

  Future<void> _getAppSignature() async {
    try {
      _appSignature = await SmsAutoFill().getAppSignature;
      print('App Signature: $_appSignature');
    } catch (e) {
      print('Error getting app signature: $e');
    }
  }

  Future<void> _listenForOtp() async {
    try {
      await SmsAutoFill().listenForCode();
      print('Listening for OTP...');

      _otpSubscription = SmsAutoFill().code.listen((code) {
        print("OTP received from SMS: $code");
        if (mounted && !_otpController.isDisposed) {  // Double check!
          setState(() {
            _otpCode = code;
            _otpController.text = code; // Autofill the OTP field
          });
          _verifyOtp(code);
        } else {
          print("Widget is disposed or controller disposed, ignoring OTP: $code");
        }
      });
    } catch (e) {
      print('Error listening for OTP: $e');
    }
  }

  // Timer Function
  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isResendButtonVisible = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).truncate();
    int remainingSeconds = seconds - (minutes * 60);
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Send OTP API Call using ApiService
  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.sendOtp(context, widget.mobileNumber);

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.statusCode == 1) {
      setState(() {
        _otpSent = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(response.statusMessage.join(', '))), // Show message from response
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response?.statusMessage.join(', ') ??
                'Failed to send OTP. Please try again.')),
      );
    }
  }

  // Verify OTP API Call using ApiService
  Future<void> _verifyOtp(String otp) async {
    if (_verifying) return; // Prevent multiple calls
    setState(() {
      _verifying = true;
      _isLoading = true;
    });


    final response =
    await _apiService.verifyOtp(context, widget.mobileNumber, otp);

    setState(() {
      _isLoading = false;
      _verifying = false;
    });

    if (response != null && response.statusCode == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.statusMessage.join(', '))), // Added message
      );
      // Navigate to Registration Screen or whatever's next
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                RegistrationScreen(mobileNumber: widget.mobileNumber)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response?.statusMessage.join(', ') ?? 'Incorrect OTP. Please try again.')),
      );
    }
  }

  // Resend OTP Function
  void _resendOtp() {
    setState(() {
      _isResendButtonVisible = false;
      _start = 60; // Reset Timer to 1 minutes
    });
    _sendOtp();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: false, //Important
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopRightCorner(), // Removed this

              SizedBox(height: 30),

              Text(
                'OTP Verification',
                style: AppStyles.titleLarge(context)
                    .copyWith(color: AppColors.primaryTextColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Text(
                'We have sent you an SMS with a code to this number ${widget.mobileNumber}\nTo complete verification, please enter 6 digit activation code sent on your phone',
                style: AppStyles.bodyMedium(context).copyWith(
                  color: AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),
              // OTP Input using PinCodeFields
              PinCodeTextField(
                appContext: context,
                length: 6,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: screenWidth * 0.11,
                  fieldWidth: screenWidth * 0.11,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: AppColors.primaryColor,
                  activeBorderWidth: 0.5,
                  inactiveBorderWidth: 0.5,
                  inactiveColor: AppColors.primaryTextColor,
                  selectedColor: AppColors.primaryColor,
                ),
                cursorColor: Colors.black,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onCompleted: (code) {
                  print("Completed: $code");
                  setState(() {
                    _otpCode = code;
                  });
                  _verifyOtp(code);
                },
                onChanged: (value) {
                  setState(() {
                    _otpCode = value;
                  });
                },
                beforeTextPaste: (text) {
                  print("Allowing to paste $text");
                  return true;
                },
              ),
              // End OTP Input

              SizedBox(height: 30),

              Visibility(
                visible: !_isResendButtonVisible,
                child: Center(
                  child: Text(
                    'Resend Code in ${_formatTime(_start)}',
                    style: AppStyles.bodyMedium(context)
                        .copyWith(color: AppColors.secondaryTextColor),
                  ),
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (){
                    if(_otpCode!=null){
                      _verifyOtp(_otpCode!);
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter the full OTP.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                      : Text(
                    'Verify',
                    style: AppStyles.bodyMedium(context)
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 30),

              Visibility(
                visible: _isResendButtonVisible,
                child: Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend code',
                      style: AppStyles.bodyMedium(context)
                          .copyWith(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTopRightCorner() {
    return Align(
      alignment: Alignment.topRight,
      child: CustomPaint(
        size: Size(130, 130),
        painter: TopRightCornerPainter(),
      ),
    );
  }
}
class TopRightCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColorLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width, 0), size.width, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
extension on TextEditingController {
  bool get isDisposed => !hasListeners;
}


/*import 'dart:async';
import 'package:Webdoc/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart'; // Import ApiService
import '../theme/app_colors.dart'; // Import AppColors
import '../theme/app_styles.dart'; // Import AppStyles
import 'package:sms_autofill/sms_autofill.dart'; // Import sms_autofill
import 'package:pin_code_fields/pin_code_fields.dart'; // For styled OTP input

// OTP Screen
class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // States
  bool _isLoading = false;
  bool _isResendButtonVisible = false; // To control visibility of resend Button
  int _start = 60; // 1 Minute Timer
  Timer? _timer;
  bool _otpSent = false;
  final ApiService _apiService = ApiService(); // Instance of ApiService
  String? _otpCode;

  //sms auto fill
  String? _appSignature;
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtp(); // Send OTP when the screen loads
    _getAppSignature();
    _listenForOtp();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    _otpController.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  Future<void> _getAppSignature() async {
    try {
      _appSignature = await SmsAutoFill().getAppSignature;
      print('App Signature: $_appSignature');
    } catch (e) {
      print('Error getting app signature: $e');
    }
  }

  Future<void> _listenForOtp() async {
    try {
      await SmsAutoFill().listenForCode();
      print('Listening for OTP...');

      SmsAutoFill().code.listen((code) {
        print("OTP received from SMS: $code");
        setState(() {
          _otpCode = code;
          _otpController.text = code; // Autofill the OTP field
        });
        _verifyOtp(code);
      });
    } catch (e) {
      print('Error listening for OTP: $e');
    }
  }

  // Timer Function
  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isResendButtonVisible = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).truncate();
    int remainingSeconds = seconds - (minutes * 60);
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Send OTP API Call using ApiService
  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.sendOtp(context, widget.mobileNumber);

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.responseCode == '0000') {
      setState(() {
        _otpSent = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(response.message!)), // Show message from response
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response?.message ??
                'Failed to send OTP. Please try again.')),
      );
    }
  }

  // Verify OTP API Call using ApiService
  Future<void> _verifyOtp(String otp) async {
    if (_verifying) return; // Prevent multiple calls
    setState(() {
      _verifying = true;
      _isLoading = true;
    });


    final response =
    await _apiService.verifyOtp(context, widget.mobileNumber, otp);

    setState(() {
      _isLoading = false;
      _verifying = false;
    });

    if (response != null && response.responseCode == '0000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message!)), // Added message
      );
      // Navigate to Registration Screen or whatever's next
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                RegistrationScreen(mobileNumber: widget.mobileNumber)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response?.message ?? 'Incorrect OTP. Please try again.')),
      );
    }
  }

  // Resend OTP Function
  void _resendOtp() {
    setState(() {
      _isResendButtonVisible = false;
      _start = 60; // Reset Timer to 1 minutes
    });
    _sendOtp();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: false, //Important
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopRightCorner(), // Removed this

              SizedBox(height: 30),

              Text(
                'OTP Verification',
                style: AppStyles.titleLarge
                    .copyWith(color: AppColors.primaryTextColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Text(
                'We have sent you an SMS with a code to this number ${widget.mobileNumber}\nTo complete verification, please enter 6 digit activation code sent on your phone',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),
              // OTP Input using PinCodeFields
              PinCodeTextField(
                appContext: context,
                length: 6,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: screenWidth * 0.11,
                  fieldWidth: screenWidth * 0.11,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: AppColors.primaryColor,
                  activeBorderWidth: 0.5,
                  inactiveBorderWidth: 0.5,
                  inactiveColor: AppColors.primaryTextColor,
                  selectedColor: AppColors.primaryColor,
                ),
                cursorColor: Colors.black,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onCompleted: (code) {
                  print("Completed: $code");
                  setState(() {
                    _otpCode = code;
                  });
                  _verifyOtp(code);
                },
                onChanged: (value) {
                  setState(() {
                    _otpCode = value;
                  });
                },
                beforeTextPaste: (text) {
                  print("Allowing to paste $text");
                  return true;
                },
              ),
              // End OTP Input

              SizedBox(height: 30),

              Visibility(
                visible: !_isResendButtonVisible,
                child: Center(
                  child: Text(
                    'Resend Code in ${_formatTime(_start)}',
                    style: AppStyles.bodyMedium
                        .copyWith(color: AppColors.secondaryTextColor),
                  ),
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (){
                    if(_otpCode!=null){
                      _verifyOtp(_otpCode!);
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter the full OTP.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                      : Text(
                    'Verify',
                    style: AppStyles.bodyMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 30),

              Visibility(
                visible: _isResendButtonVisible,
                child: Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend code',
                      style: AppStyles.bodyMedium
                          .copyWith(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTopRightCorner() {
    return Align(
      alignment: Alignment.topRight,
      child: CustomPaint(
        size: Size(130, 130),
        painter: TopRightCornerPainter(),
      ),
    );
  }
}
class TopRightCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColorLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width, 0), size.width, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}*/



/*import 'dart:async';
import 'package:Webdoc/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart'; // Import ApiService
import '../theme/app_styles.dart'; // Import AppStyles

// OTP Screen
class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // OTP Input Fields
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (index) => FocusNode());

  // States
  bool _isLoading = false;
  bool _isResendButtonVisible = false; // To control visibility of resend Button
  int _start = 60; // 1 Minute Timer
  Timer? _timer;
  bool _otpSent = false;
  final ApiService _apiService = ApiService(); // Instance of ApiService

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtp(); // Send OTP when the screen loads
    for (int i = 0; i < _otpFocusNodes.length; i++) {
      final int index = i;
      _otpFocusNodes[i].addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  // Timer Function
  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isResendButtonVisible = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).truncate();
    int remainingSeconds = seconds - (minutes * 60);
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Send OTP API Call using ApiService
  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.sendOtp(context, widget.mobileNumber);

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.responseCode == '0000') {
      setState(() {
        _otpSent = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(response.message!)), // Show message from response
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response?.message ??
                'Failed to send OTP. Please try again.')),
      );
    }
  }

  // Verify OTP API Call using ApiService
  Future<void> _verifyOtp() async {
    String otp = "";
    for (var controller in _otpControllers) {
      otp += controller.text;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response =
    await _apiService.verifyOtp(context, widget.mobileNumber, otp);

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.responseCode == '0000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message!)), // Added message
      );
      // Navigate to Registration Screen or whatever's next
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                RegistrationScreen(mobileNumber: widget.mobileNumber)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response?.message ?? 'Incorrect OTP. Please try again.')),
      );
    }
  }

  // Resend OTP Function
  void _resendOtp() {
    setState(() {
      _isResendButtonVisible = false;
      _start = 120; // Reset Timer to 2 minutes
    });
    _sendOtp();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: false, //Important
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopRightCorner(), // Removed this

              SizedBox(height: 30),

              Text(
                'OTP Verification',
                style: AppStyles.titleLarge
                    .copyWith(color: AppColors.primaryTextColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Text(
                'We have sent you an SMS with a code to this number ${widget.mobileNumber}\nTo complete verification, please enter 6 digit activation code sent on your phone',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                      (index) => SizedBox(
                    width: screenWidth * 0.11,
                    height: screenWidth * 0.11,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      obscureText: false, // Hide OTP
                      style: AppStyles.bodyMedium,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.lightGreyStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14), // Center the text vertically
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            FocusScope.of(context)
                                .requestFocus(_otpFocusNodes[index + 1]);
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        } else {
                          if (index > 0) {
                            FocusScope.of(context)
                                .requestFocus(_otpFocusNodes[index - 1]);
                          }
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),

              Visibility(
                visible: !_isResendButtonVisible,
                child: Center(
                  child: Text(
                    'Resend Code in ${_formatTime(_start)}',
                    style: AppStyles.bodyMedium
                        .copyWith(color: AppColors.secondaryTextColor),
                  ),
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                      : Text(
                    'Verify',
                    style: AppStyles.bodyMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 30),

              Visibility(
                visible: _isResendButtonVisible,
                child: Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend code',
                      style: AppStyles.bodyMedium
                          .copyWith(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTopRightCorner() {
    return Align(
      alignment: Alignment.topRight,
      child: CustomPaint(
        size: Size(130, 130),
        painter: TopRightCornerPainter(),
      ),
    );
  }
}
class TopRightCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColorLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width, 0), size.width, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}*/







/*
import 'dart:async';
import 'package:Webdoc/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/ApiConstants.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart'; // Import ApiService

// OTP Screen
class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // OTP Input Fields
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  // States
  bool _isLoading = false;
  bool _isResendButtonVisible = false; // To control visibility of resend Button
  int _start = 60; // 1 Minute Timer
  Timer? _timer;
  bool _otpSent = false;
  final ApiService _apiService = ApiService(); // Instance of ApiService

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtp(); // Send OTP when the screen loads
    for (int i = 0; i < _otpFocusNodes.length; i++) {
      final int index = i;
      _otpFocusNodes[i].addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  // Timer Function
  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isResendButtonVisible = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).truncate();
    int remainingSeconds = seconds - (minutes * 60);
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Send OTP API Call using ApiService
  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.sendOtp(context, widget.mobileNumber);

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.responseCode == '0000') {
      setState(() {
        _otpSent = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message!)), // Show message from response
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?.message ?? 'Failed to send OTP. Please try again.')),
      );
    }
  }

  // Verify OTP API Call using ApiService
  Future<void> _verifyOtp() async {
    String otp = "";
    for (var controller in _otpControllers) {
      otp += controller.text;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.verifyOtp(context, widget.mobileNumber, otp);

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.responseCode == '0000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message!)), // Added message
      );
      // Navigate to Registration Screen or whatever's next
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationScreen(mobileNumber: widget.mobileNumber)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?.message ?? 'Incorrect OTP. Please try again.')),
      );
    }
  }

  // Resend OTP Function
  void _resendOtp() {
    setState(() {
      _isResendButtonVisible = false;
      _start = 120; // Reset Timer to 2 minutes
    });
    _sendOtp();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, //Important
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final availableHeight = constraints.maxHeight;
            final logoHeight = availableHeight * 0.07;
            final stethoscopeHeight = availableHeight * 0.25;
            final contentHeight = availableHeight -
                logoHeight -
                stethoscopeHeight -
                (availableHeight * 0.12); //Triangle clip path takes 12%

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/pink_corner.png', // Replace with the path to your image
                    width: screenWidth * 0.35,
                    height: screenHeight * 0.12,
                    fit: BoxFit.fill, // Ensure the image fills the container
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: availableHeight * 0.05),
                    Image.asset(
                      'assets/images/otp_back.png',
                      height: logoHeight,
                    ),
                    SizedBox(height: availableHeight * 0.04),
                    Container(
                      width: constraints.maxWidth * 0.9,
                      height: contentHeight * 0.9, //Give it some margin
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'OTP Verification',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We have sent you an SMS with a code to this number ${widget.mobileNumber}\nTo complete verification, please enter 6 digit activation code sent on your phone',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                6,
                                    (index) => SizedBox(
                                  width: constraints.maxWidth * 0.11,
                                  height: constraints.maxWidth * 0.11,
                                  child: TextFormField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    obscureText: false, // Hide OTP
                                    style: const TextStyle(fontSize: 16),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                        const BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                        const BorderSide(color: Colors.blue),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14), // Center the text vertically
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        if (index < 5) {
                                          FocusScope.of(context).requestFocus(
                                              _otpFocusNodes[index + 1]);
                                        } else {
                                          FocusScope.of(context).unfocus();
                                        }
                                      } else {
                                        if (index > 0) {
                                          FocusScope.of(context).requestFocus(
                                              _otpFocusNodes[index - 1]);
                                        }
                                      }
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: _isLoading
                                    ? Center( // Wrap the CircularProgressIndicator with Center
                                  child: SizedBox( // Explicitly define the size
                                    height: 24, // Adjust as needed
                                    width: 24,  // Adjust as needed
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                    : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Visibility(
                              visible: _isResendButtonVisible,
                              child: TextButton(
                                onPressed: _isLoading ? null : _resendOtp,
                                child: const Text(
                                  'Resend code',
                                  style: TextStyle(color: AppColors.primaryColor),
                                ),
                              ),
                            ),
                            if (!_isResendButtonVisible)
                              Text(
                                'Resend Code in ${_formatTime(_start)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: availableHeight * 0.01),
                    Image.asset(
                      'assets/images/stethoscope.png',
                      height: stethoscopeHeight,
                    ),
                    SizedBox(height: availableHeight * 0.02),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
*/


