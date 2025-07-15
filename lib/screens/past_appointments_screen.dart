
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/past_appointment_response.dart';
import '../models/upcoming_appointments_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart';
import '../widgets/past_appointments_list.dart';
import '../widgets/upcoming_appointments_list.dart';
import 'dashboard_screen.dart'; // Import your Global class for color

class PastAppointmentsScreen extends StatefulWidget {
  @override
  _PastAppointmentsScreenState createState() => _PastAppointmentsScreenState();
}

class _PastAppointmentsScreenState extends State<PastAppointmentsScreen> {
  List<Appointment> _pastAppointments = [];
  List<UpcomingAppointment> _upcomingAppointments = [];
  bool _isLoading = true;
  bool _hasInternet = true;

  // Pagination variables
  int _upcomingPage = 1;
  int _pastPage = 1;
  bool _isLoadingMoreUpcoming = false;
  bool _isLoadingMorePast = false;
  bool _hasMoreUpcoming = true;
  bool _hasMorePast = true;

  final ApiService _apiService = ApiService();
  final String _patientId = SharedPreferencesManager.getString("id") ?? "";
  final ScrollController _scrollController = ScrollController();

  Timer? _refreshTimer; // Timer for background refresh

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);

    // Start the background refresh timer
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _stopRefreshTimer(); // Stop the timer when the screen is disposed
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _backgroundRefresh();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _upcomingPage = 1; // Reset page on initial load
      _pastPage = 1; // Reset page on initial load
      _hasMoreUpcoming = true;
      _hasMorePast = true;
    });

    _hasInternet = await ApiService.isInternetAvailable();

    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load both upcoming and past appointments concurrently
      await Future.wait([
        _loadUpcomingAppointments(page: 1), // Load first page
        _loadPastAppointments(page: 1), // Load first page
      ]);
    } catch (e) {
      print("Error loading appointments: $e");
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Background refresh function
  Future<void> _backgroundRefresh() async {
    if (!mounted) return; // Check if the widget is still in the tree

    bool hasInternet = await ApiService.isInternetAvailable();
    if (!hasInternet) {
      // Handle no internet case if needed
      return;
    }

    try {
      // Load  upcoming appointments

      final UpcomingAppointmentsResponse? upcomingResponse =
      await _apiService.getUpcomingAppointments(patientId: _patientId, page: 1);


      if (upcomingResponse != null && upcomingResponse.payLoad != null) {
        if (!listEquals(_upcomingAppointments, upcomingResponse.payLoad)) {
          setState(() {
            _upcomingAppointments = upcomingResponse.payLoad!.cast<UpcomingAppointment>().toList();
          });
        }

        setState(() {
          _hasMoreUpcoming = upcomingResponse.payLoad!.length == 10;
          _upcomingPage = 1;
        });
      } else {
        setState(() {
          _hasMoreUpcoming = false;
        });
      }


      /*
      // commented past appointment refresh
      if (pastResponse != null && pastResponse.payLoad != null) {
        if (!listEquals(_pastAppointments, pastResponse.payLoad)) {
          setState(() {
            _pastAppointments = pastResponse.payLoad!.cast<Appointment>().toList();
          });
        }

        setState(() {
          _hasMorePast = pastResponse.payLoad!.length == 10;
          _pastPage = 1;
        });
      } else {
        setState(() {
          _hasMorePast = false;
        });
      }
      */



    } catch (e) {
      print("Error refreshing appointments: $e");
      // Optionally log the error or handle it silently
    }
  }

  Future<void> _loadMoreData() async {
    // Load more upcoming appointments if available
    if (_hasMoreUpcoming && !_isLoadingMoreUpcoming) {
      _loadUpcomingAppointments(page: _upcomingPage + 1);
    }

    // Load more past appointments if available
    if (_hasMorePast && !_isLoadingMorePast) {
      _loadPastAppointments(page: _pastPage + 1);
    }
  }

  Future<void> _loadUpcomingAppointments({int page = 1}) async {
    if (page == 1) {
      _upcomingAppointments = []; // Clear existing data on first page load
    }
    setState(() {
      if (page > 1) {
        _isLoadingMoreUpcoming = true;
      }
    });

    try {
      final appointmentsResponse = await _apiService
          .getUpcomingAppointments(patientId: _patientId, page: page);

      if (appointmentsResponse != null && appointmentsResponse.payLoad != null) {
        setState(() {
          if (page == 1) {
            _upcomingAppointments =
                appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList();
          } else {
            _upcomingAppointments.addAll(
                appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList());
          }
          if (appointmentsResponse.payLoad!.length < 10) {
            // Assuming perPage is 10
            _hasMoreUpcoming = false;
          } else {
            _upcomingPage = page;
          }
        });
      } else {
        print("No upcoming appointments found or error occurred.");
        setState(() {
          _hasMoreUpcoming = false;
        });
      }
    } catch (e) {
      print("Error loading upcoming appointments: $e");
      setState(() {
        _hasMoreUpcoming = false;
      });
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoadingMoreUpcoming = false;
      });
    }
  }

  Future<void> _loadPastAppointments({int page = 1}) async {
    if (page == 1) {
      _pastAppointments = []; // Clear existing data on first page load
    }
    setState(() {
      if (page > 1) {
        _isLoadingMorePast = true;
      }
    });

    try {
      final pastAppointmentsResponse = await _apiService
          .getPastAppointments(patientId: _patientId, page: page);

      if (pastAppointmentsResponse != null &&
          pastAppointmentsResponse.payLoad != null) {
        setState(() {
          if (page == 1) {
            _pastAppointments =
                pastAppointmentsResponse.payLoad!.cast<Appointment>().toList();
          } else {
            _pastAppointments.addAll(
                pastAppointmentsResponse.payLoad!.cast<Appointment>().toList());
          }

          if (pastAppointmentsResponse.payLoad!.length < 10) {
            // Assuming perPage is 10
            _hasMorePast = false;
          } else {
            _pastPage = page;
          }
        });
      } else {
        print("No past appointments found or error occurred.");
        setState(() {
          _hasMorePast = false;
        });
      }
    } catch (e) {
      print("Error loading past appointments: $e");
      setState(() {
        _hasMorePast = false;
      });
    } finally {
      setState(() {
        _isLoadingMorePast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 16,
                )),
            Text('Appointments',
                style: AppStyles.bodyLarge(context)
                    .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Text('Loading Appointments...', style: AppStyles.bodyMedium(context)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, left: 16.0), // Added margin
            child: Text(
              'Upcoming Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          UpcomingAppointmentsList(appointments: _upcomingAppointments),
          if (_isLoadingMoreUpcoming)
            const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                )),

          Container(
            margin: const EdgeInsets.only(top: 8.0, left: 16.0), // Added margin
            child: Text(
              'Previous Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PastAppointmentsList(appointments: _pastAppointments),

          if (_isLoadingMorePast)
            const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                )),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.signal_wifi_off,
              size: 50, color: AppColors.secondaryTextColor),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              _hasInternet = await ApiService.isInternetAvailable();
              if (_hasInternet) {
                _loadData();
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
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
}

// Helper function for comparing lists
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/*
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/past_appointment_response.dart';
import '../models/upcoming_appointments_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart';
import '../widgets/past_appointments_list.dart';
import '../widgets/upcoming_appointments_list.dart';
import 'dashboard_screen.dart'; // Import your Global class for color

class PastAppointmentsScreen extends StatefulWidget {
  @override
  _PastAppointmentsScreenState createState() => _PastAppointmentsScreenState();
}

class _PastAppointmentsScreenState extends State<PastAppointmentsScreen> {
  List<Appointment> _pastAppointments = [];
  List<UpcomingAppointment> _upcomingAppointments = [];
  bool _isLoading = true;
  bool _hasInternet = true;

  // Pagination variables
  int _upcomingPage = 1;
  int _pastPage = 1;
  bool _isLoadingMoreUpcoming = false;
  bool _isLoadingMorePast = false;
  bool _hasMoreUpcoming = true;
  bool _hasMorePast = true;

  final ApiService _apiService = ApiService();
  final String _patientId = SharedPreferencesManager.getString("id") ?? "";
  final ScrollController _scrollController = ScrollController();

  Timer? _refreshTimer; // Timer for background refresh

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);

    // Start the background refresh timer
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _stopRefreshTimer(); // Stop the timer when the screen is disposed
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _backgroundRefresh();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _upcomingPage = 1; // Reset page on initial load
      _pastPage = 1; // Reset page on initial load
      _hasMoreUpcoming = true;
      _hasMorePast = true;
    });

    _hasInternet = await ApiService.isInternetAvailable();

    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load both upcoming and past appointments concurrently
      await Future.wait([
        _loadUpcomingAppointments(page: 1), // Load first page
        _loadPastAppointments(page: 1), // Load first page
      ]);
    } catch (e) {
      print("Error loading appointments: $e");
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Background refresh function
  Future<void> _backgroundRefresh() async {
    if (!mounted) return; // Check if the widget is still in the tree

    bool hasInternet = await ApiService.isInternetAvailable();
    if (!hasInternet) {
      // Handle no internet case if needed
      return;
    }

    try {
      // Load both upcoming and past appointments concurrently
      final List<dynamic> results = await Future.wait([
        _apiService.getUpcomingAppointments(patientId: _patientId, page: 1),
        _apiService.getPastAppointments(patientId: _patientId, page: 1),
      ]);

      final UpcomingAppointmentsResponse? upcomingResponse = results[0] as UpcomingAppointmentsResponse?;
      final PastAppointmentsResponse? pastResponse = results[1] as PastAppointmentsResponse?;


      if (upcomingResponse != null && upcomingResponse.payLoad != null) {
        if (!listEquals(_upcomingAppointments, upcomingResponse.payLoad)) {
          setState(() {
            _upcomingAppointments = upcomingResponse.payLoad!.cast<UpcomingAppointment>().toList();
          });
        }

        setState(() {
          _hasMoreUpcoming = upcomingResponse.payLoad!.length == 10;
          _upcomingPage = 1;
        });
      } else {
        setState(() {
          _hasMoreUpcoming = false;
        });
      }


      if (pastResponse != null && pastResponse.payLoad != null) {
        if (!listEquals(_pastAppointments, pastResponse.payLoad)) {
          setState(() {
            _pastAppointments = pastResponse.payLoad!.cast<Appointment>().toList();
          });
        }

        setState(() {
          _hasMorePast = pastResponse.payLoad!.length == 10;
          _pastPage = 1;
        });
      } else {
        setState(() {
          _hasMorePast = false;
        });
      }



    } catch (e) {
      print("Error refreshing appointments: $e");
      // Optionally log the error or handle it silently
    }
  }

  Future<void> _loadMoreData() async {
    // Load more upcoming appointments if available
    if (_hasMoreUpcoming && !_isLoadingMoreUpcoming) {
      _loadUpcomingAppointments(page: _upcomingPage + 1);
    }

    // Load more past appointments if available
    if (_hasMorePast && !_isLoadingMorePast) {
      _loadPastAppointments(page: _pastPage + 1);
    }
  }

  Future<void> _loadUpcomingAppointments({int page = 1}) async {
    if (page == 1) {
      _upcomingAppointments = []; // Clear existing data on first page load
    }
    setState(() {
      if (page > 1) {
        _isLoadingMoreUpcoming = true;
      }
    });

    try {
      final appointmentsResponse = await _apiService
          .getUpcomingAppointments(patientId: _patientId, page: page);

      if (appointmentsResponse != null && appointmentsResponse.payLoad != null) {
        setState(() {
          if (page == 1) {
            _upcomingAppointments =
                appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList();
          } else {
            _upcomingAppointments.addAll(
                appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList());
          }
          if (appointmentsResponse.payLoad!.length < 10) {
            // Assuming perPage is 10
            _hasMoreUpcoming = false;
          } else {
            _upcomingPage = page;
          }
        });
      } else {
        print("No upcoming appointments found or error occurred.");
        setState(() {
          _hasMoreUpcoming = false;
        });
      }
    } catch (e) {
      print("Error loading upcoming appointments: $e");
      setState(() {
        _hasMoreUpcoming = false;
      });
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoadingMoreUpcoming = false;
      });
    }
  }

  Future<void> _loadPastAppointments({int page = 1}) async {
    if (page == 1) {
      _pastAppointments = []; // Clear existing data on first page load
    }
    setState(() {
      if (page > 1) {
        _isLoadingMorePast = true;
      }
    });

    try {
      final pastAppointmentsResponse = await _apiService
          .getPastAppointments(patientId: _patientId, page: page);

      if (pastAppointmentsResponse != null &&
          pastAppointmentsResponse.payLoad != null) {
        setState(() {
          if (page == 1) {
            _pastAppointments =
                pastAppointmentsResponse.payLoad!.cast<Appointment>().toList();
          } else {
            _pastAppointments.addAll(
                pastAppointmentsResponse.payLoad!.cast<Appointment>().toList());
          }

          if (pastAppointmentsResponse.payLoad!.length < 10) {
            // Assuming perPage is 10
            _hasMorePast = false;
          } else {
            _pastPage = page;
          }
        });
      } else {
        print("No past appointments found or error occurred.");
        setState(() {
          _hasMorePast = false;
        });
      }
    } catch (e) {
      print("Error loading past appointments: $e");
      setState(() {
        _hasMorePast = false;
      });
    } finally {
      setState(() {
        _isLoadingMorePast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 16,
                )),
            Text('Appointments',
                style: AppStyles.bodyLarge(context)
                    .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Text('Loading Appointments...', style: AppStyles.bodyMedium(context)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, left: 16.0), // Added margin
            child: Text(
              'Upcoming Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          UpcomingAppointmentsList(appointments: _upcomingAppointments),
          if (_isLoadingMoreUpcoming)
            const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                )),

          Container(
            margin: const EdgeInsets.only(top: 8.0, left: 16.0), // Added margin
            child: Text(
              'Previous Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PastAppointmentsList(appointments: _pastAppointments),

          if (_isLoadingMorePast)
            const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                )),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.signal_wifi_off,
              size: 50, color: AppColors.secondaryTextColor),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              _hasInternet = await ApiService.isInternetAvailable();
              if (_hasInternet) {
                _loadData();
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
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
}

// Helper function for comparing lists
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
*/






/*import 'package:flutter/material.dart';
import '../models/past_appointment_response.dart';
import '../models/upcoming_appointments_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart';
import '../widgets/past_appointments_list.dart';
import '../widgets/upcoming_appointments_list.dart';
import 'dashboard_screen.dart'; // Import your Global class for color

class PastAppointmentsScreen extends StatefulWidget {
  @override
  _PastAppointmentsScreenState createState() => _PastAppointmentsScreenState();
}

class _PastAppointmentsScreenState extends State<PastAppointmentsScreen> {
  List<Appointment> _pastAppointments = [];
  List<UpcomingAppointment> _upcomingAppointments = [];
  bool _isLoading = true;
  bool _hasInternet = true;

  // Pagination variables
  int _upcomingPage = 1;
  int _pastPage = 1;
  bool _isLoadingMoreUpcoming = false;
  bool _isLoadingMorePast = false;
  bool _hasMoreUpcoming = true;
  bool _hasMorePast = true;

  final ApiService _apiService = ApiService();
  final String _patientId = SharedPreferencesManager.getString("id") ?? "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _upcomingPage = 1; // Reset page on initial load
      _pastPage = 1; // Reset page on initial load
      _hasMoreUpcoming = true;
      _hasMorePast = true;
    });

    _hasInternet = await ApiService.isInternetAvailable();

    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load both upcoming and past appointments concurrently
      await Future.wait([
        _loadUpcomingAppointments(page: 1), // Load first page
        _loadPastAppointments(page: 1), // Load first page
      ]);
    } catch (e) {
      print("Error loading appointments: $e");
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    // Load more upcoming appointments if available
    if (_hasMoreUpcoming && !_isLoadingMoreUpcoming) {
      _loadUpcomingAppointments(page: _upcomingPage + 1);
    }

    // Load more past appointments if available
    if (_hasMorePast && !_isLoadingMorePast) {
      _loadPastAppointments(page: _pastPage + 1);
    }
  }

  Future<void> _loadUpcomingAppointments({int page = 1}) async {
    if (page == 1) {
      _upcomingAppointments = []; // Clear existing data on first page load
    }
    setState(() {
      if (page > 1) {
        _isLoadingMoreUpcoming = true;
      }
    });

    try {
      final appointmentsResponse = await _apiService
          .getUpcomingAppointments(patientId: _patientId, page: page);

      if (appointmentsResponse != null && appointmentsResponse.payLoad != null) {
        setState(() {
          if (page == 1) {
            _upcomingAppointments =
                appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList();
          } else {
            _upcomingAppointments.addAll(
                appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList());
          }
          if (appointmentsResponse.payLoad!.length < 10) {
            // Assuming perPage is 10
            _hasMoreUpcoming = false;
          } else {
            _upcomingPage = page;
          }
        });
      } else {
        print("No upcoming appointments found or error occurred.");
        setState(() {
          _hasMoreUpcoming = false;
        });
      }
    } catch (e) {
      print("Error loading upcoming appointments: $e");
      setState(() {
        _hasMoreUpcoming = false;
      });
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoadingMoreUpcoming = false;
      });
    }
  }

  Future<void> _loadPastAppointments({int page = 1}) async {
    if (page == 1) {
      _pastAppointments = []; // Clear existing data on first page load
    }
    setState(() {
      if (page > 1) {
        _isLoadingMorePast = true;
      }
    });

    try {
      final pastAppointmentsResponse = await _apiService
          .getPastAppointments(patientId: _patientId, page: page);

      if (pastAppointmentsResponse != null &&
          pastAppointmentsResponse.payLoad != null) {
        setState(() {
          if (page == 1) {
            _pastAppointments =
                pastAppointmentsResponse.payLoad!.cast<Appointment>().toList();
          } else {
            _pastAppointments.addAll(
                pastAppointmentsResponse.payLoad!.cast<Appointment>().toList());
          }

          if (pastAppointmentsResponse.payLoad!.length < 10) {
            // Assuming perPage is 10
            _hasMorePast = false;
          } else {
            _pastPage = page;
          }
        });
      } else {
        print("No past appointments found or error occurred.");
        setState(() {
          _hasMorePast = false;
        });
      }
    } catch (e) {
      print("Error loading past appointments: $e");
      setState(() {
        _hasMorePast = false;
      });
    } finally {
      setState(() {
        _isLoadingMorePast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 16,
                )),
            Text('Appointments',
                style: AppStyles.bodyLarge(context)
                    .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Text('Loading Appointments...', style: AppStyles.bodyMedium(context)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, left: 16.0), // Added margin
            child: Text(
              'Upcoming Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          UpcomingAppointmentsList(appointments: _upcomingAppointments),
          if (_isLoadingMoreUpcoming)
            const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                )),

          Container(
            margin: const EdgeInsets.only(top: 8.0, left: 16.0), // Added margin
            child: Text(
              'Previous Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PastAppointmentsList(appointments: _pastAppointments),

          if (_isLoadingMorePast)
            const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                )),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.signal_wifi_off,
              size: 50, color: AppColors.secondaryTextColor),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              _hasInternet = await ApiService.isInternetAvailable();
              if (_hasInternet) {
                _loadData();
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
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
}*/





/*import 'package:flutter/material.dart';
import '../models/past_appointment_response.dart';
import '../models/upcoming_appointments_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import '../utils/global.dart';
import '../widgets/past_appointments_list.dart';
import '../widgets/upcoming_appointments_list.dart';
import 'dashboard_screen.dart'; // Import your Global class for color



class PastAppointmentsScreen extends StatefulWidget {
  @override
  _PastAppointmentsScreenState createState() => _PastAppointmentsScreenState();
}

class _PastAppointmentsScreenState extends State<PastAppointmentsScreen> {
  List<Appointment> _pastAppointments = [];
  List<UpcomingAppointment> _upcomingAppointments = [];
  bool _isLoading = true;
  bool _hasInternet = true;
  final ApiService _apiService = ApiService();
  final String _patientId = SharedPreferencesManager.getString("id") ?? "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _hasInternet = await ApiService.isInternetAvailable();

    if (!_hasInternet) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load both upcoming and past appointments concurrently
      await Future.wait([
        _loadUpcomingAppointments(),
        _loadPastAppointments(),
      ]);
    } catch (e) {
      print("Error loading appointments: $e");
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingAppointments() async {
    try {
      final appointmentsResponse = await _apiService.getUpcomingAppointments(patientId: _patientId);

      if (appointmentsResponse != null && appointmentsResponse.payLoad != null) {
        setState(() {
          _upcomingAppointments = appointmentsResponse.payLoad!.cast<UpcomingAppointment>().toList();
        });
      } else {
        print("No upcoming appointments found or error occurred.");
      }
    } catch (e) {
      print("Error loading upcoming appointments: $e");
      // Optionally show an error message to the user
    }
  }

  Future<void> _loadPastAppointments() async {
    try {
      final pastAppointmentsResponse = await _apiService.getPastAppointments(patientId: _patientId);

      if (pastAppointmentsResponse != null && pastAppointmentsResponse.payLoad != null) {
        setState(() {
          _pastAppointments = pastAppointmentsResponse.payLoad!.cast<Appointment>().toList();
        });
      } else {
        print("No past appointments found or error occurred.");
      }
    } catch (e) {
      print("Error loading past appointments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Appointments',
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Text('Loading Appointments...', style: AppStyles.bodyMedium(context)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, left: 16.0), // Added margin
            child: Text(
              'Upcoming Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          UpcomingAppointmentsList(appointments: _upcomingAppointments),
          Container(
            margin: const EdgeInsets.only(top: 8.0, left: 16.0), // Added margin
            child: Text(
              'Previous Appointments',
              style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PastAppointmentsList(appointments: _pastAppointments),
        ],
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.signal_wifi_off, size: 50, color: AppColors.secondaryTextColor),
          const SizedBox(height: 10),
          Text('No internet connection.', style: AppStyles.bodyMedium(context)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              _hasInternet = await ApiService.isInternetAvailable();
              if (_hasInternet) {
                _loadData();
              } else {
                setState(() {
                  _isLoading = false;
                });
              }
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
}*/


