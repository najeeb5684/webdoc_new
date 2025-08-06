
import 'dart:convert';
import 'dart:io';
import 'package:Webdoc/models/activate_response.dart';
import 'package:Webdoc/models/prescription_response_new.dart';
import 'package:Webdoc/models/registration_response.dart';
import 'package:Webdoc/models/reset_password_response.dart';
import 'package:Webdoc/models/save_feedback_response.dart';
import 'package:Webdoc/models/specialist_category_response.dart';
import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:Webdoc/models/user_check_response_new.dart';
import 'package:Webdoc/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as client; // Alias http as client just in case, though 'http' is standard
import '../models/api_response.dart';
import '../models/appointment_count_response.dart';
import '../models/book_slot_response.dart';
import '../models/cancel_appointment_response.dart';
import '../models/doctor.dart';
import '../models/easypaisa_response.dart';
import '../models/follow_up_coupon_response.dart';
import '../models/get_slots_response.dart';
import '../models/past_appointment_response.dart';
import '../models/prescription_response.dart';
import '../models/profile_model.dart';
import '../models/upcoming_appointments_response.dart';
import '../models/user_check_response.dart';
import '../models/login_response.dart';
// Import the new package models

import '../models/package_response.dart';
import '../models/user_package_response.dart';
import '../models/wallet_balance_response.dart';
import '../models/wallet_history_response.dart'; // Import PackageResponse

class ApiService {
  static const String baseUrlFahad = 'https://retailportalapi.webddocsystems.com/';
  //static const String baseUrl = 'https://webdocsite.webddocsystems.com/public/api/v1/';
  static const String irfanBaseUrl = 'https://webdocsite.webddocsystems.com/public/api/v1/';// Updated base
  static const String irfanBaseUrltesting = 'https://digital.webdoc.com.pk/ci4webdocsite/public/api/v1/';// Updated base
  static const String specialistDoctorListEndpoint = 'specialist/list';
  static const String specialistCategoriesEndpoint = 'specialist/categories';
  static String ciSession = '';
  static const String doctorListEndpoint = 'DoctorList';
  static const String saveFeedbackEndpoint = 'feedback/save';
  //static const String getConsultationsByUserIdEndpoint = 'GetConsultationsByUserId';
  static const String getConsultationsByUserIdEndpoint = 'prescription/detail-list';
  static const String getPatientProfileEndpoint = 'patient/profile';
  static const String updatePatientProfileEndpoint = 'patient/update-profile';
  static const String userCheckEndpoint = 'check-user';
  //static const String patientLoginEndpoint = 'PatientLogin';
  static const String patientLoginEndpoint = 'login-site';
  static const String sendOtpEndpoint = 'send-otp';
  static const String verifyOtpEndpoint = 'verify-otp';
  static const String registerUserEndpoint = 'register';
  static const String passwordResetEndpoint = 'change-password';
  // Add the new package endpoint
  static const String getPackagesEndpoint = 'GetPackages';
  static const String activatePackageEndpoint = 'activate/package';
  static const String bookSlotEndpoint = 'slots/book'; // Note:
  static const String easypaisaBaseUrl = 'https://paymentgtw.webddocsystems.com/public/api/v1/';
  static const String easypaisaEndpoint = 'service/payment';
  static const String bookedAppointmentEndpoint = 'slots/booked-appointment';
  static const String cancelAppointmentEndpoint = 'slots/cancel'; // Add the
  static const String upcomingCountEndpoint = '/slots/appointment-count';
  static const String walletHistoryEndpoint = 'wallet/history';


  //Check for internet connectivity
  static Future<bool> isInternetAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException catch (_) {
        return false;
      }
      return false;
    }
  }

