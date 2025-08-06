

import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_theme.dart'; //Import your AppTheme Class

import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'otp_screen.dart';
import '../services/api_service.dart'; // Import ApiService
import '../utils/global.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phoneNumber = '';
  String countryCode = '+92'; // Default to Pakistan
  String password = '';
  bool rememberMe = false;
  bool _obscurePassword = true;
  final double textFieldHeight = 50.0;

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController =
  TextEditingController(); // Controller for password
  final ApiService _apiService = ApiService(); // Instance of ApiService
  String? _loginError; // To display login errors
  String? _phoneNumberError; // To display phone number errors
  String? _passwordError; // To display password error
  bool _isLoading = false;
  bool _showPasswordField = false; //show password after user found
  int _phoneNumberLength =
  10; // Default Pakistan Number length (without country code)
  String? _signUpError;


  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    rememberMe = await SharedPreferencesManager.getBool('rememberMe') ?? false;
    if (rememberMe) {
      countryCode =
          await SharedPreferencesManager.getString('countryCode') ?? '+92';
      phoneNumber =
          await SharedPreferencesManager.getString('phoneNumber') ?? '';
      _phoneNumberController.text = phoneNumber;

      //Check if user exist and show password field

      String mobileNumber = "$countryCode$phoneNumber";
      // Modify number for Pakistan to start with '0'
      if (countryCode == '+92') {
        mobileNumber = "0$phoneNumber";
      }

      setState(() {
        _showPasswordField = true;
        _setPhoneNumberLength(); //set Phone number length
      });

      password = await SharedPreferencesManager.getString('password') ?? '';
      _passwordController.text = password;
    }
    setState(() {});
  }

  // Validation function (now reused)
  bool _validatePhoneNumber() {
    if (_phoneNumberController.text.isEmpty) {
      setState(() {
        _phoneNumberError = "Phone number is required";
      });
      return false;
    } else if (_phoneNumberController.text.length != _phoneNumberLength) {
      // World numbers from 7 to 15 digits
      setState(() {
        _phoneNumberError =
        "Phone number must be $_phoneNumberLength digits (excluding country code)";
      });
      return false;
    } else {
      setState(() {
        _phoneNumberError = null; // Clear the error if valid
      });
      return true;
    }
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Password is required";
      });
      return false;
    } else {
      setState(() {
        _passwordError = null; // Clear the error if valid
      });
      return true;
    }
  }

  Future<void> _userCheck() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return; // Don't proceed further if no internet.
    }

    if (!_validatePhoneNumber()) {
      // Validate FIRST
      return;
    }

    String mobileNumber = "$countryCode${_phoneNumberController.text.trim()}";

    // Modify number for Pakistan to start with '0'
    if (countryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear any previous error
    });

    try {
      final response = await _apiService.userCheck(context, mobileNumber);

      if (response?.payLoad?.user == true) {
        setState(() {
          _showPasswordField = true; // Show the Password field
        });
      } else {
        // User not found - navigate to OTP screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
        );
        await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
        Global.forgetPin = "";
      }
    } catch (error) {
      print("Error during user check: $error");

      //Even in error cases, navigate to OTP screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
      );
      Global.forgetPin = "";
      await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return; // Don't proceed further if no internet.
    }

    if (!_validatePhoneNumber()) {
      return;
    }

    if (!_validatePassword()) {
      return;
    }

    String mobileNumber = "$countryCode${_phoneNumberController.text.trim()}";

    // Modify number for Pakistan to start with '0'
    if (countryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear any previous error
    });

    try {
      // Use your API login here.
      final loginResponse =
      await _apiService.login(context, mobileNumber, password);
      if (loginResponse?.statusCode == 1) {
        // Login Successful
        final loginData = loginResponse!.payLoad?.user;

        await SharedPreferencesManager.putString('id', loginData?.id ?? '');
        await SharedPreferencesManager.putString('mobileNumber', loginData?.phoneNumber ?? '');
        await SharedPreferencesManager.putString('name', loginData?.userName ?? '');
        await SharedPreferencesManager.putBool('isPackageActivated', loginData?.isPackageActivated ?? false);

        if (loginData?.packageName != null) {
          await SharedPreferencesManager.putString(
              'packageName', loginData?.packageName ?? '');
          await SharedPreferencesManager.putString(
              'activeDate', loginData?.activeDate ?? '');
          await SharedPreferencesManager.putString(
              'expiryDate', loginData?.expiryDate ?? '');
        }
        await SharedPreferencesManager.putString('pin', _passwordController.text);
        // Save phone number and password if "Remember Me" is checked
        if (rememberMe) {
          await SharedPreferencesManager.putString('countryCode', countryCode);
          await SharedPreferencesManager.putString(
              'phoneNumber', _phoneNumberController.text);
          await SharedPreferencesManager.putString(
              'password', _passwordController.text);
          await SharedPreferencesManager.putBool('rememberMe', true);
        } else {
          await SharedPreferencesManager.remove('countryCode');
          await SharedPreferencesManager.remove('phoneNumber');
          await SharedPreferencesManager.remove('password');
          await SharedPreferencesManager.remove('rememberMe');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        //  Handle Login Failure
        String errorMessage = 'Incorrect Password. Please try again.';

        // Access statusMessage correctly. It's a List<String>.  Use first item or join them.

          errorMessage = loginResponse!.statusMessage!.join(', '); // Join messages if there are multiple.  Or use just `loginResponse.statusMessage.first` if you only want the first one.

        setState(() {
          _loginError = errorMessage;
        });

      }
    }
    catch (error) {
      print("Login error: $error");
      setState(() {
        _loginError = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setPhoneNumberLength() {
    if (countryCode == '+1') {
      _phoneNumberLength = 10; // USA/Canada
    } else if (countryCode == '+44') {
      _phoneNumberLength = 10; // UK
    } else if (countryCode == '+91') {
      _phoneNumberLength = 10; // India
    } else if (countryCode == '+92') {
      _phoneNumberLength = 10; // Pakistan (excluding '0')
    } else if (countryCode == '+61') {
      _phoneNumberLength = 9; // Australia
    } else if (countryCode == '+49') {
      _phoneNumberLength = 11; // Germany (Maximum)
    } else if (countryCode == '+33') {
      _phoneNumberLength = 9; // France
    } else if (countryCode == '+86') {
      _phoneNumberLength = 11; // China
    } else if (countryCode == '+55') {
      _phoneNumberLength = 11; // Brazil (Maximum)
    } else if (countryCode == '+27') {
      _phoneNumberLength = 9; // South Africa
    } else if (countryCode == '+81') {
      _phoneNumberLength = 11; // Japan (Maximum)
    }
    else if (countryCode == '+971') {
      _phoneNumberLength = 9; // Dubai
    }
    else {
      _phoneNumberLength = 15; // Some default length if unspecified
    }

  }

  Future<void> _handleSignUp() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return;
    }

    if (!_validatePhoneNumber()) {
      return;
    }

    String mobileNumber = "$countryCode${_phoneNumberController.text.trim()}";
    if (countryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    setState(() {
      _isLoading = true;
      _signUpError = null; //Clear Previous Error
    });

    try {
      final response = await _apiService.userCheck(context, mobileNumber);

      if (response?.payLoad?.user == true) {
        // User already exists
        setState(() {
          _signUpError = "User already registered. Please login.";
          _showPasswordField = true;
        });

      } else {
        // User not found - navigate to OTP screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
        );
        await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
        Global.forgetPin="";
      }

    } catch (error) {
      print("Error during user check for sign up: $error");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
      );
      await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
      Global.forgetPin="";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

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
                  'Log In',
                  style: AppStyles.titleLarge(context)
                      .copyWith(color: AppColors.primaryTextColor), // Make Login Black
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // Phone Number with Country Code Picker
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
                      boxShadow: [
                        // Add elevation/shadow
                        /* BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          // Adjust opacity for subtle shadow
                          spreadRadius: 0.5,
                          blurRadius: 2,
                          offset: Offset(0, 2), // changes position of shadow
                        ),*/
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          CountryCodePicker(
                            onChanged: (CountryCode cc) {
                              setState(() {
                                countryCode = cc.dialCode!;
                                _setPhoneNumberLength();
                                phoneNumber = ''; // Clear the phone number
                                _phoneNumberController.text = '';
                                _showPasswordField = false;
                                _signUpError = null;
                              });
                            },
                            initialSelection: 'PK', // Default to Pakistan
                            favorite: ['+92', '+1'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            textStyle: AppStyles.bodyMedium(context).copyWith(color: Colors.black),  // Add color here
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    _phoneNumberLength), // Dynamic length
                              ],
                              style: AppStyles.bodyMedium(context),
                              decoration: InputDecoration(
                                hintText: 'Enter Number (3051234567)',
                                hintStyle: AppStyles.bodyMedium(context).copyWith(
                                    color: AppColors.secondaryTextColor),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                errorText: _phoneNumberError,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  phoneNumber = value;
                                  _showPasswordField = false;
                                  _signUpError = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10),


                // Password Field (conditional rendering)

                if (_showPasswordField)
                  SizedBox(
                    height: textFieldHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.lightGreyStroke,
                          // Use your light grey color here
                          width: 0.8, // Adjust width as needed
                        ),
                        boxShadow: [
                          // Add elevation/shadow
                          /*  BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            // Adjust opacity for subtle shadow
                            spreadRadius: 0.5,
                            blurRadius: 2,
                            offset: Offset(0, 2), // changes position of shadow
                          ),*/
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.start,
                          style: AppStyles.bodyMedium(context),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.iconColor,
                            ),
                            hintText: 'Password',
                            hintStyle: AppStyles.bodyMedium(context).copyWith(
                                color: AppColors.secondaryTextColor),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 15),
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
                            errorText: _passwordError,
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

                if (_showPasswordField) SizedBox(height: 10),

                // Remember Me and Forgot Password (conditional rendering)
                if (_showPasswordField)
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            rememberMe = value!;
                            if (!rememberMe) {
                              //Clear all remember me data if uncheck
                              SharedPreferencesManager.remove('countryCode');
                              SharedPreferencesManager.remove('phoneNumber');
                              SharedPreferencesManager.remove('password');
                              SharedPreferencesManager.remove('rememberMe');
                            }
                          });
                        },
                        checkColor: Colors.white, // Color of the checkmark when checked
                        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return AppColors.primaryColor.withOpacity(.32); // Or a lighter version of your primary color for disabled state
                          }

                          if (states.contains(MaterialState.selected)) { // when checked
                            return AppColors.primaryColor; // The color when enabled and checked
                          }

                          return Colors.white; // The color when unchecked
                        }),
                        side: BorderSide(color: AppColors.primaryColor, width: 1), // Optional: add a border when unchecked
                      ),
                      Text('Remember Me', style: AppStyles.bodySmall(context)),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          // Navigate to OTP screen when "Forgot PIN?" is pressed

                          String mobileNumber =
                              "$countryCode${_phoneNumberController.text.trim()}";

                          // Modify number for Pakistan to start with '0'
                          if (countryCode == '+92') {
                            mobileNumber =
                            "0${_phoneNumberController.text.trim()}";
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OtpScreen(mobileNumber: mobileNumber)),
                          );
                          Global.forgetPin = "forget";
                        },
                        child: Text(
                          'Forgot Password',
                          style: AppStyles.bodySmall(context)
                              .copyWith(color: AppColors.secondaryTextColor),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 20),

                if (_signUpError != null)
                  Text(
                    _signUpError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                if (_loginError != null)
                  Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _showPasswordField
                      ? _login
                      : _userCheck,
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
                    _showPasswordField ? 'Login' : 'Next',
                    style: AppStyles.bodyMedium(context)
                        .copyWith(color: Colors.white),
                  ),
                ),

                SizedBox(height: 30),

                // Don't Have an Account? Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't Have an Account? ", style: AppStyles.bodyMedium(context)),
                    InkWell( // Use InkWell for ripple effect
                      onTap: _isLoading ? null : () {
                        // Call the signup function

                        setState(() {
                          _signUpError = null; //Clear Previous error on click
                        });
                        _handleSignUp();
                      },
                      borderRadius: BorderRadius.circular(8), // Optional: Round the corners of the InkWell
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Add padding here
                        child: Text(
                          'Sign Up',
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



/*
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/app_theme.dart'; //Import your AppTheme Class

import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'otp_screen.dart';
import '../services/api_service.dart'; // Import ApiService
import '../utils/global.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phoneNumber = '';
  String countryCode = '+92'; // Default to Pakistan
  String password = '';
  bool rememberMe = false;
  bool _obscurePassword = true;
  final double textFieldHeight = 50.0;

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController =
  TextEditingController(); // Controller for password
  final ApiService _apiService = ApiService(); // Instance of ApiService
  String? _loginError; // To display login errors
  String? _phoneNumberError; // To display phone number errors
  String? _passwordError; // To display password error
  bool _isLoading = false;
  bool _showPasswordField = false; //show password after user found
  int _phoneNumberLength =
  10; // Default Pakistan Number length (without country code)

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    rememberMe = await SharedPreferencesManager.getBool('rememberMe') ?? false;
    if (rememberMe) {
      countryCode =
          await SharedPreferencesManager.getString('countryCode') ?? '+92';
      phoneNumber =
          await SharedPreferencesManager.getString('phoneNumber') ?? '';
      _phoneNumberController.text = phoneNumber;

      //Check if user exist and show password field

      String mobileNumber = "$countryCode$phoneNumber";
      // Modify number for Pakistan to start with '0'
      if (countryCode == '+92') {
        mobileNumber = "0$phoneNumber";
      }

      setState(() {
        _showPasswordField = true;
        _setPhoneNumberLength(); //set Phone number length
      });

      password = await SharedPreferencesManager.getString('password') ?? '';
      _passwordController.text = password;
    }
    setState(() {});
  }

  // Validation function (now reused)
  bool _validatePhoneNumber() {
    if (_phoneNumberController.text.isEmpty) {
      setState(() {
        _phoneNumberError = "Phone number is required";
      });
      return false;
    } else if (_phoneNumberController.text.length != _phoneNumberLength) {
      // World numbers from 7 to 15 digits
      setState(() {
        _phoneNumberError =
        "Phone number must be $_phoneNumberLength digits (excluding country code)";
      });
      return false;
    } else {
      setState(() {
        _phoneNumberError = null; // Clear the error if valid
      });
      return true;
    }
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Password is required";
      });
      return false;
    } else {
      setState(() {
        _passwordError = null; // Clear the error if valid
      });
      return true;
    }
  }

  Future<void> _userCheck() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return; // Don't proceed further if no internet.
    }

    if (!_validatePhoneNumber()) {
      // Validate FIRST
      return;
    }

    String mobileNumber = "$countryCode${_phoneNumberController.text.trim()}";

    // Modify number for Pakistan to start with '0'
    if (countryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear any previous error
    });

    try {
      final response = await _apiService.userCheck(context, mobileNumber);

      if (response?.responseCode == "0000") {
        setState(() {
          _showPasswordField = true; // Show the Password field
        });
      } else {
        // User not found - navigate to OTP screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
        );
        await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
      }
    } catch (error) {
      print("Error during user check: $error");

      //Even in error cases, navigate to OTP screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
      );
      Global.forgetPin = "";
      await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return; // Don't proceed further if no internet.
    }

    if (!_validatePhoneNumber()) {
      return;
    }

    if (!_validatePassword()) {
      return;
    }

    String mobileNumber = "$countryCode${_phoneNumberController.text.trim()}";

    // Modify number for Pakistan to start with '0'
    if (countryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear any previous error
    });

    try {
      // Use your API login here.
      final loginResponse =
      await _apiService.login(context, mobileNumber, password);
      if (loginResponse?.responseCode == '0000') {
        // Login Successful
        final loginData = loginResponse!.loginData!;

        await SharedPreferencesManager.putString(
            'id', loginData.applicationUserId ?? '');
        await SharedPreferencesManager.putString(
            'mobileNumber', loginData.contactNumber ?? '');
        await SharedPreferencesManager.putString('name', loginData.name ?? '');
        await SharedPreferencesManager.putBool(
            'isPackageActivated', loginData.isPackageActivated ?? false);

        if (loginData.packageName != null) {
          await SharedPreferencesManager.putString(
              'packageName', loginData.packageName ?? '');
          await SharedPreferencesManager.putString(
              'activeDate', loginData.activeDate ?? '');
          await SharedPreferencesManager.putString(
              'expiryDate', loginData.expiryDate ?? '');
        }
        await SharedPreferencesManager.putString(
            'pin', _passwordController.text);
        // Save phone number and password if "Remember Me" is checked
        if (rememberMe) {
          await SharedPreferencesManager.putString('countryCode', countryCode);
          await SharedPreferencesManager.putString(
              'phoneNumber', _phoneNumberController.text);
          await SharedPreferencesManager.putString(
              'password', _passwordController.text);
          await SharedPreferencesManager.putBool('rememberMe', true);
        } else {
          await SharedPreferencesManager.remove('countryCode');
          await SharedPreferencesManager.remove('phoneNumber');
          await SharedPreferencesManager.remove('password');
          await SharedPreferencesManager.remove('rememberMe');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          _loginError =
              loginResponse?.message ?? 'Incorrect Password. Please try again.';
        });
      }
    } catch (error) {
      print("Login error: $error");
      setState(() {
        _loginError = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setPhoneNumberLength() {
    if (countryCode == '+1') {
      _phoneNumberLength = 10; // USA/Canada
    } else if (countryCode == '+44') {
      _phoneNumberLength = 10; // UK
    } else if (countryCode == '+91') {
      _phoneNumberLength = 10; // India
    } else if (countryCode == '+92') {
      _phoneNumberLength = 10; // Pakistan (excluding '0')
    } else if (countryCode == '+61') {
      _phoneNumberLength = 9; // Australia
    } else if (countryCode == '+49') {
      _phoneNumberLength = 11; // Germany (Maximum)
    } else if (countryCode == '+33') {
      _phoneNumberLength = 9; // France
    } else if (countryCode == '+86') {
      _phoneNumberLength = 11; // China
    } else if (countryCode == '+55') {
      _phoneNumberLength = 11; // Brazil (Maximum)
    } else if (countryCode == '+27') {
      _phoneNumberLength = 9; // South Africa
    } else if (countryCode == '+81') {
      _phoneNumberLength = 11; // Japan (Maximum)
    }
    else if (countryCode == '+971') {
      _phoneNumberLength = 9; // Dubai
    }
    else {
      _phoneNumberLength = 15; // Some default length if unspecified
    }

  }

  void _handleSignUp() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return;
    }

    if (!_validatePhoneNumber()) {
      return;
    }

    String mobileNumber = "$countryCode${_phoneNumberController.text.trim()}";
    if (countryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
    );
    await SharedPreferencesManager.putString('mobileNumber', mobileNumber);
    Global.forgetPin = "";
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
                  'Log In',
                  style: AppStyles.titleLarge
                      .copyWith(color: AppColors.primaryTextColor), // Make Login Black
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // Phone Number with Country Code Picker
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
                      boxShadow: [
                        // Add elevation/shadow
                        */
/* BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          // Adjust opacity for subtle shadow
                          spreadRadius: 0.5,
                          blurRadius: 2,
                          offset: Offset(0, 2), // changes position of shadow
                        ),*//*

                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          CountryCodePicker(
                            onChanged: (CountryCode cc) {
                              setState(() {
                                countryCode = cc.dialCode!;
                                _setPhoneNumberLength();
                                phoneNumber = ''; // Clear the phone number
                                _phoneNumberController.text = '';
                                _showPasswordField = false;
                              });
                            },
                            initialSelection: 'PK', // Default to Pakistan
                            favorite: ['+92', '+1'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            textStyle: AppStyles.bodyMedium,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    _phoneNumberLength), // Dynamic length
                              ],
                              style: AppStyles.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'Enter Phone Number',
                                hintStyle: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.secondaryTextColor),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                errorText: _phoneNumberError,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  phoneNumber = value;
                                  _showPasswordField = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Password Field (conditional rendering)

                if (_showPasswordField)
                  SizedBox(
                    height: textFieldHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.lightGreyStroke,
                          // Use your light grey color here
                          width: 0.8, // Adjust width as needed
                        ),
                        boxShadow: [
                          // Add elevation/shadow
                          */
/*  BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            // Adjust opacity for subtle shadow
                            spreadRadius: 0.5,
                            blurRadius: 2,
                            offset: Offset(0, 2), // changes position of shadow
                          ),*//*

                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.start,
                          style: AppStyles.bodyMedium,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.iconColor,
                            ),
                            hintText: 'Password',
                            hintStyle: AppStyles.bodyMedium.copyWith(
                                color: AppColors.secondaryTextColor),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 15),
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
                            errorText: _passwordError,
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

                if (_showPasswordField) SizedBox(height: 10),

                // Remember Me and Forgot Password (conditional rendering)
                if (_showPasswordField)
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            rememberMe = value!;
                            if (!rememberMe) {
                              //Clear all remember me data if uncheck
                              SharedPreferencesManager.remove('countryCode');
                              SharedPreferencesManager.remove('phoneNumber');
                              SharedPreferencesManager.remove('password');
                              SharedPreferencesManager.remove('rememberMe');
                            }
                          });
                        },
                        checkColor: Colors.white, // Color of the checkmark when checked
                        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return AppColors.primaryColor.withOpacity(.32); // Or a lighter version of your primary color for disabled state
                          }

                          if (states.contains(MaterialState.selected)) { // when checked
                            return AppColors.primaryColor; // The color when enabled and checked
                          }

                          return Colors.white; // The color when unchecked
                        }),
                        side: BorderSide(color: AppColors.primaryColor, width: 1), // Optional: add a border when unchecked
                      ),
                      Text('Remember Me', style: AppStyles.bodySmall),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          // Navigate to OTP screen when "Forgot PIN?" is pressed

                          String mobileNumber =
                              "$countryCode${_phoneNumberController.text.trim()}";

                          // Modify number for Pakistan to start with '0'
                          if (countryCode == '+92') {
                            mobileNumber =
                            "0${_phoneNumberController.text.trim()}";
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OtpScreen(mobileNumber: mobileNumber)),
                          );
                          Global.forgetPin = "forget";
                        },
                        child: Text(
                          'Forgot Password',
                          style: AppStyles.bodySmall
                              .copyWith(color: AppColors.secondaryTextColor),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 20),
                if (_loginError != null)
                  Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _showPasswordField
                      ? _login
                      : _userCheck,
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
                    _showPasswordField ? 'Login' : 'Next',
                    style: AppStyles.bodyMedium
                        .copyWith(color: Colors.white),
                  ),
                ),

                SizedBox(height: 30),

                // Don't Have an Account? Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't Have an Account? ", style: AppStyles.bodyMedium),
                    InkWell( // Use InkWell for ripple effect
                      onTap: () {
                        // Call the signup function
                        _handleSignUp();
                      },
                      borderRadius: BorderRadius.circular(8), // Optional: Round the corners of the InkWell
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0), // Add padding here
                        child: Text(
                          'Sign Up',
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

*/








/*
import 'package:Webdoc/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'otp_screen.dart';
import '../services/api_service.dart'; // Import ApiService

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final List<TextEditingController> _pinControllers =
  List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (index) => FocusNode());
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final ApiService _apiService = ApiService(); // Instance of ApiService
  String? _loginError; // To display login errors
  String? _phoneNumberError; // To display phone number errors
  bool _isLoading = false;
  bool _showPinBoxes = false;
  String _selectedCountryCode = '+92'; // Default to Pakistan
  String _selectedFlag = 'assets/images/flag_pakistan.png'; // Default Pakistan Flag
  int _phoneNumberLength = 10; // Default Pakistan Number length

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _pinFocusNodes.length; i++) {
      final int index = i;
      _pinFocusNodes[i].addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    _phoneNumberFocusNode.dispose();
    super.dispose();
  }

  // Validation function (now reused)
  bool _validatePhoneNumber() {
    if (_phoneNumberController.text.isEmpty) {
      setState(() {
        _phoneNumberError = "Phone number is required";
      });
      return false;
    } else if (_phoneNumberController.text.length != _phoneNumberLength) {
      setState(() {
        _phoneNumberError = "Phone number must be $_phoneNumberLength digits";
      });
      return false;
    } else {
      setState(() {
        _phoneNumberError = null; // Clear the error if valid
      });
      return true;
    }
  }


  Future<void> _userCheck() async {
    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return; // Don't proceed further if no internet.
    }


    if (!_validatePhoneNumber()) { // Validate FIRST
      return;
    }

    String mobileNumber = "$_selectedCountryCode${_phoneNumberController.text
        .trim()}";

    // Modify number for Pakistan to start with '0'
    if (_selectedCountryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear any previous error
    });

    try {
      final response = await _apiService.userCheck(context, mobileNumber);

      if (response?.responseCode == "0000") {
        setState(() {
          _showPinBoxes = true; // Show the PIN boxes
        });
      } else {
        // User not found - navigate to OTP screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
        );
        await SharedPreferencesManager.putString(
            'mobileNumber', mobileNumber);
      }
    } catch (error) {
      print("Error during user check: $error");

      //Even in error cases, navigate to OTP screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => OtpScreen(mobileNumber: mobileNumber)),
      );
      Global.forgetPin= "";
      await SharedPreferencesManager.putString(
          'mobileNumber', mobileNumber);


    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {

    if (!await ApiService.isInternetAvailable()) {
      ApiService.showNoInternetDialog(context);
      return; // Don't proceed further if no internet.
    }


    if (!_validatePhoneNumber()) { // Validate FIRST
      return;
    }

    String mobileNumber = "$_selectedCountryCode${_phoneNumberController.text
        .trim()}";

    // Modify number for Pakistan to start with '0'
    if (_selectedCountryCode == '+92') {
      mobileNumber = "0${_phoneNumberController.text.trim()}";
    }

    String pin = "";
    for (var controller in _pinControllers) {
      pin += controller.text;
    }

    if (pin.isEmpty || pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a 4-digit PIN")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null; // Clear any previous error
    });

    try {
      final loginResponse = await _apiService.login(context, mobileNumber, pin);

      if (loginResponse?.responseCode == '0000') {
        // Login Successful
        final loginData = loginResponse!.loginData!;

        await SharedPreferencesManager.putString(
            'id', loginData.applicationUserId ?? '');
        await SharedPreferencesManager.putString(
            'mobileNumber', loginData.contactNumber ?? '');
        await SharedPreferencesManager.putString('name', loginData.name ?? '');
        await SharedPreferencesManager.putBool(
            'isPackageActivated', loginData.isPackageActivated ?? false);

        if (loginData.packageName != null) {
          await SharedPreferencesManager.putString(
              'packageName', loginData.packageName ?? '');
          await SharedPreferencesManager.putString(
              'activeDate', loginData.activeDate ?? '');
          await SharedPreferencesManager.putString(
              'expiryDate', loginData.expiryDate ?? '');
        }

        await SharedPreferencesManager.putString('pin', pin);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          _loginError = loginResponse?.message ?? 'Incorrect PIN. Please try again.';
        });
      }
    } catch (error) {
      print("Login error: $error");
      setState(() {
        _loginError = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Pink top-right corner
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
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.09),
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.09,
                    ),
                    SizedBox(height: screenHeight * 0.09),
                    Container(
                      width: screenWidth * 0.9,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Enter credentials to continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: Row(
                                    children: [
                                      // Country Code Selection - POPUP MENU
                                      PopupMenuButton<String>(
                                        offset: const Offset(0, 40),
                                        itemBuilder: (BuildContext context) {
                                          return <PopupMenuEntry<String>>[
                                            PopupMenuItem<String>(
                                              value: '+92',
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/images/flag_pakistan.png',
                                                    height: 24,
                                                    width: 32,
                                                    fit: BoxFit.fill,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text('+92 (Pakistan)'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: '+971',
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/images/flag_dubai.png',
                                                    height: 24,
                                                    width: 32,
                                                    fit: BoxFit.fill,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text('+971 (Dubai)'),
                                                ],
                                              ),
                                            ),
                                          ];
                                        },
                                        onSelected: (String newValue) {
                                          setState(() {
                                            _selectedCountryCode = newValue;
                                            if (_selectedCountryCode == '+92') {
                                              _selectedFlag =
                                              'assets/images/flag_pakistan.png';
                                              _phoneNumberLength = 10;
                                            } else if (_selectedCountryCode ==
                                                '+971') {
                                              _selectedFlag =
                                              'assets/images/flag_dubai.png'; // Replace with dubai flag asset
                                              _phoneNumberLength = 9;
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                _selectedFlag,
                                                height: 24,
                                                width: 32,
                                                fit: BoxFit.fill,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _selectedCountryCode,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 0.5,
                                        width: 1,
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneNumberController,
                                          focusNode: _phoneNumberFocusNode,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                                _phoneNumberLength), // Dynamic length
                                          ],
                                          decoration: InputDecoration(
                                            labelText: 'Phone Number',
                                            labelStyle: const TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            hintText: 'Enter your phone number',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(15.0),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                                width: 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(15.0),
                                              borderSide: const BorderSide(
                                                color: Colors.blue,
                                                width: 1.5,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(15.0),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                                width: 1.0,
                                              ),
                                            ),
                                            contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 15,
                                                horizontal: 10),
                                            floatingLabelBehavior:
                                            FloatingLabelBehavior.auto,
                                            errorText: _phoneNumberError, // Show error message
                                          ),
                                          onChanged: (value) {
                                            // Reset _showPinBoxes when the number changes
                                            setState(() {
                                              _showPinBoxes = false;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (_showPinBoxes)
                              const Text(
                                "Enter PIN",
                                textAlign: TextAlign.center,
                              ),
                            if (_showPinBoxes)
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  4,
                                      (index) => SizedBox(
                                    width: screenWidth * 0.15,
                                    height: screenWidth * 0.15,
                                    child: TextFormField(
                                      controller: _pinControllers[index],
                                      focusNode: _pinFocusNodes[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      obscureText: true, // hide pin
                                      style: const TextStyle(fontSize: 16),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.blue),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          if (index < 3) {
                                            FocusScope.of(context).requestFocus(
                                                _pinFocusNodes[index + 1]);
                                          } else {
                                            FocusScope.of(context).unfocus();
                                          }
                                        } else if (value.isEmpty && index > 0) {
                                          // Move focus to the previous box when backspace is pressed and the current box is empty
                                          FocusScope.of(context).requestFocus(
                                              _pinFocusNodes[index - 1]);
                                        }
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            if (_loginError != null)
                              Text(
                                _loginError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 10),

                            // Forget PIN
                            if (_showPinBoxes)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Navigate to OTP screen when "Forgot PIN?" is pressed

                                    String mobileNumber = "$_selectedCountryCode${_phoneNumberController.text
                                        .trim()}";

                                    // Modify number for Pakistan to start with '0'
                                    if (_selectedCountryCode == '+92') {
                                      mobileNumber = "0${_phoneNumberController.text.trim()}";
                                    }

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              OtpScreen(mobileNumber: mobileNumber)),
                                    );
                                    Global.forgetPin= "forget";
                                  },
                                  child: const Text(
                                    'Forgot PIN?',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _showPinBoxes
                                    ? _login
                                    : _userCheck,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                                    : Text(
                                  _showPinBoxes ? 'Login' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Image.asset(
                      'assets/images/stethoscope.png',
                      height: screenHeight * 0.35,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/


