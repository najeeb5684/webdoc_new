
import 'dart:io';
import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:Webdoc/screens/specialist_doctor_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../widgets/specialist_doctor_list_item.dart';
import 'dashboard_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final int? specialityId; // Receive the ID

  const AppointmentScreen({Key? key, this.specialityId}) : super(key: key);

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final ApiService apiService = ApiService();
  List<Doctor> _doctors = [];
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInternet = true;
  String? _errorMessage;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _scrollController.addListener(_onScroll);

    // Call _loadDoctors immediately after initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors(initialLoad: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        _loadDoctors(initialLoad: true); // Load doctors after internet check
      } else {
        setState(() {
          _hasInternet = false;
          _isInitialLoading = false; // Ensure loading indicator is hidden
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isInitialLoading = false; // Ensure loading indicator is hidden
      });
    }
  }

  Future<void> _loadDoctors({bool initialLoad = false}) async {
    if (!_hasInternet) return;

    if (initialLoad) {
      setState(() {
        _isInitialLoading = true;
        _doctors.clear();
        _currentPage = 1;
        _hasMoreData = true;
        _errorMessage = null; // Clear any previous error message
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final doctorsResponse = await apiService.getDoctors(
        context,
        page: _currentPage,
        perPage: _perPage,
        speciality: widget.specialityId ?? 0, // Use widget.specialityId
      );

      if (doctorsResponse != null && doctorsResponse.isNotEmpty) {
        final newDoctors = doctorsResponse.first.payLoad ?? [];
        setState(() {
          if (initialLoad) {
            _doctors = newDoctors;
          } else {
            _doctors.addAll(newDoctors);
          }
          _hasMoreData = newDoctors.length == _perPage;
        });
      } else {
        setState(() {
          _hasMoreData = false;
          if (initialLoad) {
            _errorMessage = "No doctors found";
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load doctors: $e';
        _hasMoreData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors: $e')),
      );
    } finally {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            200 && // Adjusted for early loading
        !_isLoadingMore &&
        _hasMoreData &&
        !_isInitialLoading &&
        _hasInternet) {
      _currentPage++;
      _loadDoctors();
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Doctor> get _filteredDoctors {
    if (_searchQuery.isEmpty) {
      return _doctors;
    } else {
      return _doctors.where((doctor) {
        return doctor.firstName!.toLowerCase().contains(_searchQuery) ||
            doctor.lastName!.toLowerCase().contains(_searchQuery) ||
            (doctor.doctorSpecialties
                ?.toLowerCase()
                .contains(_searchQuery) ??
                false);
      }).toList();
    }
  }

  Widget _buildDoctorList() {
    if (_isInitialLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Text('Loading doctors...', style: AppStyles.bodyMedium(context)),
          ],
        ),
      );
    }

    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_errorMessage != null) {
      return _buildErrorMessage();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildNoDoctors();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredDoctors.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _filteredDoctors.length) {
          final doctor = _filteredDoctors[index];
          return SpecialistDoctorListItem(
            doctor: doctor,
            onConsultPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDoctorProfileScreen(
                    doctor: doctor,
                  ),
                ),
              );
            },
            onItemTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDoctorProfileScreen(doctor: doctor),
                ),
              );
            },
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No internet connection.',
              style: AppStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No doctors found.',
              style: AppStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        centerTitle: false,
        title: Text(
          "Specialist Doctors",
          style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () =>
          /*    Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          ),*/
          Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isSearchFocused = hasFocus;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 1.0,
                    style: BorderStyle.solid,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  cursorColor: AppColors.primaryColor,
                  decoration: InputDecoration(
                    hintText: 'Search Doctors',
                    prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterDoctors('');
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  onChanged: _filterDoctors,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildDoctorList(),
    );
  }
}



