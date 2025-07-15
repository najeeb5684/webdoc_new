

import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models/registration_response.dart';
import '../models/reset_password_response.dart';
import '../models/user_check_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_theme.dart';

import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'otp_screen.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String mobileNumber;

  const RegistrationScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String phoneNumber = '';
  String countryCode = '+92'; // Default to Pakistan
  String password = '';
  String userName = '';

  final double textFieldHeight = 50.0;

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _nameErrorText;
  String? _passwordErrorText;
  bool _isLoading = false;

  final ApiService _apiService = ApiService(); // Instance of ApiService


  @override
  void initState() {
    super.initState();
    _phoneNumberController.text = widget.mobileNumber;
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    setState(() {
      _nameErrorText = null;
      _passwordErrorText = null;
    });

    final name = _userNameController.text.trim();
    final password = _passwordController.text.trim();

    if (Global.forgetPin != "forget" && name.isEmpty) {
      setState(() {
        _nameErrorText = 'Name is required';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordErrorText = 'Password is required';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    ChangePasswordResponse? response;
    RegistrationResponse? registerResponse;
    if (Global.forgetPin == "forget") {
      response = await _apiService.resetPassword(context, widget.mobileNumber, password);

      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        if (response.statusCode == 1) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((response.statusMessage?.toString() ?? 'Operation failed. Please try again.'))),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation failed. Please try again.')),
        );
      }
    } else {
      registerResponse = await _apiService.registerUser(context, widget.mobileNumber, name, password,'${widget.mobileNumber}@webdoc.com.pk');

      setState(() {
        _isLoading = false;
      });

      if (registerResponse != null) {
        if (registerResponse.statusCode == 1) {

          // Save UserID in shared preferences
          await SharedPreferencesManager.putString('id', registerResponse.payLoad?.applicationUserId ?? '');
          await SharedPreferencesManager.putString('mobileNumber', widget.mobileNumber);
          await SharedPreferencesManager.putString('name', name);
          await SharedPreferencesManager.putString('pin', password); // Save Pin

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          //Navigate to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((registerResponse.statusMessage?.toString() ?? 'Operation failed. Please try again.'))),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation failed. Please try again.')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return WillPopScope( // Prevent back button from dismissing
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppColors.primaryColorLight,
            title: const Text("Password Reset Successful"),
            content: const Text("Your password has been reset successfully."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                //  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                  );
                  Global.forgetPin = ""; // Reset global forget pin
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopRightCorner(),
                SizedBox(height: 30),
                Text(
                  Global.forgetPin == "forget" ? 'Reset Password' : 'Sign Up',
                  style: AppStyles.titleLarge(context)
                      .copyWith(color: AppColors.primaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                if (Global.forgetPin != "forget") _buildUserNameTextField(),
                if (Global.forgetPin != "forget") SizedBox(height: 20),
                _buildPhoneNumberTextField(),
                SizedBox(height: 20),
                _buildPasswordTextField(),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
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
                    Global.forgetPin == "forget" ? 'Set Password' : 'Sign Up',
                    style: AppStyles.bodyMedium(context)
                        .copyWith(color: Colors.white),
                  ),
                ),

                SizedBox(height: 30),

                //  "Have an Account? Log In" is shown only when Global.forgetPin is NOT "forget"
                if (Global.forgetPin != "forget")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Have an Account? ", style: AppStyles.bodyMedium(context)),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                          child: Text(
                            'Log In',
                            style: AppStyles.bodyMedium(context)
                                .copyWith(color: AppColors.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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

  Widget _buildUserNameTextField() {
    return Column( // Wrap the existing code with a Column
      crossAxisAlignment: CrossAxisAlignment.start, // Align to left

      children: [
        SizedBox(
          height: textFieldHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.lightGreyStroke,
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: _userNameController,
                keyboardType: TextInputType.name,
                style: AppStyles.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'User Name',
                  hintStyle: AppStyles.bodyMedium(context).copyWith(
                      color: AppColors.secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14), //Adjust the vertical alignment here
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.iconColor,
                  ),

                ),
                onChanged: (value) {
                  setState(() {
                    userName = value;
                  });
                },
              ),
            ),
          ),
        ),
        if (_nameErrorText != null)  // Show the error text only if it is not null
          Padding(
            padding: const EdgeInsets.only(left: 12.0),  // Add horizontal padding here to match prefixIcon
            child: Text(
              _nameErrorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        SizedBox(height: 8), // Adjust height as needed for error message

      ],
    );
  }
  Widget _buildPhoneNumberTextField() {
    return Column( // Wrap the existing code with a Column
      crossAxisAlignment: CrossAxisAlignment.start, // Align to left

      children: [
        SizedBox(
          height: textFieldHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.lightGreyStroke,
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                enabled: false,
                style: AppStyles.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: AppStyles.bodyMedium(context).copyWith(
                      color: AppColors.secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14), //Adjust the vertical alignment here
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppColors.iconColor,
                  ),

                ),
                onChanged: (value) {
                  setState(() {
                    phoneNumber = value;
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 8),  // <-- ADD THIS LINE HERE
      ],
    );
  }
  Widget _buildPasswordTextField() {
    return Column( // Wrap the existing code with a Column
      crossAxisAlignment: CrossAxisAlignment.start, // Align to left

      children: [
        SizedBox(
          height: textFieldHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.lightGreyStroke,
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppStyles.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'Set Password',
                  hintStyle: AppStyles.bodyMedium(context).copyWith(
                      color: AppColors.secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14), //Adjust the vertical alignment here
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.iconColor,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.iconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                ),
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
            ),
          ),
        ),

        if (_passwordErrorText != null) // ADD THIS BLOCK (Conditional error display)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              _passwordErrorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        SizedBox(height: 8),
      ],
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


/*import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models/user_check_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';


import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String mobileNumber;

  const RegistrationScreen({Key? key, required this.mobileNumber}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String phoneNumber = '';
  String countryCode = '+92'; // Default to Pakistan
  String password = '';
  String userName = '';

  final double textFieldHeight = 50.0;

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _nameErrorText;
  String? _passwordErrorText;
  bool _isLoading = false;

  final ApiService _apiService = ApiService(); // Instance of ApiService


  @override
  void initState() {
    super.initState();
    _phoneNumberController.text = widget.mobileNumber;
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    setState(() {
      _nameErrorText = null;
      _passwordErrorText = null;
    });

    final name = _userNameController.text.trim();
    final password = _passwordController.text.trim();

    if (Global.forgetPin != "forget" && name.isEmpty) {
      setState(() {
        _nameErrorText = 'Name is required';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordErrorText = 'Password is required';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    UserCheckResponse? response;
    if (Global.forgetPin == "forget") {
      response = await _apiService.resetPassword(context, widget.mobileNumber, password);
    } else {
      response = await _apiService.registerUser(context, widget.mobileNumber, name, password);
    }

    setState(() {
      _isLoading = false;
    });

    if (response != null) {
      if (response.responseCode == '0000') {
        if (Global.forgetPin == "forget") {
          _showSuccessDialog();
        } else {
          // Save UserID in shared preferences
          await SharedPreferencesManager.putString('id', response.message!);
          await SharedPreferencesManager.putString('mobileNumber', widget.mobileNumber);
          await SharedPreferencesManager.putString('name', name);
          await SharedPreferencesManager.putString('pin', password); // Save Pin

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          //Navigate to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Operation failed. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed. Please try again.')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Password Reset Successful"),
          content: const Text("Your password has been reset successfully."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
                Global.forgetPin = ""; // Reset global forget pin
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
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopRightCorner(),
                SizedBox(height: 30),
                Text(
                  Global.forgetPin == "forget" ? 'Reset Password' : 'Sign Up',
                  style: AppStyles.titleLarge
                      .copyWith(color: AppColors.primaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                if (Global.forgetPin != "forget") _buildUserNameTextField(),
                if (Global.forgetPin != "forget") SizedBox(height: 20),
                _buildPhoneNumberTextField(),
                SizedBox(height: 20),
                _buildPasswordTextField(),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
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
                    Global.forgetPin == "forget" ? 'Set Password' : 'Sign Up',
                    style: AppStyles.bodyMedium
                        .copyWith(color: Colors.white),
                  ),
                ),

                SizedBox(height: 30),

                //  "Have an Account? Log In" is shown only when Global.forgetPin is NOT "forget"
                if (Global.forgetPin != "forget")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Have an Account? ", style: AppStyles.bodyMedium),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                          child: Text(
                            'Log In',
                            style: AppStyles.bodyMedium
                                .copyWith(color: AppColors.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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

  Widget _buildUserNameTextField() {
    return SizedBox(
      height: textFieldHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.lightGreyStroke,
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TextField(
            controller: _userNameController,
            keyboardType: TextInputType.name,
            style: AppStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'User Name',
              hintStyle: AppStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryTextColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14), //Adjust the vertical alignment here
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppColors.iconColor,
              ),
              errorText: _nameErrorText,
            ),
            onChanged: (value) {
              setState(() {
                userName = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberTextField() {
    return SizedBox(
      height: textFieldHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.lightGreyStroke,
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TextField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            enabled: false,
            style: AppStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: AppStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryTextColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14), //Adjust the vertical alignment here
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: AppColors.iconColor,
              ),
            ),
            onChanged: (value) {
              setState(() {
                phoneNumber = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField() {
    return SizedBox(
      height: textFieldHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.lightGreyStroke,
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Set Password',
              hintStyle: AppStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryTextColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14), //Adjust the vertical alignment here
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.iconColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.iconColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              errorText: _passwordErrorText,
            ),
            onChanged: (value) {
              setState(() {
                password = value;
              });
            },
          ),
        ),
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_check_response.dart';
import '../services/api_service.dart'; // Import ApiService
import '../constants/ApiConstants.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart'; // Import login screen

class RegistrationScreen extends StatefulWidget {
  final String mobileNumber;

  const RegistrationScreen({Key? key, required this.mobileNumber})
      : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  //Text Editing Controller
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _pinControllers =
  List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _confirmPinControllers =
  List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
  List.generate(4, (index) => FocusNode());
  final List<FocusNode> _confirmPinFocusNodes =
  List.generate(4, (index) => FocusNode());
  final FocusNode _nameFocusNode = FocusNode();
  String? _nameErrorText;
  String? _pinErrorText;
  String? _confirmPinErrorText;

  //Loading state
  bool _isLoading = false;

  //Indicate whether to show indicator on button or not
  bool _isButtonLoading = false;

  List<bool> _isPinEmptyList =
  List.generate(4, (index) => true); // Track empty state for PIN
  List<bool> _isConfirmPinEmptyList =
  List.generate(4, (index) => true); // Track empty state for Confirm PIN

  //Validation booleans
  bool _isPinValid = true;
  bool _isConfirmPinValid = true;

  // Indicate if register button has been pressed.
  bool _registerButtonPressed = false;

  final ApiService _apiService = ApiService(); // Instance of ApiService

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _pinFocusNodes.length; i++) {
      final int index = i;
      _pinFocusNodes[i].addListener(() {
        setState(() {});
      });
    }

    for (int i = 0; i < _confirmPinFocusNodes.length; i++) {
      final int index = i;
      _confirmPinFocusNodes[i].addListener(() {
        setState(() {});
      });
    }
    _nameFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var controller in _confirmPinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    for (var node in _confirmPinFocusNodes) {
      node.dispose();
    }
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    setState(() {
      _registerButtonPressed = true;
      _pinErrorText = null;
      _confirmPinErrorText = null;
      _isButtonLoading = true;
    });
    final String name = _nameController.text.trim();
    String pin = "";
    String confirmPin = "";
    for (var controller in _pinControllers) {
      pin += controller.text;
    }

    for (var controller in _confirmPinControllers) {
      confirmPin += controller.text;
    }

    // Validate Fields and Set Error States
    setState(() {
      _nameErrorText = name.isEmpty ? 'Name is required' : null;

      // Update isEmptyList based on the current state
      _isPinEmptyList =
          List.generate(4, (index) => _pinControllers[index].text.isEmpty);
      _isConfirmPinEmptyList = List.generate(
          4, (index) => _confirmPinControllers[index].text.isEmpty);

      _isPinValid = !_isPinEmptyList.contains(true);
      _isConfirmPinValid = !_isConfirmPinEmptyList.contains(true);

      if (!_isPinValid) {
        _pinErrorText = "PIN is required";
      }

      if (!_isConfirmPinValid) {
        _confirmPinErrorText = "Confirm PIN is required";
      }
    });

    if ((Global.forgetPin != "forget" && name.isEmpty) ||
        !_isPinValid ||
        !_isConfirmPinValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter all fields and a 4-digit PIN.')),
      );
      setState(() {
        _isButtonLoading = false; // Reset button loading state
      });
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match.')),
      );
      setState(() {
        _isButtonLoading = false; // Reset button loading state
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    UserCheckResponse? response;
    if (Global.forgetPin == "forget") {
      // Call forget password API
      response = await _apiService.resetPassword(
          context, widget.mobileNumber, pin);
    } else {
      // Call register user API
      response = await _apiService.registerUser(
          context, widget.mobileNumber, name, pin);
    }

    setState(() {
      _isLoading = false;
      _isButtonLoading = false; // Ensure button loading is always reset
    });

    if (response != null) {
      if (response.responseCode == '0000') {
        // Registration Successful
        if (Global.forgetPin == "forget") {
          //Show success dialog and move back to login
          _showSuccessDialog();
        } else {
          // Save UserID in shared preferences
          await SharedPreferencesManager.putString('id', response.message!);
          await SharedPreferencesManager.putString('mobileNumber', widget.mobileNumber);
          await SharedPreferencesManager.putString('name', name);
          await SharedPreferencesManager.putString('pin', pin); // Save Pin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          //Navigate to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
      } else {
        // Registration Failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message ??
                  'Operation failed. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed. Please try again.')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Password Reset Successful"),
          content: const Text("Your password has been reset successfully."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
                Global.forgetPin = ""; // Reset global forget pin
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double horizontalPadding = screenWidth * 0.07;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: false, //Ensure background color does not extend behind app bar
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/images/pink_corner.png',
                width: screenWidth * 0.35,
                height: screenHeight * 0.12,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.07,
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Container(
                      width: screenWidth * 0.86,
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
                            Text(
                              Global.forgetPin == "forget"
                                  ? 'Reset PIN'
                                  : 'Register',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              Global.forgetPin == "forget"
                                  ? 'Set your new 4-digit PIN.\nYour phone number is ${widget.mobileNumber}'
                                  : 'Enter your name and set a 4-digit PIN.\nYour phone number is ${widget.mobileNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Conditionally Show Name Field
                            if (Global.forgetPin != "forget")
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Enter your name',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide:
                                      const BorderSide(color: Colors.blue),
                                    ),
                                    errorText: _nameErrorText,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                  ),
                                ),
                              ),
                            if (Global.forgetPin != "forget")
                              const SizedBox(height: 20),
                            const Text("Set PIN"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                4,
                                    (index) => SizedBox(
                                  width: screenWidth * 0.12,
                                  height: screenWidth * 0.12,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      TextFormField(
                                        controller: _pinControllers[index],
                                        focusNode: _pinFocusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        obscureText: true,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          errorText: null,
                                          // Hide individual box error
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: (_registerButtonPressed &&
                                                  _isPinEmptyList[index])
                                                  ? Colors.red
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.blue),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _isPinEmptyList[index] =
                                                value.isEmpty;
                                          });

                                          if (value.isNotEmpty) {
                                            if (index < 3) {
                                              FocusScope.of(context).requestFocus(
                                                  _pinFocusNodes[index + 1]);
                                            } else {
                                              FocusScope.of(context).unfocus();
                                            }
                                          } else {
                                            if (index > 0) {
                                              FocusScope.of(context).requestFocus(
                                                  _pinFocusNodes[index - 1]);
                                            }
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_pinErrorText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _pinErrorText!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 20),
                            const Text("Confirm PIN"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                4,
                                    (index) => SizedBox(
                                  width: screenWidth * 0.12,
                                  height: screenWidth * 0.12,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      TextFormField(
                                        controller: _confirmPinControllers[index],
                                        focusNode: _confirmPinFocusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        obscureText: true,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          errorText: null,
                                          //Hide error on individual
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: (_registerButtonPressed &&
                                                  _isConfirmPinEmptyList[
                                                  index])
                                                  ? Colors.red
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.blue),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _isConfirmPinEmptyList[index] =
                                                value.isEmpty;
                                          });

                                          if (value.isNotEmpty) {
                                            if (index < 3) {
                                              FocusScope.of(context).requestFocus(
                                                  _confirmPinFocusNodes[
                                                  index + 1]);
                                            } else {
                                              FocusScope.of(context).unfocus();
                                            }
                                          } else {
                                            if (index > 0) {
                                              FocusScope.of(context).requestFocus(
                                                  _confirmPinFocusNodes[
                                                  index - 1]);
                                            }
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_confirmPinErrorText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _confirmPinErrorText!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed:
                                _isButtonLoading ? null : _registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: _isButtonLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 3,
                                  ),
                                )
                                    : Text(
                                  Global.forgetPin == "forget"
                                      ? 'Reset PIN'
                                      : 'Register',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Image.asset(
                      'assets/images/stethoscope.png',
                      height: screenHeight * 0.22,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
            // _isLoading
            //     ? Container(
            //   color: Colors.black.withOpacity(0.5),
            //   child: const Center(
            //     child: CircularProgressIndicator(
            //       valueColor:
            //       AlwaysStoppedAnimation<Color>(Colors.white),
            //     ),
            //   ),
            // )
            //     : const SizedBox.shrink(),
          ],
        ),
      ),
      extendBody: true, // Make sure this is still here
    );
  }
}

*/
