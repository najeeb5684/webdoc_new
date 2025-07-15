import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../models/prescription_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import '../widgets/prescription_history_item.dart';
import 'dashboard_screen.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({Key? key}) : super(key: key);

  @override
  _PrescriptionScreenState createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final ApiService _apiService = ApiService();
  String userId = '';
  int _pageNumber = 1;
  final int _pageSize = 10;
  bool _isLoading = true; // Start in the loading state
  bool _hasInternet = true;
  bool _isLastPage = false;
  List<Consultation> _consultations = [];
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    userId = SharedPreferencesManager.getString('id') ?? 'ID';
   // userId = 'd33fe352-ddd4-4040-a370-d3dedcbaf73c';
    _checkInternetConnection();
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
      if (!_isLoading && !_isLastPage && _hasInternet) {
        _loadPrescriptions();
      }
    }
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
          _isLoading = false; // Set isLoading to false after successful check
        });
        _loadPrescriptions();
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false; // Set isLoading to false on error
      });
    }
  }

  Future<void> _loadPrescriptions() async {
    if (_isLoading || _isLastPage || !_hasInternet) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PrescriptionResponse? response = await _apiService.getPrescription(context,
          userId, _pageNumber, _pageSize);

      setState(() {
        _isLoading = false;
      });

      if (response != null &&
          response.responseCode == '0000' &&
          response.consultationList != null) {
        if (response.consultationList!.isEmpty) {
          setState(() {
            _isLastPage = true;
          });
        } else {
          setState(() {
            _consultations.addAll(response.consultationList!);
            if (response.consultationList!.length < _pageSize) {
              _isLastPage = true;
            } else {
              _pageNumber++;
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?.message ?? 'Failed to load prescriptions.')),
        );
        setState(() {
          _errorMessage = response?.message ?? 'Failed to load prescriptions.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
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
                'Prescription',
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

    if (_isLoading && _consultations.isEmpty) {
      return _buildLoading();
    }

    if (_consultations.isEmpty) {
      return _buildNoPrescriptions();
    }

    return RefreshIndicator( // Wrap ListView.builder with RefreshIndicator
      onRefresh: _refreshPrescriptions,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _consultations.length + (_isLastPage ? 0 : 1),
        itemBuilder: (context, index) {
          if (index < _consultations.length) {
            final consultation = _consultations[index];
            return PrescriptionHistoryItem(consultation: consultation);
          } else {
            return Center(
              child:  CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor),
              ),
            );
          }
        },
      ),
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
          Text('Prescription loading...', style: AppStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  Widget _buildNoPrescriptions() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.healing, size: 50, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text('No prescriptions found.', style: AppStyles.bodyMedium(context)),
                ],
              ),
            ),
          ),
        );
      },
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

  // Add a function to reload the prescriptions data:
  Future<void> _refreshPrescriptions() async {
    setState(() {
      _isLoading = true;
      _isLastPage = false;
      _pageNumber = 1;
      _consultations.clear();
    });
    await _checkInternetConnection(); //Recheck the internet connection
    // _loadPrescriptions(); This gets called from within _checkInternetConnection now if there's a connection
  }
}