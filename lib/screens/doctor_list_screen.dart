

import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/screens/package_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

import '../models/doctor.dart';
//import '../services/api_service.dart'; // Removed API service import
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import '../widgets/doctor_list_item.dart';
import 'audio_call_screen.dart';
import 'doctor_profile_screen.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true; // Start in the loading state
  bool _hasInternet = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Global.isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        _loadDoctorsFromFirebaseAndSetupListeners(); // Load from Firebase
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDoctorsFromFirebaseAndSetupListeners() async {
    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DatabaseReference doctorsRef = FirebaseDatabase.instance.ref().child('StaticDoctors');

      doctorsRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          Global.allDoctorsList = _parseDoctorsFromFirebase(data);

          // Sort the doctors immediately after parsing
          _sortDoctorsByStatus();
          _filteredDoctors = List.from(Global.allDoctorsList);

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No doctors found in Firebase.')),
          );
          Global.allDoctorsList = [];
          _filteredDoctors = [];
        }
        setState(() {
          _isLoading = false; // Set isLoading to false AFTER data loads.
        });
      }, onError: (error) {
        print("Error loading doctors from Firebase: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctors from Firebase: $error')),
        );
        setState(() {
          _isLoading = false; // Ensure isLoading is set to false even on error
        });
      });

      // Set up Firebase listeners for online status AFTER the initial load
      _setupFirebaseListeners();

    } catch (error) {
      print("Error loading doctors from Firebase: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors from Firebase: $error')),
      );
      setState(() {
        _isLoading = false; // Ensure isLoading is set to false, even on error
      });
    }
  }

  List<Doctor> _parseDoctorsFromFirebase(Map<dynamic, dynamic> data) {
    List<Doctor> doctorList = [];

    data.forEach((key, value) {
      try {
        final doctorData = Map<String, dynamic>.from(value);

        Doctor doctor = Doctor(
          doctorSpecialty: doctorData['doctorSpecialty'] ?? '',
          doctorId: doctorData['doctorId'] ?? key, // Use the key as doctorId
          firstName: doctorData['firstName'] ?? '',
          imgLink: doctorData['imgLink'] ?? '',
          lastName: doctorData['lastName'] ?? '',
          country: doctorData['country'] ?? '',
          isOnline: doctorData['isOnline'] ?? '0',
          profileMessage: doctorData['profileMessage'] ?? '',
          rate: doctorData['rate'] ?? '5',
          emailDoctor: doctorData['emailDoctor'] ?? '',
          qualifications: doctorData['qualifications'] ?? '',
          experience: doctorData['experience'] ?? '',
        );
        doctorList.add(doctor);
      } catch (e) {
        print('Error parsing doctor data: $e for doctor with key: $key');
      }
    });

    return doctorList;
  }

  void _setupFirebaseListeners() {
    Global.databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _updateDoctorStatuses(data);
      }
    });
  }

  void _updateDoctorStatuses(Map<dynamic, dynamic> data) {
    // Create a local copy to avoid modifying the list while iterating
    List<Doctor> updatedDoctors = List.from(Global.allDoctorsList);

    for (var doctor in updatedDoctors) {
      final emailKey = doctor.emailDoctor?.replaceAll('.', '');
      if (data.containsKey(emailKey)) {
        doctor.isOnline = data[emailKey]['status'];
      }
    }

    // Update the global list
    Global.allDoctorsList = updatedDoctors;

    // Sort after updating statuses
    _sortDoctorsByStatus();

    // Update the filtered list
    setState(() {
      _filteredDoctors = List.from(Global.allDoctorsList);
    });
  }


  void _sortDoctorsByStatus() {
    Global.allDoctorsList.sort((a, b) {
      // Define the order: online > busy > offline
      int getStatusPriority(String? status) {
        switch (status?.toLowerCase()) {
          case 'online':
            return 0;
          case 'busy':
            return 1;
          default: // Includes 'offline' or null
            return 2;
        }
      }

      return getStatusPriority(a.isOnline).compareTo(getStatusPriority(b.isOnline));
    });
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = List.from(Global.allDoctorsList);
      } else {
        _filteredDoctors = Global.allDoctorsList
            .where((doctor) =>
        (doctor.firstName?.toLowerCase().contains(query.toLowerCase()) ??
            false) ||
            (doctor.lastName?.toLowerCase().contains(query.toLowerCase()) ??
                false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // set background color to white

      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                        (Route<dynamic> route) => false,
                  );
                  // uploadDoctorDataToFirebase(context, doctorDataList);
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Instant Doctors',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,

      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_isLoading) {
      return _buildLoading();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildNoDoctors();
    }

    return ListView.builder(
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        return DoctorListItem(
          doctor: _filteredDoctors[index],
          isPackageActivated: Global.isPackageActivated,
          onConsultPressed: () {
            Global.docPosition = index;

            if (Global.isPackageActivated) {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: _filteredDoctors[index],
                )
                ),
              );

              /*Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                ),
              );*/
              Global.fromProfile = "list";
            } else {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                ),
              );
            }
          },
          onItemTap: () {
            // This is the new callback
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: _filteredDoctors[index],
              )
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor),
          ),
          const SizedBox(height: 10),
          Text('Doctors loading...', style: AppStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_hospital, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No doctors found.', style: AppStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              _checkInternetConnection();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}



/*import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/screens/package_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

import '../models/doctor.dart';
//import '../services/api_service.dart'; // Removed API service import
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import '../widgets/doctor_list_item.dart';
import 'audio_call_screen.dart';
import 'doctor_profile_screen.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true; // Start in the loading state
  bool _hasInternet = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Global.isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        _loadDoctorsFromFirebaseAndSetupListeners(); // Load from Firebase
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDoctorsFromFirebaseAndSetupListeners() async {

    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Reference to your "doctors" node in Firebase Realtime Database. Adjust the path if needed.
      DatabaseReference doctorsRef = FirebaseDatabase.instance.ref().child('StaticDoctors');

      // Fetch data from Firebase
      doctorsRef.onValue.listen((event) { // Use .onValue.listen for real-time updates
        if (event.snapshot.value != null) {
          // Parse the data into a List<Doctor>
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          Global.allDoctorsList = _parseDoctorsFromFirebase(data); // Parse the data
          _filteredDoctors = List.from(Global.allDoctorsList);

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No doctors found in Firebase.')),
          );
          Global.allDoctorsList = [];
          _filteredDoctors = [];
        }
        setState(() {
          _isLoading = false; // Set isLoading to false AFTER data loads.  Important.
        });
      }, onError: (error) { // Handle potential errors in the listener
        print("Error loading doctors from Firebase: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctors from Firebase: $error')),
        );
        setState(() {
          _isLoading = false; // Ensure isLoading is set to false even on error
        });
      });

      // Set up Firebase listeners for online status AFTER the initial load
      _setupFirebaseListeners();

    } catch (error) {
      print("Error loading doctors from Firebase: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors from Firebase: $error')),
      );
      setState(() {
        _isLoading = false; // Ensure isLoading is set to false, even on error
      });
    }
  }


  List<Doctor> _parseDoctorsFromFirebase(Map<dynamic, dynamic> data) {
    List<Doctor> doctorList = [];

    data.forEach((key, value) { // Key is the doctorId in this case
      try {
        final doctorData = Map<String, dynamic>.from(value); // Cast to Map<String, dynamic>

        Doctor doctor = Doctor(
          doctorSpecialty: doctorData['doctorSpecialty'] ?? '',
          doctorId: doctorData['doctorId'] ?? key, // Use the key as doctorId
          firstName: doctorData['firstName'] ?? '',
          imgLink: doctorData['imgLink'] ?? '',
          lastName: doctorData['lastName'] ?? '',
          country: doctorData['country'] ?? '',
          isOnline: doctorData['isOnline'] ?? '0',  // Corrected this line
          profileMessage: doctorData['profileMessage'] ?? '',
          rate: doctorData['rate'] ?? '5',
          emailDoctor: doctorData['emailDoctor'] ?? '',
          qualifications: doctorData['qualifications'] ?? '',
          experience: doctorData['experience'] ?? '',
        );
        doctorList.add(doctor);
      } catch (e) {
        print('Error parsing doctor data: $e for doctor with key: $key');
        // Handle the error (e.g., log it, skip the doctor, etc.)
      }
    });

    return doctorList;
  }


  void _setupFirebaseListeners() {
    Global.databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _updateDoctorStatuses(data);
      }

    });
  }

  void _updateDoctorStatuses(Map<dynamic, dynamic> data) {
    setState(() {
      for (var doctor in Global.allDoctorsList) {
        final emailKey = doctor.emailDoctor?.replaceAll('.', '');
        if (data.containsKey(emailKey)) {
          doctor.isOnline = data[emailKey]['status'];
        }
      }
      _filteredDoctors = List.from(Global.allDoctorsList);
    });
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = List.from(Global.allDoctorsList);
      } else {
        _filteredDoctors = Global.allDoctorsList
            .where((doctor) =>
        (doctor.firstName?.toLowerCase().contains(query.toLowerCase()) ??
            false) ||
            (doctor.lastName?.toLowerCase().contains(query.toLowerCase()) ??
                false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // set background color to white

      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                        (Route<dynamic> route) => false,
                  );
                 // uploadDoctorDataToFirebase(context, doctorDataList);
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Instant Doctors',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,

      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_isLoading) {
      return _buildLoading();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildNoDoctors();
    }

    return ListView.builder(
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        return DoctorListItem(
          doctor: _filteredDoctors[index],
          isPackageActivated: Global.isPackageActivated,
          onConsultPressed: () {
            Global.docPosition = index;

            if (Global.isPackageActivated) {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: _filteredDoctors[index],
                )
                ),
              );

              *//*Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                ),
              );*//*
              Global.fromProfile = "list";
            } else {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                ),
              );
            }
          },
          onItemTap: () {
            // This is the new callback
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: _filteredDoctors[index],
              )
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor),
          ),
          const SizedBox(height: 10),
          Text('Doctors loading...', style: AppStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_hospital, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No doctors found.', style: AppStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              _checkInternetConnection();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }






  final List<Map<String, dynamic>> doctorDataList = [
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "20203314-e176-461d-8814-352c54a2e776",
      "firstName": "Dr. Hassan ",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/Dr. Hassan.jpeg",
      "lastName": "Nawaz",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "Dr Hassan Malik brings a wealth of clinical experience, boasting a three-year tenure within a hospital setting. His expertise extends across critical areas, including Neonatal Intensive Care Unit (NICU), Emergency Room (ER), both general and medical ER, as well as Intensive Care Unit (ICU). Dr. Malik, committed to staying abreast of the latest advancements, recently participated in workshops focusing on Basic Life Support (BLS) and Advanced Cardiovascular Life Support (ACLS). Demonstrating a proficiency in accurate diagnosis and the formulation of optimal treatment plans, Dr. Malik stands out for his strategic approach to healthcare. His commitment to patient well-being is underscored by a blend of empathy and professionalism, ensuring that individuals under his care receive the highest standard of attention and treatment. Dr. Malik's unwavering dedication aligns with the pursuit of excellence in healthcare delivery.",
      "rate": "5",
      "emailDoctor": "dr.hassannawaz@webdoc.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "3474fe94-58a7-46dc-9e44-17256d0dcdda",
      "firstName": "Dr. Sundas Malik",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/WhatsApp Image 2024-12-30 at 12.41.09 PM.jpeg",
      "lastName": " ",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "Dr.Sundas Tahira Malik brings a wealth of clinical experience, boasting a three-year tenure within a hospital setting. His expertise extends across critical areas, including Neonatal Intensive Care Unit (NICU), Emergency Room (ER), both general and medical ER, as well as Intensive Care Unit (ICU). Dr. Malik, committed to staying abreast of the latest advancements, recently participated in workshops focusing on Basic Life Support (BLS) and Advanced Cardiovascular Life Support (ACLS). Demonstrating a proficiency in accurate diagnosis and the formulation of optimal treatment plans, Dr. Malik stands out for his strategic approach to healthcare. His commitment to patient well-being is underscored by a blend of empathy and professionalism, ensuring that individuals under his care receive the highest standard of attention and treatment. Dr. Malik's unwavering dedication aligns with the pursuit of excellence in healthcare delivery.",
      "rate": "5",
      "emailDoctor": "dr.sundastahira@webdocoffice.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "848430ff-2b3b-478f-b4a5-015af23e27c5",
      "firstName": "Dr. Khalid Hussain",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/WhatsApp Image 2024-10-31 at 9.23.48 AM.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "Dr.Khalid Hussain possesses a commendable three years tensure in the field of healthcare within a hospital setting .His professional background includes significant experience in paediatric,Emergency Room(EM),encompassing both general and medical ER ,as well as intensive Care Unit(ICU) .Dr.Khalid Hussain demonstrating a commitment to ongoing professional development ,recently completed workshops in Basic Life Support (BLS) and Advanced Cardiovascular Life Support (ACLS),Proficient in the art precise diagnosis and the formulationof optimal treatment plans ,Dr.Khalid Hussain stands out for his strategic approach to medical care .His professional demeansor,coupled with a genuine sense of empathy,define his commitment to providing patients with the hights standard of care. Dr .Khalid Hussain dedication is marked by a pledge to deliver the best possible healthcare solutions,reflecting his unwavering pursuit of excellence in patient well-being ",
      "rate": "5",
      "emailDoctor": "dr.khalidhussain@webdocoffice.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "Internal Medicine",
      "doctorId": "9f5782f9-6906-4d89-be84-3e8f879cece5",
      "firstName": "Dr Nabeela Jahantab",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/WhatsApp Image 2024-10-08 at 7.37.32 PM.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "A dedicated and compassionate medical doctor committed to delivering patient-centered care through a blend of clinical expertise and empathy. With hands-on experience in both online and offline healthcare environments, I prioritize accurate diagnosis and effective treatment grounded in evidence-based medicine. I am passionate about continuous learning and staying current with the latest advancements in medical science while fostering open, honest communication to build trust and ensure the best outcomes for my patients.",
      "rate": "5",
      "emailDoctor": "dr.nabeela@webdocoffice.com.pk",
      "qualifications": "MBBS",
      "experience": "03 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "a244b17f-6ce5-4dbd-ba5a-0cb3ca92c716",
      "firstName": "Dr.  Rameesha Bakhtawar ",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/Dr. Rameesha.jpeg",
      "lastName": " ",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "Dr. Rameesha completed her house job at Akbar Niazi Teaching Hospital, where she gained comprehensive clinical experience across diverse medical departments. Her training included rotations in Ophthalmology, Dermatology, General Medicine, and General Surgery. This rigorous exposure has equipped her with a well-rounded understanding of various medical disciplines, laying a solid foundation for her professional journey in healthcare.",
      "rate": "5",
      "emailDoctor": "dr.rameeshabakhtawer@webdoc.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "c3aa3675-0ac4-441a-bcc5-3ddacf499699",
      "firstName": "Dr. Muhammad Baqir",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/WhatsApp Image 2024-10-11 at 10.48.34 AM.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "Dr Muhammad Baqir brings a wealth of clinical experience, boasting a two-year tenure within a hospital setting. His expertise extends across critical areas, including Emergency Room (ER), both general and medical ER, as well as Intensive Care Unit (ICU). Dr. Baqir, committed to staying abreast of the latest advancements, recently participated in workshops focusing on Basic Life Support (BLS) and Advanced Cardiovascular Life Support (ACLS). Demonstrating a proficiency in accurate diagnosis and the formulation of optimal treatment plans, Dr. Baqir stands out for his strategic approach to healthcare. His commitment to patient well-being is underscored by a blend of empathy and professionalism, ensuring that individuals under his care receive the highest standard of attention and treatment. Dr. Baqir's unwavering dedication aligns with the pursuit of excellence in healthcare delivery.",
      "rate": "5",
      "emailDoctor": "dr.baqir@webdocoffice.com.pk",
      "qualifications": "MBBS",
      "experience": "03 Years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "d7b8b408-48bc-44c0-aaa7-ebfcb27009a1",
      "firstName": "Dr. Sara Saeed",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/Dr. Sara.jpeg",
      "lastName": " ",
      "country": "Pakistan",
      "isOnline": "1",
      "profileMessage": "Dr. Sara Rizwan, having successfully completed her MBBS and MCPS, brings eight years of dedicated experience acquired through diverse roles in various hospitals and clinics. Her professional journey has included significant contributions to the Emergency Room (ER) department, Gynecology department, proficiency in Basic Ultrasonography (USG), and managing General Outpatient Departments (OPD). Dr. Rizwan is committed to delivering exemplary services to patients, leveraging her expertise and skills acquired over her years of practice. Adept in effective communication and counseling, she ensures that patients receive not only the best medical care but also compassionate and informed guidance. Dr. Rizwan's commitment to providing high-quality healthcare underscores her dedication to the well-being of those she serves.",
      "rate": "5",
      "emailDoctor": "dr.sararizwan@webdocoffice.com.pk",
      "qualifications": "MBBS, MCPS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Medicine",
      "doctorId": "1d37d633-56b7-46a1-97c0-0936d7c267ef",
      "firstName": "Dr. Tariq Saeed Rao",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/Dr. Tariq.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "0",
      "profileMessage": "Dr. Tariq Saeed Rao possesses a wealth of expertise garnered through three years of dedicated service within a hospital setting. His comprehensive experience encompasses the intricate domains of Neonatal Intensive Care Unit (NICU), Emergency Room (ER), including medical ER, and Intensive Care Unit (ICU). Recently, Dr. Tariq Saeed Rao has further enriched his skills through participation in workshops on Basic Life Support (BLS) and Advanced Cardiovascular Life Support (ACLS). His proficiency extends beyond routine clinical duties, as he is adept at accurate diagnosis and formulating optimal treatment plans. Dr. Tariq Saeed Rao is characterized by a commitment to delivering the highest standard of care, underscored by a professional demeanor and an empathetic approach. His unwavering dedication to ensuring the well-being of patients reflects a steadfast commitment to excellence in healthcare.",
      "rate": "5",
      "emailDoctor": "dr.tariqsaeed@webdocoffice.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Medicine",
      "doctorId": "accbcac5-7bfa-40f0-8a6b-a118ab1eb476",
      "firstName": "Dr. Kainat Azam",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/WhatsApp Image 2024-10-28 at 5.51.32 PM.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "0",
      "profileMessage": "Dr Kainat Azam brings a wealth of clinical experience, boasting a three-year tenure within a hospital setting. Her expertise extends across critical areas, including Intensive Care Unit (ICU), Gynea ,Emergency Room (ER), both general and medical ER, as well as Trauma and Emergency. Dr. Kainat, committed to staying abreast of the latest advancements, recently participated in workshops focusing on Basic Life Support (BLS). Demonstrating a proficiency in accurate diagnosis and the formulation of optimal treatment plans, Dr. Kainat  stands out for his strategic approach to healthcare. His commitment to patient well-being is underscored by a blend of empathy and professionalism, ensuring that individuals under her care receive the highest standard of attention and treatment. Dr Kainat's unwavering dedication aligns with the pursuit of excellence in healthcare delivery.",
      "rate": "5",
      "emailDoctor": "dr.kainatazam@webdocoffice.com.pk",
      "qualifications": "mbbs",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "99407019-e023-4023-abc7-d10cc0311c6d",
      "firstName": "Dr. Nazish Ashraf",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/Dr. Nazish.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "0",
      "profileMessage": "Dr. Nazish brings a wealth of diverse clinical experience gained through dedicated service at prestigious healthcare institutions, including Combined Military Hospital and Pak Emirates Military Hospital in Rawalpindi. Her proficiency spans across various medical specialties, encompassing General Medicine, General Surgery, Neuromedicine, Neurosurgery, Emergency Medicine Trauma Centre, Pediatrics, and Obstetrics & Gynecology. Notably, she completed her internship in Emergency Medicine at Shifa International Hospital in Islamabad. Dr. Nazish has demonstrated her commitment to academic excellence by successfully passing the FCPS Part I examination in Medicine and Allied disciplines. Currently, she is actively engaged in the Global Emergency Medicine Program for MRCEM examination UK, a renowned program in the field of Emergency Medicine globally. Renowned for her professional dedication, Dr. Nazish is characterized by her commitment to providing the highest standard of care to patients. Her empathetic approach, coupled with effective communication and counseling skills, underscores her ability to establish meaningful connections with those under her care. Dr. Nazish's comprehensive skill set and ongoing pursuit of professional development position her as an exemplary healthcare practitioner dedicated to the well-being of her patients.",
      "rate": "5",
      "emailDoctor": "dr.nazishashraf@webdoc.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "384b4dde-3d6b-453e-810d-473d3d37eff7",
      "firstName": "Dr. Nabeel Farooq",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/Dr. Nabeel.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "0",
      "profileMessage": "Dr. Nabeel Farooq possesses a commendable three-years tenure in the field of healthcare within a hospital setting. His professional background includes significant experience in Paediatrics, Emergency Room (ER), encompassing both general and medical ER, as well as Intensive Care Unit (ICU). Dr. Nabeel Farooq demonstrating a commitment to ongoing professional development, recently completed workshops in Basic Life Support (BLS) and Advanced Cardiovascular Life Support (ACLS). Proficient in the art of precise diagnosis and the formulation of optimal treatment plans, Dr.Nabeel Farooq stands out for his strategic approach to medical care. His professional demeanor, coupled with a genuine sense of empathy, defines his commitment to providing patients with the highest standard of care. Dr.Nabeel Farooq's dedication is marked by a pledge to deliver the best possible healthcare solutions, reflecting his unwavering pursuit of excellence in patient well-being.",
      "rate": "5",
      "emailDoctor": "dr.nabeelfarooq@webdocoffice.com.pk",
      "qualifications": "MBBS",
      "experience": "3 years"
    },
    {
      "doctorSpecialty": "General Practitioner",
      "doctorId": "2f525bc8-f45b-418d-9372-9ff74eb4ee35",
      "firstName": "Dr. Nereen Awan",
      "imgLink": "https://portal.webdoc.com.pk/doctorprofiles/WhatsApp Image 2025-04-29 at 3.12.55 PM.jpeg",
      "lastName": ".",
      "country": "Pakistan",
      "isOnline": "0",
      "profileMessage": "I have attended BLS and ACLS workshop. Completed housejob from Combined Military Hospital,PEMH Rawalpindi. I have experience working gynae dept, surgery , medical ICU, Emergency medicine, Gastroenterology dept, have knowledge about family medicine. Looking forward to providing healthcare services.",
      "rate": "5",
      "emailDoctor": "dr.nereenawan@webdoc.com.pk",
      "qualifications": "MBBS",
      "experience": "03 Years"
    }
  ];


  Future<void> uploadDoctorDataToFirebase(
      BuildContext context, List<Map<String, dynamic>> doctorList) async {
    try {
      final databaseReference = FirebaseDatabase.instance.ref().child('StaticDoctors');

      for (var doctorData in doctorList) {
        final doctorId = doctorData['doctorId'];
        if (doctorId == null) {
          print("Skipping doctor without doctorId: $doctorData");
          continue;
        }

        try {
          await databaseReference.child(doctorId).set(doctorData);
          print("Uploaded doctor with ID: $doctorId");
        } catch (e) {
          print("Error uploading doctor with ID $doctorId: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                Text('Error uploading doctor with ID $doctorId: $e')),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor data uploaded to Firebase successfully!')),
      );
    } catch (e) {
      print("Error uploading data to Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload doctor data: $e')),
      );
    }
  }
}*/










/*
import 'package:Webdoc/screens/package_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

import '../models/doctor.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import '../widgets/doctor_list_item.dart';
import 'audio_call_screen.dart';
import 'doctor_profile_screen.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true; // Start in the loading state
  bool _hasInternet = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Global.isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        _loadDoctorsAndSetupFirebaseListeners(); // Combine these two operations
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDoctorsAndSetupFirebaseListeners() async {

    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final apiService = ApiService();
    final doctorListResponse = await apiService.getDoctorList(context);

    if (doctorListResponse != null &&
        doctorListResponse.responseCode == '0000') {
      Global.allDoctorsList = doctorListResponse.doctorList ?? [];
      _filteredDoctors = List.from(Global.allDoctorsList);
      _setupFirebaseListeners(); // Set up Firebase listeners before setting isLoading to false
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load doctors')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupFirebaseListeners() {
    Global.databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _updateDoctorStatuses(data);
      }
      setState(() {
        _isLoading = false; // Set isLoading to false after initial data load and listener setup
      });
    });
  }

  void _updateDoctorStatuses(Map<dynamic, dynamic> data) {
    setState(() {
      for (var doctor in Global.allDoctorsList) {
        final emailKey = doctor.emailDoctor?.replaceAll('.', '');
        if (data.containsKey(emailKey)) {
          doctor.isOnline = data[emailKey]['status'];
        }
      }
      _filteredDoctors = List.from(Global.allDoctorsList);
    });
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = List.from(Global.allDoctorsList);
      } else {
        _filteredDoctors = Global.allDoctorsList
            .where((doctor) =>
        (doctor.firstName?.toLowerCase().contains(query.toLowerCase()) ??
            false) ||
            (doctor.lastName?.toLowerCase().contains(query.toLowerCase()) ??
                false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // set background color to white

      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Instant Doctors',
                style: AppStyles.bodyLarge.copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        */
/*bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Doctors',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: _filterDoctors,
            ),
          ),
        ),*//*

      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_isLoading) {
      return _buildLoading();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildNoDoctors();
    }

    return ListView.builder(
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        return DoctorListItem(
          doctor: _filteredDoctors[index],
          isPackageActivated: Global.isPackageActivated,
          onConsultPressed: () {
            Global.docPosition = index;

            if (Global.isPackageActivated) {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: _filteredDoctors[index],
                )
                ),
              );

              */
/*Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                ),
              );*//*

              Global.fromProfile = "list";
            } else {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PackageScreen(), // Navigate to PackageScreen
                ),
              );
            }
          },
          onItemTap: () {
            // This is the new callback
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: _filteredDoctors[index],
              )
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor),
          ),
          const SizedBox(height: 10),
          Text('Doctors loading...', style: AppStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_hospital, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No doctors found.', style: AppStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              _checkInternetConnection();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
*/



