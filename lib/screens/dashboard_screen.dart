// DashboardScreen.dart
import 'package:Webdoc/screens/appointment_screen.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:Webdoc/screens/specialist_category_screen.dart';
import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:Webdoc/screens/account_screen.dart';
import 'package:Webdoc/screens/prescription_screen.dart';
import '../widgets/bottom_navigation.dart';
import 'home_screen.dart';
import '../services/api_service.dart'; // Import the ApiService

import 'package:Webdoc/utils/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _appointmentCount = 0; // Add this line

  final List<Widget> _screens = [
    HomeScreen(),
    PrescriptionScreen(),
    PastAppointmentsScreen(),
    AccountScreen(),

  ];

  @override
  void initState() {
    super.initState();
    _loadAppointmentCount();
  }

  Future<void> _loadAppointmentCount() async {
    try {
      // 1. Try to load from SharedPreferences first
      int? savedCount = await SharedPreferencesManager.getInt("upcomingAppointmentCount");
      setState(() {
        _appointmentCount = savedCount ?? 0; // Use null-aware operator
      });

      // Get patientId from SharedPreferences
      String? patientId = await SharedPreferencesManager.getString("id");

      if (patientId != null && patientId.isNotEmpty) {
        // 2. Then, fetch from the API and update SharedPreferences *and* the UI
        final appointmentCountResponse = await ApiService.getAppointmentCount(patientId: patientId);
        if (appointmentCountResponse != null && appointmentCountResponse.payLoad != null) {  // Check for null response and payload
          final count = appointmentCountResponse.payLoad?.upcomingAppointmentCount ?? 0;

          await SharedPreferencesManager.putInt("upcomingAppointmentCount", count);
          setState(() {
            _appointmentCount = count;
          });
        } else {
          print("API returned null response or payload");
          // Handle the error appropriately here.  Perhaps set _appointmentCount to 0
          setState(() {
            _appointmentCount = 0;  // Set to default value
          });
        }

      } else {
        print("Patient ID not found in SharedPreferences");
        // Handle the case where the patient ID is not available
      }

    } catch (e) {
      print('Error loading appointment count: $e');
      setState(() {
        _appointmentCount = 0; // Ensure default value on error
      });
      // Handle the error appropriately (e.g., show a message to the user)
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true, // BottomNavigation has transparency
      body: SafeArea(  // Wrap the selected screen with SafeArea
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Padding( // Add Padding directly to bottomNavigationBar
        padding: EdgeInsets.only(
            left: 50,
            right: 50,
            bottom: 2 + MediaQuery.of(context).padding.bottom, // Add bottom padding
            top: 10
        ),
        child: BottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          appointmentCount: _appointmentCount, // Pass the count
        ),
      ),
    );
  }
}

// DashboardScreen.dart
/*import 'package:Webdoc/screens/appointment_screen.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:Webdoc/screens/specialist_category_screen.dart';
import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:Webdoc/screens/account_screen.dart';
import 'package:Webdoc/screens/prescription_screen.dart';
import '../widgets/bottom_navigation.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    PrescriptionScreen(),
    AccountScreen(),
    PastAppointmentsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true, // BottomNavigation has transparency
      body: SafeArea(  // Wrap the selected screen with SafeArea
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Padding( // Add Padding directly to bottomNavigationBar
        padding: EdgeInsets.only(
            left: 50,
            right: 50,
            bottom: 2 + MediaQuery.of(context).padding.bottom, // Add bottom padding
            top: 10
        ),
        child: BottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}*/




/*
import 'package:Webdoc/screens/appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:Webdoc/screens/account_screen.dart';
import 'package:Webdoc/screens/prescription_screen.dart';
import '../widgets/bottom_navigation.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;



  final List<Widget> _screens = [
    HomeScreen(),
    PrescriptionScreen(),
    AccountScreen(),
    AppointmentScreen(), // Place the widget here.
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
*/


/*
import 'package:Webdoc/screens/account_screen.dart';
import 'package:Webdoc/screens/prescription_screen.dart';



import 'package:flutter/material.dart';

import '../widgets/bottom_navigation.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    PrescriptionScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}*/
