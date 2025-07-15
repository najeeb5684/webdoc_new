
import 'dart:io';

import 'package:Webdoc/models/specialist_category_response.dart';
import 'package:Webdoc/screens/appointment_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class SpecialistCategoryScreen extends StatefulWidget {
  const SpecialistCategoryScreen({Key? key}) : super(key: key);

  @override
  _SpecialistCategoryScreenState createState() => _SpecialistCategoryScreenState();
}

class _SpecialistCategoryScreenState extends State<SpecialistCategoryScreen> {
  final ApiService apiService = ApiService();
  List<SpecialistCategory> _categories = [];
  bool _isLoading = true;
  bool _hasInternet = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasInternet = true; // Assume internet initially
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        _loadCategories(); // Load categories after internet check
      } else {
        setState(() {
          _hasInternet = false;
          _isLoading = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }


  Future<void> _loadCategories() async {
    if (!_hasInternet) return; // Don't load if no internet

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      final categoriesResponse = await apiService.getSpecialistCategories(context);

      if (categoriesResponse != null && categoriesResponse.isNotEmpty) {
        setState(() {
          _categories = categoriesResponse.first.payLoad ?? [];
        });
      } else {
        setState(() {
          _errorMessage = "No categories found.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load categories: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoryCard(SpecialistCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentScreen(specialityId: category.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            category.imageLink != null
                ? Image.network(
              category.imageLink!,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              color: AppColors.primaryColor,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error_outline, color: Colors.red, size: 30);
              },
            )
                : Icon(Icons.image_not_supported, color: AppColors.primaryColor, size: 30),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Text(
                category.description ?? "N/A",
                style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
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
            Text('Loading categories...', style: AppStyles.bodyMedium(context)),
          ],
        ),
      );
    }

    if (!_hasInternet) {
      return _buildNoInternet();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(_categories[index]);
        },
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        centerTitle: false,
        title: Text(
          "Specialist Categories",
          style: AppStyles.bodyLarge(context).copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildCategoryGrid(),
    );
  }
}



/*
import 'package:Webdoc/models/specialist_category_response.dart';
import 'package:Webdoc/screens/appointment_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class SpecialistCategoryScreen extends StatefulWidget {
  const SpecialistCategoryScreen({Key? key}) : super(key: key);

  @override
  _SpecialistCategoryScreenState createState() => _SpecialistCategoryScreenState();
}

class _SpecialistCategoryScreenState extends State<SpecialistCategoryScreen> {
  final ApiService apiService = ApiService();
  List<SpecialistCategory> _categories = [];
  bool _isLoading = true; // Add a loading indicator

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    final categoriesResponse = await apiService.getSpecialistCategories(context);
    setState(() {
      _isLoading = false; // Stop loading when done
    });
    if (categoriesResponse != null && categoriesResponse.isNotEmpty) {
      setState(() {
        _categories = categoriesResponse.first.payLoad ?? [];
      });
    } else {
      // Handle error case - maybe show an error message
      print("Failed to load categories");
    }
  }

  Widget _buildCategoryCard(SpecialistCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentScreen(specialityId: category.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            category.imageLink != null
                ? Image.network(
              category.imageLink!,
             // "https://portal.webdoc.com.pk/icons/Cadiologist.png",
              width: 30,  // Icon size
              height: 30,  // Icon size
              fit: BoxFit.contain,  // Fit within circle
              color: AppColors.primaryColor,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error_outline, color: Colors.red, size: 30);
              },
            )
                : Icon(Icons.image_not_supported, color: AppColors.primaryColor, size: 30),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Text(
                category.description ?? "N/A",
                style: AppStyles.bodySmall.copyWith(color: AppColors.primaryColor),
                textAlign: TextAlign.center,
                maxLines: 2,  // Limit to two lines
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:AppColors.backgroundColor ,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        centerTitle: false,
        title: Text(
          "Specialist Categories",
          style: AppStyles.bodyLarge.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,  // Number of items per row
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,  // Adjust as needed to refine appearance
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(_categories[index]);
          },
        ),
      ),
    );
  }
}*/
