import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';

import '../models/doctor.dart';

class Global {
  static bool isPackageActivated = false; // Example - load from shared prefs
  static String? docid; //Store Doctor ID
  static String? docType; //Store Doctor Type
  static int docPosition = 0;
  static String? fromProfile;


  static const String isPackageActivatedKey = 'isPackageActivated';

  static String country = "";
  static String currency = "";
  static String appointmentOpen = "";
  static String navigateTo = "";
  static bool isShown = false;
  // static BookedAppointmentResponse bookListResponse = BookedAppointmentResponse(); // You'll need to create this model in Dart
  // static BookedAppointmentResponse pastAppointmentListResponse = BookedAppointmentResponse(); // Same as above
  static String vitalHistory = "";
  static String transactionID = "";
  static String transactionDate = "";
  static String botQuestion = "";
  static String botQuestionType = "";
  static List<String> categoryLoopList = [];
  static int specialistCategory = 0;
  static String showbooked = "";
  static String docChanel = "";
  static String callFrom = "";
  static String dateSlotDialog = "";
  static int slotNo = 0;
  static String dateSlot = "";
  static String timeslot = "";
  static String privacytermsurl = "";
  static int getReportPosition = 0;
  //static GetPatientProfileResponse getPatientProfile = GetPatientProfileResponse(); // You'll need to create this model in Dart
  static int selectedCustomerConsultationPosition = 0;
  static int selectedVitalPosition = 0;

  static String bankName = "";
  static int selectedPackageId = 0;
  static const String THEME_COLOR_CODE = "#000000";
  static const String THEME_COLOR_WHITE = "#FFFFFF";
  static Color getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
  static bool feedbackDialog = false;
  static bool call_missed = false;
  static String selectedPackagePrice = "";
  static String paymentUrl = "";
  //static PackagesResponse packagesResponse = PackagesResponse(); // You'll need to create this model in Dart
  static String forgetPin = "";
  static String OTPCode = "";
  static String mobileNumber = "";
  static String privacyTermsUrl = "";
  static dynamic getPatientProfile;


  // Doctor List Variables
  static List<Doctor> allDoctorsList = [];

  //Firebase realtime method
  static final databaseReference =
  FirebaseDatabase.instance.ref().child("Doctors");

  static Future<void> updateRealTimeStatuses(List<Doctor> allDoctorsList) async {
    databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        for (var doctor in allDoctorsList) {
          final emailKey = doctor.emailDoctor?.replaceAll('.', '');
          if (data.containsKey(emailKey)) {
            doctor.isOnline = data[emailKey]['status'];
          }
        }
        //Global.allDoctorsList = allDoctorsList;
      }
    });
  }

  static doctorStatusRealTime(String docEmail, Function(String) onStatusChanged) {
    final databaseReference =
    FirebaseDatabase.instance.ref().child("Doctors").child(docEmail);
    databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        if (event.snapshot.children.isNotEmpty) {
          final docStatus = event.snapshot.child("status").value.toString();
          onStatusChanged(docStatus);
        }
      }
    });
  }

  static bool isEmailValid(String email) {
    final pattern = r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }




  // Special profile specific data
  static dynamic specialdoctorListResponse; // Hold doctor data


  // For showing booked list on special doctors screen

  static List<dynamic> bookedList = [];

  static String? appointmentNo="0";
}