//Show No Internet connection Dialogue
  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          title: Row(
            mainAxisSize: MainAxisSize.min, // Added this
            children: [
              Icon(Icons.wifi_off, color: Colors.red), // Icon for no internet
              SizedBox(width: 8),
              Flexible( // Added Flexible
                child: Text(
                  'No Internet',
                  overflow: TextOverflow.ellipsis, // Added ellipsis
                ),
              ),
            ],
          ),
          content: Text('Please check your internet connection and try again.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // New method: User Check
  Future<UserCheckResponseNew?> userCheck(
      BuildContext context, String mobileNumber) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$userCheckEndpoint');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({'phone': '$mobileNumber@webdoc.com.pk'});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return UserCheckResponseNew.fromJson(decodedJson);
      } else {
        print('Failed to check user: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error checking user: $e');
      return null;
    }
  }

  // New method: Login
  Future<LoginResponse?> login(
      BuildContext? context, String mobileNumber, String pin) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context!);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$patientLoginEndpoint');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'phone': mobileNumber,
        'password': pin,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return LoginResponse.fromJson(decodedJson);
      } else {
        print('Login failed: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context!);
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
// Password Reset API Call
  Future<ChangePasswordResponse?> resetPassword(BuildContext context, String mobileNumber, String pin) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    final Uri apiUrl = Uri.parse('$irfanBaseUrl$passwordResetEndpoint');

    try {
      final response = await http.post(
        apiUrl,
        headers: {'accept': '*/*', 'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": mobileNumber,
          "password": pin,
          "confrim_password": pin,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Password Reset Successful (even if the API returns an error message, we still need to handle it in UI)
        return ChangePasswordResponse.fromJson(responseData);
      } else {
        print('Password reset failed: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error resetting password: $e');
      return null;
    }
  }


  Future<DoctorListResponse?> getDoctorList(BuildContext context) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null; // Return null if no internet
    }

    try {
      final response =
      await http.get(Uri.parse('$baseUrlFahad$doctorListEndpoint'));

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return DoctorListResponse.fromJson(decodedJson);
      } else {
        print('Failed to load doctors. Status code: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context); // Show dialog for socket exception
      return null;
    } catch (e) {
      print('Error fetching doctor list: $e');
      return null;
    }
  }

  Future<FeedbackResponse?> saveFeedback({
    required BuildContext context,
    required String feedBackText,
    required String feedBackRating,
    required String doctorId,
    required String patientId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$irfanBaseUrl$saveFeedbackEndpoint'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'FeedbackText': feedBackText,
          'RatingPoints': feedBackRating,
          'DoctorId': doctorId,
          'PatientId': patientId,
        }),
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return FeedbackResponse.fromJson(decodedJson);
      } else {
        print('Failed to save feedback. Status code: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context); // Show dialog if real network error occurs
      return null;
    } catch (e) {
      print('Error saving feedback: $e');
      return null;
    }
  }


  /* Future<PrescriptionResponse?> getPrescription(
      BuildContext context, String userId, int pageNumber, int pageSize) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null; // Return null if no internet
    }

    try {
      final queryParams = {
        'userId': userId,
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse('${baseUrlFahad}${getConsultationsByUserIdEndpoint}')
          .replace(queryParameters: queryParams);
      final response = await client.get(uri); // Using 'client' alias here

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return PrescriptionResponse.fromJson(decodedJson);
      } else {
        print(
            'Failed to load prescriptions. Status code: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context); // Show dialog for socket exception
      return null;
    } catch (e) {
      print('Error fetching prescriptions: $e');
      return null;
    }
  }*/
  Future<PrescriptionResponseNew?> getPrescription(
      BuildContext context, String userId, int pageNumber, int pageSize) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null; // Return null if no internet
    }

    try {
      final queryParams = {
        'patient_profile_id': userId,
        'page': pageNumber.toString(),
        'perPage': pageSize.toString(),
      };

      final uri = Uri.parse('${irfanBaseUrl}${getConsultationsByUserIdEndpoint}')
          .replace(queryParameters: queryParams);
      final response = await client.get(uri); // Using 'client' alias here

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return PrescriptionResponseNew.fromJson(decodedJson);
      } else {
        print(
            'Failed to load prescriptions. Status code: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context); // Show dialog for socket exception
      return null;
    } catch (e) {
      print('Error fetching prescriptions: $e');
      return null;
    }
  }
  // New method: Get Patient Profile
  Future<Profile?> getPatientProfile(BuildContext context, String id) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context); // Ensure showNoInternetDialog is defined
      return null; // Return null if no internet
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$getPatientProfileEndpoint'); // Assumes baseUrl and getPatientProfileEndpoint are defined elsewhere
      final headers = {
        'Content-Type': 'application/json',
        'accept': 'text/plain',
        'Cookie': 'ci_session=tmijb8l33v6khel9un46h6k3ork2ao8f', // Use your actual session cookie
      };

      //Important change :  GET request with the patient_profile_id as part of the body is incorrect
      //You need to add `patient_profile_id` as the query parameter

      final response = await http.get(
          Uri.parse('$irfanBaseUrl$getPatientProfileEndpoint?patient_profile_id=$id'),
          headers: headers);
      // final body = json.encode({'patient_profile_id': id}); // API expects patient_profile_id in body  <- Removed because GET request

      // final response = await http.post(url, headers: headers, body: body);  <- Removed because GET request

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return Profile.fromJson(decodedJson);
      } else {
        print('Failed to load profile: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context); // Show dialog for socket exception
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // New method: Update Patient Profile
  Future<UserCheckResponseNew?> updatePatientProfile({
    required BuildContext context,
    required String id,
    required String firstName, // Changed from name to firstName
    required String gender,
    required String mobileNumber,
    required String maritalStatus,
    required String dateOfBirth, // Corrected casing
    required String age,
    required String weight,
    required String height,
    required String cnic,
    required String lastName,
    required String address,
    required String country,
    required String city
  }) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null; // Return null if no internet
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$updatePatientProfileEndpoint');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'patient_profile_id': id,
        'phone': mobileNumber,
        'FirstName': firstName, // Corrected to firstName
        'LastName': lastName,
        'CNIC': cnic,
        'DateOfBirth': dateOfBirth, // Corrected casing
        'Gender': gender,
        'Address': address,
        'Country': country,
        'City': city,
        'MartialStatus': maritalStatus,
        'Age': age,
        'Weight': weight,
        'Height': height,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return UserCheckResponseNew.fromJson(decodedJson); //Assuming UserCheckResponseNew is what your backend sends as a response. If not please specify
      } else {
        print('Failed to update profile: ${response.statusCode}');
        print('Response body: ${response.body}');  // Print the response body for debugging
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context); // Show dialog for socket exception
      return null;
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }
  // Send OTP API Call
  Future<SendOtpResponse?> sendOtp(BuildContext context, String mobileNumber) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    final Uri url = Uri.parse(irfanBaseUrl + sendOtpEndpoint); // Correct URL construction

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // Match curl headers
        body: jsonEncode({'mobileNumber': mobileNumber}), // Match curl body
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return SendOtpResponse.fromJson(decodedResponse);
      } else {
        print('Failed to send OTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return null;
    }
  }