/*import 'dart:io';
import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:Webdoc/screens/specialist_doctor_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../widgets/specialist_doctor_list_item.dart';
import 'book_slot_screen.dart';
import 'dashboard_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final int? specialityId; // Receive the ID

  const AppointmentScreen({Key? key, this.specialityId}) : super(key: key);

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final ApiService apiService = ApiService();
  List<Doctor> _doctors = [];
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInternet = true;
  String? _errorMessage;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _scrollController.addListener(_onScroll);

    // Call _loadDoctors immediately after initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors(initialLoad: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        //_loadDoctors(initialLoad: true); // Load doctors after internet check
      } else {
        setState(() {
          _hasInternet = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
      });
    } finally {
      //  setState(() {
      //   _isInitialLoading = false;
      // });
    }
  }

  Future<void> _loadDoctors({bool initialLoad = false}) async {
    if (!_hasInternet) return;

    if (initialLoad) {
      setState(() {
        _isInitialLoading = true;
        _doctors.clear();
        _currentPage = 1;
        _hasMoreData = true;
        _errorMessage = null; // Clear any previous error message
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final doctorsResponse = await apiService.getDoctors(
        context,
        page: _currentPage,
        perPage: _perPage,
        speciality: widget.specialityId ?? 0, // Use widget.specialityId
      );

      if (doctorsResponse != null && doctorsResponse.isNotEmpty) {
        final newDoctors = doctorsResponse.first.payLoad ?? [];
        setState(() {
          if (initialLoad) {
            _doctors = newDoctors;
          } else {
            _doctors.addAll(newDoctors);
          }
          _hasMoreData = newDoctors.length == _perPage;
        });
      } else {
        setState(() {
          _hasMoreData = false;
          if (initialLoad) {
            _errorMessage = "No doctors found";
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load doctors: $e';
        _hasMoreData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors: $e')),
      );
    } finally {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            200 && // Adjusted for early loading
        !_isLoadingMore &&
        _hasMoreData &&
        !_isInitialLoading &&
        _hasInternet) {
      _currentPage++;
      _loadDoctors();
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Doctor> get _filteredDoctors {
    if (_searchQuery.isEmpty) {
      return _doctors;
    } else {
      return _doctors.where((doctor) {
        return doctor.firstName!.toLowerCase().contains(_searchQuery) ||
            doctor.lastName!.toLowerCase().contains(_searchQuery) ||
            (doctor.doctorSpecialties
                ?.toLowerCase()
                .contains(_searchQuery) ??
                false);
      }).toList();
    }
  }

  Widget _buildDoctorList() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_errorMessage != null) {
      return _buildErrorMessage();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildNoDoctors();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredDoctors.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _filteredDoctors.length) {
          final doctor = _filteredDoctors[index];
          return SpecialistDoctorListItem(
            doctor: doctor,
            onConsultPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDoctorProfileScreen(
                    doctor: doctor,
                  ),
                ),
              );
            },
            onItemTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDoctorProfileScreen(doctor: doctor),
                ),
              );
            },
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
      },
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No internet connection.',
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checkInternetConnection,
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
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No doctors found.',
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        centerTitle: false,
        title: Text(
          "Specialist Doctors",
          style: AppStyles.bodyLarge.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isSearchFocused = hasFocus;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 1.0,
                    style: BorderStyle.solid,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  cursorColor: AppColors.primaryColor,
                  decoration: InputDecoration(
                    hintText: 'Search Doctors',
                    prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterDoctors('');
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  onChanged: _filterDoctors,
                ),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _isInitialLoading
            ? Center(
            child: CircularProgressIndicator(color: Colors.black)) // Show loading indicator
            : _buildDoctorList(),
      ),
    );
  }
}*/




/*
import 'package:Webdoc/models/specialist_category_response.dart';
import 'package:Webdoc/screens/specialist_doctor_profile_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../models/specialist_doctors_response.dart';
import '../services/api_service.dart';
import '../theme/app_styles.dart'; // Assuming you have this
import '../widgets/specialist_doctor_list_item.dart';
import 'book_slot_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({Key? key}) : super(key: key);

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final ApiService apiService = ApiService();
  List<Doctor> _doctors = [];
  List<SpecialistCategory> _categories = [];
  int? _selectedSpecialityId;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInternet = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        await _loadInitialData(); // Only load if internet is available
      } else {
        setState(() {
          _hasInternet = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadDoctors(initialLoad: true);
  }

  Future<void> _loadCategories() async {
    final categoriesResponse = await apiService.getSpecialistCategories(context);
    if (categoriesResponse != null && categoriesResponse.isNotEmpty) {
      setState(() {
        _categories = categoriesResponse.first.payLoad ?? [];
      });
    }
  }

  Future<void> _loadDoctors({bool initialLoad = false}) async {
    if (!_hasInternet) return;

    if (initialLoad) {
      setState(() {
        _isInitialLoading = true;
        _doctors.clear();
        _currentPage = 1;
        _hasMoreData = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final doctorsResponse = await apiService.getDoctors(
        context,
        page: _currentPage,
        perPage: _perPage,
        speciality: _selectedSpecialityId ?? 0,
      );

      if (doctorsResponse != null && doctorsResponse.isNotEmpty) {
        final newDoctors = doctorsResponse.first.payLoad ?? [];
        setState(() {
          if (initialLoad) {
            _doctors = newDoctors;
          } else {
            _doctors.addAll(newDoctors);
          }
          _hasMoreData = newDoctors.length == _perPage;
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load doctors: $e';
        _hasMoreData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors: $e')),
      );
    } finally {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isInitialLoading &&
        _hasInternet) {
      _currentPage++;
      _loadDoctors();
    }
  }

  void _onSpecialitySelected(int? id) {
    setState(() {
      _selectedSpecialityId = id;
      _currentPage = 1;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadDoctors(initialLoad: true);
  }

  void _filterDoctors(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Doctor> get _filteredDoctors {
    if (_searchQuery.isEmpty) {
      return _doctors;
    } else {
      return _doctors.where((doctor) {
        return doctor.firstName!.toLowerCase().contains(_searchQuery) ||
            doctor.lastName!.toLowerCase().contains(_searchQuery) ||
            (doctor.doctorSpecialties?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  Widget _buildDoctorList() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildNoDoctors();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredDoctors.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _filteredDoctors.length) {
          final doctor = _filteredDoctors[index];
          return SpecialistDoctorListItem(
            doctor: doctor,
            onConsultPressed: () {
             */
/* Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDoctorProfileScreen(doctor: doctor),
                ),
              );*//*


              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookSlotScreen(
                    doctor: doctor,
                  ),
                ),
              );
            },
            onItemTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDoctorProfileScreen(doctor: doctor),
                ),
              );
            },
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
      },
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No internet connection.',
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checkInternetConnection,
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
      ),
    );
  }

  Widget _buildNoDoctors() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No doctors found.',
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Speciality',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: _selectedSpecialityId,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('All Doctors'),
                    ),
                    ..._categories.map((category) => DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.description ?? ''),
                    )),
                  ],
                  onChanged: _onSpecialitySelected,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Doctors',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: _filterDoctors,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildDoctorList(),
    );
  }
}

*/
