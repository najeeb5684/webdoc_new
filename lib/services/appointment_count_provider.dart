import 'dart:async';

import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:Webdoc/services/api_service.dart';
import 'package:Webdoc/utils/shared_preferences.dart';

class AppointmentCountProvider extends ChangeNotifier {
  int _appointmentCount = 0;
  Timer? _timer;

  int get appointmentCount => _appointmentCount;

  AppointmentCountProvider() {
    _loadAppointmentCount();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadAppointmentCount();
    });
  }

  Future<void> _loadAppointmentCount() async {
    try {
      // 1. Try to load from SharedPreferences first
      int? savedCount = await SharedPreferencesManager.getInt("upcomingAppointmentCount");
      _appointmentCount = savedCount ?? 0;
      notifyListeners();

      // Get patientId from SharedPreferences
      String? patientId = await SharedPreferencesManager.getString("id");

      if (patientId != null && patientId.isNotEmpty) {
        // 2. Then, fetch from the API and update SharedPreferences *and* the UI
        final appointmentCountResponse = await ApiService.getAppointmentCount(patientId: patientId);
        if (appointmentCountResponse != null && appointmentCountResponse.payLoad != null) {  // Check for null response and payload
          final count = appointmentCountResponse.payLoad?.upcomingAppointmentCount ?? 0;

          await SharedPreferencesManager.putInt("upcomingAppointmentCount", count);
          _appointmentCount = count;
          notifyListeners();
        } else {
          print("API returned null response or payload");
          _appointmentCount = 0;
          notifyListeners();
        }

      } else {
        print("Patient ID not found in SharedPreferences");
      }

    } catch (e) {
      print('Error loading appointment count: $e');
      _appointmentCount = 0;
      notifyListeners();
    }
  }
}