// Verify OTP API Call
  Future<VerifyOtpResponse?> verifyOtp(BuildContext context, String mobileNumber, String otp) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    final Uri url = Uri.parse(irfanBaseUrl + verifyOtpEndpoint);  //Correct URL Construction

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // Match curl headers
        body: jsonEncode({'mobileNumber': mobileNumber, 'Code': otp}), // Match curl body
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return VerifyOtpResponse.fromJson(decodedResponse);
      } else {
        print('Failed to verify OTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }
  // Register User API Call
  Future<RegistrationResponse?> registerUser(BuildContext context, String mobileNumber, String name, String pin,String email,String platform) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    final Uri apiUrl = Uri.parse('$irfanBaseUrl$registerUserEndpoint');

    try {
      final response = await http.post(
        apiUrl,
        headers: {'accept': '*/*', 'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": mobileNumber,
          "firstname": name,
          "password": pin,
          "email": email,
          "platform": platform,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Registration Successful
        return RegistrationResponse.fromJson(responseData);
      } else {
        print('Registration failed: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // --- New API Call: Get Packages ---
  Future<List<Package>?> getPackages(BuildContext context) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null; // Return null if no internet
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$getPackagesEndpoint');
      // Using the accept header from your curl example
      final headers = {'accept': 'text/plain'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        final packageResponse = PackageResponse.fromJson(decodedJson);

        if (packageResponse.responseCode == '0000' && packageResponse.getPackageDetails.isNotEmpty) {
          return packageResponse.getPackageDetails;
        } else {
          // Handle cases where API returns success but no packages or a non-success code
          print('API returned non-success code or empty list: ${packageResponse.responseCode} - ${packageResponse.message}');
          return []; // Return empty list if success but no data
        }
      } else {
        print('Failed to load packages. Status code: ${response.statusCode}');
        return null; // Return null for HTTP errors
      }
    } on SocketException catch (e) {
      print('Socket exception getting packages: $e');
      showNoInternetDialog(context); // Show dialog for socket exception
      return null;
    } catch (e) {
      print('Error fetching packages: $e');
      return null;
    }
  }


  Future<ActivateResponse?> activatePackage({
    required BuildContext context,
    required String user_id,
    required String packageId,
  }) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$activatePackageEndpoint');
      final headers = {
        'accept': '*/*', // From curl
        'Content-Type': 'application/json',
      };
      final body = json.encode({
        'user_id': user_id,
        'package_id': packageId,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        // The API response has "message" and "responseCode" top level
        return ActivateResponse.fromJson(decodedJson);
      } else {
        print('Failed to activate package: ${response.statusCode}');
        try {
          // Attempt to parse error body if available
          final decodedErrorJson = jsonDecode(response.body);
          return ActivateResponse.fromJson(decodedErrorJson);
        } catch (e) {
          print('Error parsing error response: $e');
          return ActivateResponse(
            statusMessage: ['Failed to activate package. Status code: ${response.statusCode}'],
            statusCode: response.statusCode,
          );
        }
      }
    } on SocketException catch (e) {
      print('Socket exception during package activation: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error activating package: $e');
      return null;
    }
  }

  // New method: Book Slot API Call
  Future<BookSlotResponse?> bookSlot({
    required BuildContext context,
    required String patientId,
    required String doctorId,
    required String appointmentDate, // yyyy-MM-dd
    required String appointmentTime, // HH:mm
    required String slotNumber, // String as per curl
    required String paymentMethod, // String as per curl
    required String price, // String as per curl
    required String couponCode, // String as per curl
  }) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      // Using the separate base URL for the book slot API
      final url = Uri.parse('$irfanBaseUrl$bookSlotEndpoint');
      final headers = {
        'Content-Type': 'application/json',
        // 'Cookie': 'ci_session=...', // Cookies are usually handled by the http client or not required for API calls
      };
      final body = json.encode({
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'slotNumber': slotNumber,
        'paymentMethod': paymentMethod,
        'price': price,
        'couponCode': couponCode,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return BookSlotResponse.fromJson(decodedJson);
      } else {
        print('Failed to book slot: ${response.statusCode}');
        try {
          final decodedErrorJson = jsonDecode(response.body);
          return BookSlotResponse.fromJson(decodedErrorJson); // Attempt to parse error body
        } catch (e) {
          print('Error parsing error response: $e');
          return BookSlotResponse(
            statusCode: response.statusCode,
            statusMessage: ['Failed to book slot. Status code: ${response.statusCode}'],
          );
        }
      }
    } on SocketException catch (e) {
      print('Socket exception during slot booking: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error booking slot: $e');
      return null;
    }
  }


  Future<UpcomingAppointmentsResponse?> getUpcomingAppointments({
    required String patientId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final url = Uri.parse('$irfanBaseUrl${bookedAppointmentEndpoint}?patientId=$patientId&page=$page&perPage=$perPage&type=upcoming');
      final headers = {
        'Content-Type': 'application/json',
        if (ciSession.isNotEmpty) 'Cookie': 'ci_session=$ciSession',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return UpcomingAppointmentsResponse.fromJson(decodedJson);
      } else {
        print('Failed to get upcoming appointments: ${response.statusCode}');
        print('Response body: ${response.body}');  // Log the response body
        return null;
      }
    } catch (e) {
      print('Error getting upcoming appointments: $e');
      return null;
    }
  }

  Future<PastAppointmentsResponse?> getPastAppointments({
    required String patientId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final url = Uri.parse('$irfanBaseUrl${bookedAppointmentEndpoint}?patientId=$patientId&page=$page&perPage=$perPage&type=past');
      final headers = {
        'Content-Type': 'application/json',
        if (ciSession.isNotEmpty) 'Cookie': 'ci_session=$ciSession',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return PastAppointmentsResponse.fromJson(decodedJson);
      } else {
        print('Failed to get past appointments: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting past appointments: $e');
      return null;
    }
  }

  Future<EasyPaisaResponse?> easypaisaPayment(
      BuildContext context, String encryptedRequest) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('${easypaisaBaseUrl}${easypaisaEndpoint}');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('WebDocEsayPaisaStore:WebDoc@321'))}', // Add Basic Auth header
      };
      final body = json.encode({'encrypted_request': encryptedRequest});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return EasyPaisaResponse.fromJson(decodedJson);
      } else {
        print('EasyPaisa payment failed: ${response.statusCode}');
        try {
          final decodedErrorJson = jsonDecode(response.body);
          return EasyPaisaResponse.fromJson(decodedErrorJson); // Attempt to parse error body
        } catch (e) {
          print('Error parsing error response: $e');
          return EasyPaisaResponse(
            statusCode: response.statusCode.toString(),
            statusMessage: ['EasyPaisa payment failed. Status code: ${response.statusCode}'],
          );
        }
      }
    } on SocketException catch (e) {
      print('Socket exception during EasyPaisa payment: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error during EasyPaisa payment: $e');
      return null;
    }
  }


  Future<List<SpecialistDoctorsResponse>?> getDoctors(
      BuildContext context,
      {int page = 1,
        int perPage = 10,
        int speciality = 0}) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$specialistDoctorListEndpoint?'
          'page=$page&perPage=$perPage&speciality=$speciality');

      final headers = {'Cookie': 'ci_session=$ciSession'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return [SpecialistDoctorsResponse.fromJson(decodedJson)];
      } else {
        print(
            'Failed to fetch doctors: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      return null;
    }
  }

  Future<List<SpecialistCategoryResponse>?> getSpecialistCategories(
      BuildContext context) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$specialistCategoriesEndpoint');
      final headers = {'Cookie': 'ci_session=$ciSession'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return [SpecialistCategoryResponse.fromJson(decodedJson)];
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return null;
    }
  }


  Future<List<Slot>?> getSlots(
      BuildContext context, {
        required String doctorId,
        required String dayOfWeek,
        required String appointmentDate,
      }) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl/slots/list?'
          'doctorId=$doctorId&dayOfWeek=$dayOfWeek&appointmentDate=$appointmentDate');

      final headers = {'Cookie': 'ci_session=$ciSession'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        final getSlotsResponse = GetSlotsResponse.fromJson(decodedJson);

        if (getSlotsResponse.payLoad != null) {
          return getSlotsResponse.payLoad;
        } else {
          print('No slots found in the response.');
          return []; // Or null, depending on how you want to handle it
        }
      } else {
        print('Failed to fetch slots: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching slots: $e');
      return null;
    }
  }

 static Future<AppointmentCountResponse> getAppointmentCount({required String patientId}) async {
    try {
      final url = Uri.parse('$irfanBaseUrl$upcomingCountEndpoint?patientId=$patientId');
      final headers = {
        'Content-Type': 'application/json',  //Most likely needed
        if (ciSession.isNotEmpty) 'Cookie': 'ci_session=$ciSession',
      };

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AppointmentCountResponse.fromJson(jsonData);
      } else {
        print('API Error: ${response.statusCode}'); // Log error for debugging
        print('Response body: ${response.body}'); // Log response body
        throw Exception('Failed to load appointment count');
      }
    } catch (e) {
      print('API Exception: $e');  // Log exception for debugging
      throw Exception('Failed to connect to the API');
    }
  }


  Future<UserPackageResponse?> fetchUserPackage({
    required BuildContext context,
    required String userId,
  }) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl/user/package?user_id=$userId');
      final headers = {
        'Content-Type': 'application/json', // Important
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return UserPackageResponse.fromJson(decodedJson);
      } else {
        print('Failed to fetch user package: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error fetching user package: $e');
      return null;
    }
  }

  Future<WalletHistoryResponse?> getWalletHistory(
      BuildContext context, String patientId,
      {int page = 1, int perPage = 100}) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl$walletHistoryEndpoint?'
          'patientId=$patientId&page=$page&perPage=$perPage');

      final headers = {'Cookie': 'ci_session=$ciSession'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return WalletHistoryResponse.fromJson(decodedJson);
      } else {
        print('Get wallet history failed: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Get wallet history error: $e');
      return null;
    }
  }


  Future<WalletBalanceResponse?> getWalletBalance(BuildContext context, String patientId) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl/wallet/balance?patientId=$patientId');  // Correct URL

      final headers = {'Cookie': 'ci_session=$ciSession'}; //Add cookie
      final response = await http.get(url, headers: headers); // Add headers

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return WalletBalanceResponse.fromJson(decodedJson);
      } else {
        print('Get wallet balance failed: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Get wallet balance error: $e');
      return null;
    }
  }


  // New method: Cancel Appointment
  Future<CancelAppointmentResponse?> cancelAppointment({
    required String patientId,
    required String appointmentId,
  }) async {
    try {
      final url = Uri.parse('$irfanBaseUrl$cancelAppointmentEndpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'ci_session=$ciSession'  // Make sure ciSession is correctly populated
      };
      final body = json.encode({
        'patientId': patientId,
        'appointmentId': appointmentId,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return CancelAppointmentResponse.fromJson(decodedJson);
      } else {
        print('Cancel appointment failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cancel appointment error: $e');
      return null;
    }
  }

  Future<FollowUpCouponResponse?> checkFollowUpCoupon({
    required BuildContext context,
    required String patientId,
    required String doctorId,
    required String couponCode,
  }) async {
    if (!await isInternetAvailable()) {
      showNoInternetDialog(context);
      return null;
    }

    try {
      final url = Uri.parse('$irfanBaseUrl/slots/check-follow');
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'ci_session=$ciSession',
      };
      final body = json.encode({
        'patientId': patientId,
        'doctorId': doctorId,
        'couponCode': couponCode,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        return FollowUpCouponResponse.fromJson(decodedJson);
      } else {
        print('Failed to check follow up coupon: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      showNoInternetDialog(context);
      return null;
    } catch (e) {
      print('Error checking follow up coupon: $e');
      return null;
    }
  }
}






