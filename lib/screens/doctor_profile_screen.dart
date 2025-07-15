

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/doctor.dart';
import '../models/user_check_response.dart'; // Import UserCheckResponse
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';
import '../screens/package_screen.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import '../utils/permission_util.dart';
import '../utils/shared_preferences.dart';
import '../widgets/suggested_doctor_list_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfileScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with WidgetsBindingObserver {
  String _doctorStatus = 'offline';
  String _callType = '';
  bool _isLoadingSuggestedDoctors = false;
  bool _isPackageActivated = false;
  bool _isExpanded = false;
  final int _maxLines = 3;
  final Map<String, String> _doctorStatuses = {};
  StreamSubscription? _doctorListStatusSubscription;
  StreamSubscription? _doctorStatusSubscription;

  // API Service
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _listenForStatusUpdatesForSuggestedDoctors();
    _setupFirebaseListener();

    // Initial check for dialogs.  Important after returning from AudioCallScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowDialogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_checkAndShowDialogs(); // Move dialog logic here - NO LONGER NEEDED
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkAndShowDialogs(); // Re-check when app comes back to foreground
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _doctorListStatusSubscription?.cancel();
    _doctorStatusSubscription?.cancel();
    super.dispose();
  }

  void checkAndShowDialogs() {
    // Immediately check and show dialogs.  No need for WidgetsBinding.instance.addPostFrameCallback

    if (Global.feedbackDialog) {
      _showFeedbackDialog();
      Global.feedbackDialog = false; // Reset flag immediately after showing.
    }

    if (Global.call_missed) {
      _showCallMissedDialog();
      Global.call_missed = false; // Reset flag immediately after showing.
    }
  }

  void _setupFirebaseListener() {
    final emailKey = widget.doctor.emailDoctor?.replaceAll('.', '');

    if (emailKey != null) {
      _doctorStatusSubscription = Global.databaseReference
          .child(emailKey)
          .child('status')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _doctorStatus = event.snapshot.value.toString();
          });
        }
      });
    }
  }

  Future<void> _startCall(String callType) async {
    bool hasPermissions = true; // Initialize to true;

    // Only check permissions on Android
    if (Platform.isAndroid) {
      hasPermissions = await PermissionUtil.requestPermissions(context);
    }

    if (hasPermissions) {
      setState(() {
        _callType = callType;
      });
      if (_isPackageActivated) {
        if (_doctorStatus == 'online') {
          if (callType == 'audio') {
            _navigateToAudioCall();
          } else {
            _navigateToVideoCall();
          }
        } else {
          _showStatusDialog(context,
              _doctorStatus == 'offline'
                  ? 'Offline!'
                  : 'Busy!');
        }
      } else {
        _navigateToPackageScreen();
        Global.fromProfile = "profile";
      }
    }
  }

  void _navigateToAudioCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AudioCallScreen(
              channelName: widget.doctor.emailDoctor!,
              // pass email to agorachannel
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!,
              //pas doctorname to top of audio
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from AudioCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoCallScreen(
              channelName: widget.doctor.emailDoctor!,
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!, // pass doctor name too
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from VideoCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToPackageScreen() {
    Global.fromProfile = 'profile';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PackageScreen(),
      ),
    );
  }



  void _showStatusDialog(BuildContext context, String message) {
    IconData icon;
    Color iconColor;

    if (message.toLowerCase().contains("offline")) {
      icon = Icons.offline_bolt; // Use offline icon
      iconColor = Colors.red; // Set color to red
    } else if (message.toLowerCase().contains("busy")) {
      icon = Icons.access_time; // Use busy icon (or another time-related icon)
      iconColor = Colors.orange; // Set color to orange
    } else {
      icon = Icons.check_circle; // Default to check circle
      iconColor = AppColors.primaryColor; // Use default color
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog( // Use Dialog instead of AlertDialog for more customization
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0, // Remove shadow for a flatter design
          backgroundColor: Colors.transparent, // Transparent background
          child: Container(
            padding: EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.primaryColorLight,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(  // Visual Cue Container
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),  // Semi-transparent background
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 40,
                      color: iconColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: AppStyles.titleMedium(context).copyWith(color: AppColors.primaryColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton( // Use ElevatedButton for a more prominent button
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Got it'), // Positive affirmation text
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _listenForStatusUpdatesForSuggestedDoctors() {
    _doctorListStatusSubscription =
        Global.databaseReference.onValue.listen((event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            Map<String, String> newStatuses = {};
            for (var doctor in Global.allDoctorsList) {
              final emailKey = doctor.emailDoctor?.replaceAll('.', '');
              if (emailKey != null && data.containsKey(emailKey)) {
                newStatuses[doctor.emailDoctor!] =
                    data[emailKey]['status'].toString();
              } else {
                newStatuses[doctor.emailDoctor!] =
                'offline'; // Default status if not found
              }
            }
            setState(() {
              _doctorStatuses.clear();
              _doctorStatuses.addAll(newStatuses);
            });
          }
        });
  }

  String _getDoctorStatus(Doctor doctor) {
    return _doctorStatuses[doctor.emailDoctor!] ?? 'offline';
  }

  void _showCallMissedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Missed'),
          content: Text(
              '${widget.doctor.firstName} ${widget.doctor
                  .lastName} couldn\'t receive call at the moment.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog() {
    double rating = 5.0; // Initial rating
    String feedbackText = '';
    String ratingText = "I had an excellent experience!"; // Default rating text

    // Function to determine the rating text based on the selected rating
    String getRatingText(double rating) {
      switch (rating.toInt()) {
        case 1:
          return "I was extremely dissatisfied.";
        case 2:
          return "I was dissatisfied with the doctor's service.";
        case 3:
          return "The doctor's service was adequate.";
        case 4:
          return "I was pleased with the doctor's service.";
        case 5:
          return "I had an excellent experience!";
        default:
          return "I had an excellent experience!"; // Default in case of unexpected value
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          content: StatefulBuilder( // Use StatefulBuilder
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView( // Make it scrollable
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your Prescription will be available in\n'Prescription' tab in 5 to 10 minutes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Rate the Doctor",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "How would you rate your experience with the doctor?",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 30.0,
                        // Reduced the star size
                        unratedColor: Colors.grey[300],
                        itemPadding: const EdgeInsets.symmetric(
                            horizontal: 4.0),
                        itemBuilder: (context, _) =>
                        const Icon(
                          Icons.star,
                          color: Colors.orangeAccent,
                        ),
                        onRatingUpdate: (newRating) {
                          setState(() {
                            rating = newRating;
                            ratingText =
                                getRatingText(newRating); // Update rating text
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ratingText, // Display rating text
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: "Please write your feedback here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (text) {
                          feedbackText = text;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              foregroundColor: Colors.black,
                              // changed text color
                              shape: RoundedRectangleBorder( // changed shape
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Later"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Disable the button immediately after pressing
                              // Show loading indicator (optional)
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return  Center(
                                    child:  CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor),
                                    ),
                                  );
                                },
                              );

                              try {
                                // Call the SaveFeedback API
                                final String? patientId =
                                SharedPreferencesManager.getString('id');
                                final String doctorId = widget.doctor
                                    .doctorId ?? '0';

                                final UserCheckResponse? response =
                                await _apiService.saveFeedback(context: context,
                                  feedBackText: feedbackText,
                                  feedBackRating: rating.toInt(),
                                  doctorId: doctorId,
                                  patientId: patientId!,
                                );

                                if (response != null &&
                                    response.responseCode == '0000') {
                                  // Success
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text(
                                            'Feedback submitted successfully!')),
                                  );
                                } else {
                                  // Failure
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to submit feedback: ${response
                                                ?.message ??
                                                'Unknown error'}')),
                                  );
                                }
                              } catch (e) {
                                // Error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occurred: $e')),
                                );
                              } finally {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(); // Close dialog
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Set background color to white
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: screenHeight * 0.45, // Cover 45% of the screen
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35, // Start the card from the 35% of the screen
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor, // Background is primary color light
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(60)), // Rounded corners at the top
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight, // Ensure Column takes available height
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            10, 20, 10, 100), // 100 is added here for the additional padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Doctor's Name
                            Text(
                              '${widget.doctor.firstName} ${widget.doctor.lastName}',
                              style: AppStyles.titleLarge(context).copyWith(fontWeight: FontWeight.bold,color: AppColors.primaryTextColor),
                              textAlign: TextAlign.center, // Set color to primary color
                            ),
                            const SizedBox(height: 5),
                            // Doctor's Specialty
                            Text(
                              '${widget.doctor.doctorSpecialty ?? 'Medical Officer'}',
                              style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            // Online Status Badge
                            DoctorStatusBadge(doctorStatus: _doctorStatus),

                            // Doctor Summary
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0), // Add space above DoctorSummary
                              child: DoctorSummaryCard(
                                  doctor: widget.doctor,
                                  doctorStatus: _doctorStatus),
                            ),

                            // About Doctor Section
                            AboutDoctorSection(
                              doctor: widget.doctor,
                              isExpanded: _isExpanded,
                              onToggle: () {
                                setState(() => _isExpanded = !_isExpanded);
                              },
                              maxLines: _maxLines,
                            ),

                            // Suggested Doctors Section
                            /*   SuggestedDoctorsSection(
                              suggestedDoctors: Global.allDoctorsList,
                              isLoadingSuggestedDoctors: _isLoadingSuggestedDoctors,
                              getDoctorStatus: _getDoctorStatus,
                            ),*/

                            //SizedBox(height: screenHeight * 0.10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20, //Keep top padding at 20
                bottom: 2 + MediaQuery.of(context).padding.bottom, //Add bottom padding and safe area padding.
              ),
              child: CallButtonsSection(startCall: _startCall),
            ),
          ),
          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorStatusDelegate extends SliverPersistentHeaderDelegate {
  final String doctorStatus;
  final double height;

  _DoctorStatusDelegate({required this.doctorStatus, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      //color: Global.getColorFromHex(Global.THEME_COLOR_WHITE), // Set background color
      color: Colors.transparent, // Set background color
      child: Center(
        child: DoctorStatusBadge(doctorStatus: doctorStatus),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({Key? key, required this.doctorStatus})
      : super(key: key);

  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (doctorStatus) {
      case 'online':
        statusColor = Colors.green;
        statusText = 'Online';
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusText = 'Busy';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: AppStyles.bodyMedium(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard(
      {Key? key, required this.doctor, required this.doctorStatus})
      : super(key: key);

  final Doctor doctor;
  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 2.0, // Add elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight, // Background is primary color light
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2), // Stroke color, adjust opacity as needed
            width: 1, // Stroke width
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.01, vertical: screenHeight * 0.02),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem('Rating', doctor.rate ?? 'N/A', context),
            _buildInfoItem('Exp. years', doctor.experience ?? 'N/A', context),
            _buildInfoItem('Country', 'Pakistan', context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Container(
          width: screenWidth * 0.23, // Set a fixed width to boxes equal size
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Adjust padding to give space around both values and labels
          decoration: BoxDecoration(
            color: Colors.white, // Make the container white
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
              SizedBox(height: 4),
              Text(
                label, // label used to display inside the box at the bottom
                style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class AboutDoctorSection extends StatelessWidget {
  const AboutDoctorSection({
    Key? key,
    required this.doctor,
    required this.isExpanded,
    required this.onToggle,
    required this.maxLines,
  }) : super(key: key);

  final Doctor doctor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor, // Set background to lightPrimaryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Doctor',
            style: AppStyles.titleSmall(context).copyWith(fontWeight: FontWeight.w700,color:AppColors.primaryTextColor),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 75.0),
              child: Text(
                doctor.profileMessage ?? 'No profile message available.',
                style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: isExpanded ? null : maxLines,
              ),
            ),
          ),
          if ((doctor.profileMessage?.length ?? 0) > 70)
            InkWell(
              onTap: onToggle,
              child: Text(
                isExpanded ? 'Read Less' : 'Read More',
                style: AppStyles.bodyMedium(context).copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class CallButtonsSection extends StatelessWidget {
  const CallButtonsSection({
    Key? key,
    required this.startCall,
  }) : super(key: key);

  final Function(String) startCall;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => startCall('audio'),
          icon: const Icon(Icons.phone, color: Colors.white),
          label:
          const Text('Audio', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => startCall('video'),
          icon: const Icon(Icons.videocam, color: Colors.white),
          label:
          const Text('Video', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class SuggestedDoctorsSection extends StatelessWidget {
  const SuggestedDoctorsSection({
    Key? key,
    required this.suggestedDoctors,
    required this.isLoadingSuggestedDoctors,
    required this.getDoctorStatus, // Add this line
  }) : super(key: key);

  final List<Doctor> suggestedDoctors;
  final bool isLoadingSuggestedDoctors;
  final String Function(Doctor) getDoctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight, // Set background to lightPrimaryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Doctors',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: screenHeight * 0.18,
            child: isLoadingSuggestedDoctors
                ? Center(
              child:  CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedDoctors.length,
              itemBuilder: (context, index) {
                final doctor = suggestedDoctors[index];
                return Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.03),
                  child: SuggestedDoctorListItem(
                    doctor: doctor,
                    doctorStatus: getDoctorStatus(doctor),
                    onTap: () {
                      Global.docPosition = index;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: doctor,
                        )
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/doctor.dart';
import '../models/user_check_response.dart'; // Import UserCheckResponse
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';
import '../screens/package_screen.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import '../utils/permission_util.dart';
import '../utils/shared_preferences.dart';
import '../widgets/suggested_doctor_list_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfileScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with WidgetsBindingObserver {
  String _doctorStatus = 'offline';
  String _callType = '';
  bool _isLoadingSuggestedDoctors = false;
  bool _isPackageActivated = false;
  bool _isExpanded = false;
  final int _maxLines = 3;
  final Map<String, String> _doctorStatuses = {};
  StreamSubscription? _doctorListStatusSubscription;
  StreamSubscription? _doctorStatusSubscription;

  // API Service
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _listenForStatusUpdatesForSuggestedDoctors();
    _setupFirebaseListener();

    // Initial check for dialogs.  Important after returning from AudioCallScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowDialogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_checkAndShowDialogs(); // Move dialog logic here - NO LONGER NEEDED
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkAndShowDialogs(); // Re-check when app comes back to foreground
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _doctorListStatusSubscription?.cancel();
    _doctorStatusSubscription?.cancel();
    super.dispose();
  }

  void checkAndShowDialogs() {
    // Immediately check and show dialogs.  No need for WidgetsBinding.instance.addPostFrameCallback

    if (Global.feedbackDialog) {
      _showFeedbackDialog();
      Global.feedbackDialog = false; // Reset flag immediately after showing.
    }

    if (Global.call_missed) {
      _showCallMissedDialog();
      Global.call_missed = false; // Reset flag immediately after showing.
    }
  }

  void _setupFirebaseListener() {
    final emailKey = widget.doctor.emailDoctor?.replaceAll('.', '');

    if (emailKey != null) {
      _doctorStatusSubscription = Global.databaseReference
          .child(emailKey)
          .child('status')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _doctorStatus = event.snapshot.value.toString();
          });
        }
      });
    }
  }

  Future<void> _startCall(String callType) async {
    bool hasPermissions = true; // Initialize to true;

    // Only check permissions on Android
    if (Platform.isAndroid) {
      hasPermissions = await PermissionUtil.requestPermissions(context);
    }

    if (hasPermissions) {
      setState(() {
        _callType = callType;
      });
      if (_isPackageActivated) {
        if (_doctorStatus == 'online') {
          if (callType == 'audio') {
            _navigateToAudioCall();
          } else {
            _navigateToVideoCall();
          }
        } else {
          _showStatusDialog(context,
              _doctorStatus == 'offline'
                  ? 'Offline!'
                  : 'Busy!');
        }
      } else {
        _navigateToPackageScreen();
        Global.fromProfile = "profile";
      }
    }
  }

  void _navigateToAudioCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AudioCallScreen(
              channelName: widget.doctor.emailDoctor!,
              // pass email to agorachannel
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!,
              //pas doctorname to top of audio
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from AudioCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoCallScreen(
              channelName: widget.doctor.emailDoctor!,
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!, // pass doctor name too
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from VideoCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToPackageScreen() {
    Global.fromProfile = 'profile';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PackageScreen(),
      ),
    );
  }



  void _showStatusDialog(BuildContext context, String message) {
    IconData icon;
    Color iconColor;

    if (message.toLowerCase().contains("offline")) {
      icon = Icons.offline_bolt; // Use offline icon
      iconColor = Colors.red; // Set color to red
    } else if (message.toLowerCase().contains("busy")) {
      icon = Icons.access_time; // Use busy icon (or another time-related icon)
      iconColor = Colors.orange; // Set color to orange
    } else {
      icon = Icons.check_circle; // Default to check circle
      iconColor = AppColors.primaryColor; // Use default color
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog( // Use Dialog instead of AlertDialog for more customization
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0, // Remove shadow for a flatter design
          backgroundColor: Colors.transparent, // Transparent background
          child: Container(
            padding: EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.primaryColorLight,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(  // Visual Cue Container
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),  // Semi-transparent background
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 40,
                      color: iconColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: AppStyles.titleMedium.copyWith(color: AppColors.primaryColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton( // Use ElevatedButton for a more prominent button
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Got it'), // Positive affirmation text
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _listenForStatusUpdatesForSuggestedDoctors() {
    _doctorListStatusSubscription =
        Global.databaseReference.onValue.listen((event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            Map<String, String> newStatuses = {};
            for (var doctor in Global.allDoctorsList) {
              final emailKey = doctor.emailDoctor?.replaceAll('.', '');
              if (emailKey != null && data.containsKey(emailKey)) {
                newStatuses[doctor.emailDoctor!] =
                    data[emailKey]['status'].toString();
              } else {
                newStatuses[doctor.emailDoctor!] =
                'offline'; // Default status if not found
              }
            }
            setState(() {
              _doctorStatuses.clear();
              _doctorStatuses.addAll(newStatuses);
            });
          }
        });
  }

  String _getDoctorStatus(Doctor doctor) {
    return _doctorStatuses[doctor.emailDoctor!] ?? 'offline';
  }

  void _showCallMissedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Missed'),
          content: Text(
              '${widget.doctor.firstName} ${widget.doctor
                  .lastName} couldn\'t receive call at the moment.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog() {
    double rating = 5.0; // Initial rating
    String feedbackText = '';
    String ratingText = "I had an excellent experience!"; // Default rating text

    // Function to determine the rating text based on the selected rating
    String getRatingText(double rating) {
      switch (rating.toInt()) {
        case 1:
          return "I was extremely dissatisfied.";
        case 2:
          return "I was dissatisfied with the doctor's service.";
        case 3:
          return "The doctor's service was adequate.";
        case 4:
          return "I was pleased with the doctor's service.";
        case 5:
          return "I had an excellent experience!";
        default:
          return "I had an excellent experience!"; // Default in case of unexpected value
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          content: StatefulBuilder( // Use StatefulBuilder
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView( // Make it scrollable
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your Prescription will be available in\n'Prescription' tab in 5 to 10 minutes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Rate the Doctor",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "How would you rate your experience with the doctor?",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 30.0,
                        // Reduced the star size
                        unratedColor: Colors.grey[300],
                        itemPadding: const EdgeInsets.symmetric(
                            horizontal: 4.0),
                        itemBuilder: (context, _) =>
                        const Icon(
                          Icons.star,
                          color: Colors.orangeAccent,
                        ),
                        onRatingUpdate: (newRating) {
                          setState(() {
                            rating = newRating;
                            ratingText =
                                getRatingText(newRating); // Update rating text
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ratingText, // Display rating text
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: "Please write your feedback here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (text) {
                          feedbackText = text;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              foregroundColor: Colors.black,
                              // changed text color
                              shape: RoundedRectangleBorder( // changed shape
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Later"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Disable the button immediately after pressing
                              // Show loading indicator (optional)
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return  Center(
                                    child:  CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor),
                                    ),
                                  );
                                },
                              );

                              try {
                                // Call the SaveFeedback API
                                final String? patientId =
                                SharedPreferencesManager.getString('id');
                                final String doctorId = widget.doctor
                                    .doctorId ?? '0';

                                final UserCheckResponse? response =
                                await _apiService.saveFeedback(context: context,
                                  feedBackText: feedbackText,
                                  feedBackRating: rating.toInt(),
                                  doctorId: doctorId,
                                  patientId: patientId!,
                                );

                                if (response != null &&
                                    response.responseCode == '0000') {
                                  // Success
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text(
                                            'Feedback submitted successfully!')),
                                  );
                                } else {
                                  // Failure
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to submit feedback: ${response
                                                ?.message ??
                                                'Unknown error'}')),
                                  );
                                }
                              } catch (e) {
                                // Error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occurred: $e')),
                                );
                              } finally {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(); // Close dialog
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Set background color to white
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: screenHeight * 0.45, // Cover 45% of the screen
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35, // Start the card from the 35% of the screen
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor, // Background is primary color light
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(60)), // Rounded corners at the top
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight, // Ensure Column takes available height
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            10, 20, 10, 100), // 100 is added here for the additional padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Doctor's Name
                            Text(
                              '${widget.doctor.firstName} ${widget.doctor.lastName}',
                              style: AppStyles.titleLarge.copyWith(fontWeight: FontWeight.bold,color: AppColors.primaryTextColor),
                              textAlign: TextAlign.center, // Set color to primary color
                            ),
                            const SizedBox(height: 5),
                            // Doctor's Specialty
                            Text(
                              '${widget.doctor.doctorSpecialty ?? 'Medical Officer'}',
                              style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            // Online Status Badge
                            DoctorStatusBadge(doctorStatus: _doctorStatus),

                            // Doctor Summary
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0), // Add space above DoctorSummary
                              child: DoctorSummaryCard(
                                  doctor: widget.doctor,
                                  doctorStatus: _doctorStatus),
                            ),

                            // About Doctor Section
                            AboutDoctorSection(
                              doctor: widget.doctor,
                              isExpanded: _isExpanded,
                              onToggle: () {
                                setState(() => _isExpanded = !_isExpanded);
                              },
                              maxLines: _maxLines,
                            ),

                            // Suggested Doctors Section
                         *//*   SuggestedDoctorsSection(
                              suggestedDoctors: Global.allDoctorsList,
                              isLoadingSuggestedDoctors: _isLoadingSuggestedDoctors,
                              getDoctorStatus: _getDoctorStatus,
                            ),*//*

                            //SizedBox(height: screenHeight * 0.10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
              child: CallButtonsSection(startCall: _startCall),
            ),
          ),
          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorStatusDelegate extends SliverPersistentHeaderDelegate {
  final String doctorStatus;
  final double height;

  _DoctorStatusDelegate({required this.doctorStatus, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      //color: Global.getColorFromHex(Global.THEME_COLOR_WHITE), // Set background color
      color: Colors.transparent, // Set background color
      child: Center(
        child: DoctorStatusBadge(doctorStatus: doctorStatus),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({Key? key, required this.doctorStatus})
      : super(key: key);

  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (doctorStatus) {
      case 'online':
        statusColor = Colors.green;
        statusText = 'Online';
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusText = 'Busy';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: AppStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard(
      {Key? key, required this.doctor, required this.doctorStatus})
      : super(key: key);

  final Doctor doctor;
  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 2.0, // Add elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight, // Background is primary color light
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2), // Stroke color, adjust opacity as needed
            width: 1, // Stroke width
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.01, vertical: screenHeight * 0.02),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem('Rating', doctor.rate ?? 'N/A', context),
            _buildInfoItem('Exp. years', doctor.experience ?? 'N/A', context),
            _buildInfoItem('Country', 'Pakistan', context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Container(
          width: screenWidth * 0.23, // Set a fixed width to boxes equal size
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Adjust padding to give space around both values and labels
          decoration: BoxDecoration(
            color: Colors.white, // Make the container white
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
              SizedBox(height: 4),
              Text(
                label, // label used to display inside the box at the bottom
                style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class AboutDoctorSection extends StatelessWidget {
  const AboutDoctorSection({
    Key? key,
    required this.doctor,
    required this.isExpanded,
    required this.onToggle,
    required this.maxLines,
  }) : super(key: key);

  final Doctor doctor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor, // Set background to lightPrimaryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Doctor',
            style: AppStyles.titleSmall.copyWith(fontWeight: FontWeight.w700,color:AppColors.primaryTextColor),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 75.0),
              child: Text(
                doctor.profileMessage ?? 'No profile message available.',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: isExpanded ? null : maxLines,
              ),
            ),
          ),
          if ((doctor.profileMessage?.length ?? 0) > 70)
            InkWell(
              child: Text(
                isExpanded ? 'Read Less' : 'Read More',
                style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ),
              onTap: onToggle,
            ),
        ],
      ),
    );
  }
}

class CallButtonsSection extends StatelessWidget {
  const CallButtonsSection({
    Key? key,
    required this.startCall,
  }) : super(key: key);

  final Function(String) startCall;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => startCall('audio'),
          icon: const Icon(Icons.phone, color: Colors.white),
          label:
          const Text('Audio', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => startCall('video'),
          icon: const Icon(Icons.videocam, color: Colors.white),
          label:
          const Text('Video', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class SuggestedDoctorsSection extends StatelessWidget {
  const SuggestedDoctorsSection({
    Key? key,
    required this.suggestedDoctors,
    required this.isLoadingSuggestedDoctors,
    required this.getDoctorStatus, // Add this line
  }) : super(key: key);

  final List<Doctor> suggestedDoctors;
  final bool isLoadingSuggestedDoctors;
  final String Function(Doctor) getDoctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight, // Set background to lightPrimaryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Doctors',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: screenHeight * 0.18,
            child: isLoadingSuggestedDoctors
                ? Center(
              child:  CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedDoctors.length,
              itemBuilder: (context, index) {
                final doctor = suggestedDoctors[index];
                return Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.03),
                  child: SuggestedDoctorListItem(
                    doctor: doctor,
                    doctorStatus: getDoctorStatus(doctor),
                    onTap: () {
                      Global.docPosition = index;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: doctor,
                        )
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}*/




/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/doctor.dart';
import '../models/user_check_response.dart'; // Import UserCheckResponse
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';
import '../screens/package_screen.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import '../utils/permission_util.dart';
import '../utils/shared_preferences.dart';
import '../widgets/suggested_doctor_list_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfileScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with WidgetsBindingObserver {
  String _doctorStatus = 'offline';
  String _callType = '';
  bool _isLoadingSuggestedDoctors = false;
  bool _isPackageActivated = false;
  bool _isExpanded = false;
  final int _maxLines = 3;
  final Map<String, String> _doctorStatuses = {};
  StreamSubscription? _doctorListStatusSubscription;
  StreamSubscription? _doctorStatusSubscription;

  // API Service
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _listenForStatusUpdatesForSuggestedDoctors();
    _setupFirebaseListener();

    // Initial check for dialogs.  Important after returning from AudioCallScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowDialogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_checkAndShowDialogs(); // Move dialog logic here - NO LONGER NEEDED
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkAndShowDialogs(); // Re-check when app comes back to foreground
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _doctorListStatusSubscription?.cancel();
    _doctorStatusSubscription?.cancel();
    super.dispose();
  }

  void checkAndShowDialogs() {
    // Immediately check and show dialogs.  No need for WidgetsBinding.instance.addPostFrameCallback

    if (Global.feedbackDialog) {
      _showFeedbackDialog();
      Global.feedbackDialog = false; // Reset flag immediately after showing.
    }

    if (Global.call_missed) {
      _showCallMissedDialog();
      Global.call_missed = false; // Reset flag immediately after showing.
    }
  }

  void _setupFirebaseListener() {
    final emailKey = widget.doctor.emailDoctor?.replaceAll('.', '');

    if (emailKey != null) {
      _doctorStatusSubscription = Global.databaseReference
          .child(emailKey)
          .child('status')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _doctorStatus = event.snapshot.value.toString();
          });
        }
      });
    }
  }

  Future<void> _startCall(String callType) async {
    bool hasPermissions = true; // Initialize to true;

    // Only check permissions on Android
    if (Platform.isAndroid) {
      hasPermissions = await PermissionUtil.requestPermissions(context);
    }

    if (hasPermissions) {
      setState(() {
        _callType = callType;
      });
      if (_isPackageActivated) {
        if (_doctorStatus == 'online') {
          if (callType == 'audio') {
            _navigateToAudioCall();
          } else {
            _navigateToVideoCall();
          }
        } else {
          _showStatusDialog(
              _doctorStatus == 'offline'
                  ? 'Doctor is offline!'
                  : 'Doctor is busy!');
        }
      } else {
        _navigateToPackageScreen();
        Global.fromProfile = "profile";
      }
    }
  }

  void _navigateToAudioCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AudioCallScreen(
              channelName: widget.doctor.emailDoctor!,
              // pass email to agorachannel
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!,
              //pas doctorname to top of audio
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from AudioCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoCallScreen(
              channelName: widget.doctor.emailDoctor!,
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!, // pass doctor name too
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from VideoCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToPackageScreen() {
    Global.fromProfile = 'profile';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PackageScreen(),
      ),
    );
  }

  void _showStatusDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Doctor Status'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _listenForStatusUpdatesForSuggestedDoctors() {
    _doctorListStatusSubscription =
        Global.databaseReference.onValue.listen((event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            Map<String, String> newStatuses = {};
            for (var doctor in Global.allDoctorsList) {
              final emailKey = doctor.emailDoctor?.replaceAll('.', '');
              if (emailKey != null && data.containsKey(emailKey)) {
                newStatuses[doctor.emailDoctor!] =
                    data[emailKey]['status'].toString();
              } else {
                newStatuses[doctor.emailDoctor!] =
                'offline'; // Default status if not found
              }
            }
            setState(() {
              _doctorStatuses.clear();
              _doctorStatuses.addAll(newStatuses);
            });
          }
        });
  }

  String _getDoctorStatus(Doctor doctor) {
    return _doctorStatuses[doctor.emailDoctor!] ?? 'offline';
  }

  void _showCallMissedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Missed'),
          content: Text(
              '${widget.doctor.firstName} ${widget.doctor
                  .lastName} couldn\'t receive call at the moment.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog() {
    double rating = 5.0; // Initial rating
    String feedbackText = '';
    String ratingText = "I had an excellent experience!"; // Default rating text

    // Function to determine the rating text based on the selected rating
    String getRatingText(double rating) {
      switch (rating.toInt()) {
        case 1:
          return "I was extremely dissatisfied.";
        case 2:
          return "I was dissatisfied with the doctor's service.";
        case 3:
          return "The doctor's service was adequate.";
        case 4:
          return "I was pleased with the doctor's service.";
        case 5:
          return "I had an excellent experience!";
        default:
          return "I had an excellent experience!"; // Default in case of unexpected value
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          content: StatefulBuilder( // Use StatefulBuilder
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView( // Make it scrollable
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your Prescription will be available in\n'Prescription' tab in 5 to 10 minutes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Rate the Doctor",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "How would you rate your experience with the doctor?",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 30.0,
                        // Reduced the star size
                        unratedColor: Colors.grey[300],
                        itemPadding: const EdgeInsets.symmetric(
                            horizontal: 4.0),
                        itemBuilder: (context, _) =>
                        const Icon(
                          Icons.star,
                          color: Colors.orangeAccent,
                        ),
                        onRatingUpdate: (newRating) {
                          setState(() {
                            rating = newRating;
                            ratingText =
                                getRatingText(newRating); // Update rating text
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ratingText, // Display rating text
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: "Please write your feedback here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (text) {
                          feedbackText = text;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              foregroundColor: Colors.black,
                              // changed text color
                              shape: RoundedRectangleBorder( // changed shape
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Later"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Disable the button immediately after pressing
                              // Show loading indicator (optional)
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return  Center(
                                    child: CircularProgressIndicator( // Added color here
                                      valueColor: AlwaysStoppedAnimation<Color>(Global.getColorFromHex(Global.THEME_COLOR_CODE)),
                                    ),
                                  );
                                },
                              );

                              try {
                                // Call the SaveFeedback API
                                final String? patientId =
                                SharedPreferencesManager.getString('id');
                                final String doctorId = widget.doctor
                                    .doctorId ?? '0';

                                final UserCheckResponse? response =
                                await _apiService.saveFeedback(context: context,
                                  feedBackText: feedbackText,
                                  feedBackRating: rating.toInt(),
                                  doctorId: doctorId,
                                  patientId: patientId!,
                                );

                                if (response != null &&
                                    response.responseCode == '0000') {
                                  // Success
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text(
                                            'Feedback submitted successfully!')),
                                  );
                                } else {
                                  // Failure
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to submit feedback: ${response
                                                ?.message ??
                                                'Unknown error'}')),
                                  );
                                }
                              } catch (e) {
                                // Error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occurred: $e')),
                                );
                              } finally {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(); // Close dialog
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Set background color to white
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: screenHeight * 0.45, // Cover 45% of the screen
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35, // Start the card from the 35% of the screen
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor, // Background is primary color light
                borderRadius: BorderRadius.vertical(top: Radius.circular(60)), // Rounded corners at the top
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 0), // Add padding to the card content
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Doctor's Name
                      Text(
                        '${widget.doctor.firstName} ${widget.doctor.lastName}',
                        style: AppStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                      // Doctor's Specialty
                      Text(
                        '${widget.doctor.doctorSpecialty ?? 'Medical Officer'}',
                        style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),

                      // Online Status Badge
                      DoctorStatusBadge(doctorStatus: _doctorStatus),

                      // Doctor Summary
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0), // Add space above DoctorSummary
                        child: DoctorSummaryCard(
                          doctor: widget.doctor,
                          doctorStatus: _doctorStatus,
                        ),
                      ),

                      // About Doctor Section
                      AboutDoctorSection(
                        doctor: widget.doctor,
                        isExpanded: _isExpanded,
                        onToggle: () {
                          setState(() => _isExpanded = !_isExpanded);
                        },
                        maxLines: _maxLines,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: CallButtonsSection(startCall: _startCall),
                      ),

                      // Suggested Doctors Section
                     *//* SuggestedDoctorsSection(
                        suggestedDoctors: Global.allDoctorsList,
                        isLoadingSuggestedDoctors: _isLoadingSuggestedDoctors,
                        getDoctorStatus: _getDoctorStatus,
                      ),

                      SizedBox(height: screenHeight * 0.02),*//*
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorStatusDelegate extends SliverPersistentHeaderDelegate {
  final String doctorStatus;
  final double height;

  _DoctorStatusDelegate({required this.doctorStatus, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      //color: Global.getColorFromHex(Global.THEME_COLOR_WHITE), // Set background color
      color: Colors.transparent, // Set background color
      child: Center(
        child: DoctorStatusBadge(doctorStatus: doctorStatus),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({Key? key, required this.doctorStatus})
      : super(key: key);

  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (doctorStatus) {
      case 'online':
        statusColor = Colors.green;
        statusText = 'Online';
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusText = 'Busy';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: AppStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard(
      {Key? key, required this.doctor, required this.doctorStatus})
      : super(key: key);

  final Doctor doctor;
  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 2.0, // Add elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight, // Background is primary color light
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2), // Stroke color, adjust opacity as needed
            width: 1, // Stroke width
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.01, vertical: screenHeight * 0.02),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem('Rating', doctor.rate ?? 'N/A', context),
            _buildInfoItem('Exp. years', doctor.experience ?? 'N/A', context),
            _buildInfoItem('Country', 'Pakistan', context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Container(
          width: screenWidth * 0.23, // Set a fixed width to boxes equal size
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Adjust padding to give space around both values and labels
          decoration: BoxDecoration(
            color: Colors.white, // Make the container white
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
              SizedBox(height: 4),
              Text(
                label, // label used to display inside the box at the bottom
                style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
*//*class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard(
      {Key? key, required this.doctor, required this.doctorStatus})
      : super(key: key);

  final Doctor doctor;
  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight, // Background is primary color light
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem( 'Rating', doctor.rate ?? 'N/A'),
          _buildInfoItem( 'Exp. years', doctor.experience ?? 'N/A'),
          _buildInfoItem( 'Country', 'Pakistan'),
        ],
      ),
    );
  }

  Widget _buildInfoItem( String label, String value) {
    return Column(
      children: [
        Text(value,
            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600,color: Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryTextColor)),
       // Icon(icon, color: AppColors.primaryColor, size: 28),
      ],
    );
  }
}*//*

class AboutDoctorSection extends StatelessWidget {
  const AboutDoctorSection({
    Key? key,
    required this.doctor,
    required this.isExpanded,
    required this.onToggle,
    required this.maxLines,
  }) : super(key: key);

  final Doctor doctor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor, // Set background to lightPrimaryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Doctor',
            style: AppStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 75.0),
              child: Text(
                doctor.profileMessage ?? 'No profile message available.',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: isExpanded ? null : maxLines,
              ),
            ),
          ),
          if ((doctor.profileMessage?.length ?? 0) > 70)
            InkWell(
              child: Text(
                isExpanded ? 'Read Less' : 'Read More',
                style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ),
              onTap: onToggle,
            ),
        ],
      ),
    );
  }
}

class CallButtonsSection extends StatelessWidget {
  const CallButtonsSection({
    Key? key,
    required this.startCall,
  }) : super(key: key);

  final Function(String) startCall;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => startCall('audio'),
          icon: const Icon(Icons.phone, color: Colors.white),
          label:
          const Text('Audio', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => startCall('video'),
          icon: const Icon(Icons.videocam, color: Colors.white),
          label:
          const Text('Video', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class SuggestedDoctorsSection extends StatelessWidget {
  const SuggestedDoctorsSection({
    Key? key,
    required this.suggestedDoctors,
    required this.isLoadingSuggestedDoctors,
    required this.getDoctorStatus, // Add this line
  }) : super(key: key);

  final List<Doctor> suggestedDoctors;
  final bool isLoadingSuggestedDoctors;
  final String Function(Doctor) getDoctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight, // Set background to lightPrimaryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Doctors',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: screenHeight * 0.18,
            child: isLoadingSuggestedDoctors
                ? Center(
              child: CircularProgressIndicator( // Added color here
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedDoctors.length,
              itemBuilder: (context, index) {
                final doctor = suggestedDoctors[index];
                return Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.03),
                  child: SuggestedDoctorListItem(
                    doctor: doctor,
                    doctorStatus: getDoctorStatus(doctor),
                    onTap: () {
                      Global.docPosition = index;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: doctor,
                        )
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}*/









/*import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Import SystemChrome
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/doctor.dart';
import '../models/user_check_response.dart'; // Import UserCheckResponse
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';
import '../screens/package_screen.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import '../utils/permission_util.dart';
import '../utils/shared_preferences.dart';
import '../widgets/suggested_doctor_list_item.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfileScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with WidgetsBindingObserver {
  String _doctorStatus = 'offline';
  String _callType = '';
  bool _isLoadingSuggestedDoctors = false;
  bool _isPackageActivated = false;
  bool _isExpanded = false;
  final int _maxLines = 3;
  // double _scrollOffset = 0.0; // No longer needed
  // Timer? _scrollTimer; // No longer needed
  final Map<String, String> _doctorStatuses = {};
  StreamSubscription? _doctorListStatusSubscription;
  StreamSubscription? _doctorStatusSubscription;

  // API Service
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _isPackageActivated =
        SharedPreferencesManager.getBool('isPackageActivated') ?? false;
    _listenForStatusUpdatesForSuggestedDoctors();
    _setupFirebaseListener();

    // Initial check for dialogs.  Important after returning from AudioCallScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowDialogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_checkAndShowDialogs(); // Move dialog logic here - NO LONGER NEEDED
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkAndShowDialogs(); // Re-check when app comes back to foreground
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    // _scrollTimer?.cancel();  // No longer needed
    _doctorListStatusSubscription?.cancel();
    _doctorStatusSubscription?.cancel();
    super.dispose();
  }

  void checkAndShowDialogs() {
    // Immediately check and show dialogs.  No need for WidgetsBinding.instance.addPostFrameCallback

    if (Global.feedbackDialog) {
      _showFeedbackDialog();
      Global.feedbackDialog = false; // Reset flag immediately after showing.
    }

    if (Global.call_missed) {
      _showCallMissedDialog();
      Global.call_missed = false; // Reset flag immediately after showing.
    }
  }

  void _setupFirebaseListener() {
    final emailKey = widget.doctor.emailDoctor?.replaceAll('.', '');

    if (emailKey != null) {
      _doctorStatusSubscription = Global.databaseReference
          .child(emailKey)
          .child('status')
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          setState(() {
            _doctorStatus = event.snapshot.value.toString();
          });
        }
      });
    }
  }
  Future<void> _startCall(String callType) async {
    bool hasPermissions = true; // Initialize to true;

    // Only check permissions on Android
    if (Platform.isAndroid) {
      hasPermissions = await PermissionUtil.requestPermissions(context);
    }

    if (hasPermissions) {
      setState(() {
        _callType = callType;
      });
      if (_isPackageActivated) {
        if (_doctorStatus == 'online') {
          if (callType == 'audio') {
            _navigateToAudioCall();
          } else {
            _navigateToVideoCall();
          }
        }
        else {
          _showStatusDialog(
              _doctorStatus == 'offline'
                  ? 'Doctor is offline!'
                  : 'Doctor is busy!');
        }
      } else {
        _navigateToPackageScreen();
        Global.fromProfile = "profile";
      }
    }
  }


  void _navigateToAudioCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AudioCallScreen(
              channelName: widget.doctor.emailDoctor!,
              // pass email to agorachannel
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!,
              //pas doctorname to top of audio
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from AudioCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoCallScreen(
              channelName: widget.doctor.emailDoctor!,
              doctorName: widget.doctor.firstName! +
                  " " +
                  widget.doctor.lastName!, // pass doctor name too
              doctorImageUrl: widget.doctor.imgLink!, //set dynamic image here
            ),
      ),
    ).then((_) {
      // After returning from VideoCallScreen, immediately check for dialogs
      checkAndShowDialogs();
    });
  }

  void _navigateToPackageScreen() {
    Global.fromProfile = 'profile';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PackageScreen(),
      ),
    );
  }

  void _showStatusDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Doctor Status'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _listenForStatusUpdatesForSuggestedDoctors() {
    _doctorListStatusSubscription =
        Global.databaseReference.onValue.listen((event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            Map<String, String> newStatuses = {};
            for (var doctor in Global.allDoctorsList) {
              final emailKey = doctor.emailDoctor?.replaceAll('.', '');
              if (emailKey != null && data.containsKey(emailKey)) {
                newStatuses[doctor.emailDoctor!] =
                    data[emailKey]['status'].toString();
              } else {
                newStatuses[doctor.emailDoctor!] =
                'offline'; // Default status if not found
              }
            }
            setState(() {
              _doctorStatuses.clear();
              _doctorStatuses.addAll(newStatuses);
            });
          }
        });
  }

  String _getDoctorStatus(Doctor doctor) {
    return _doctorStatuses[doctor.emailDoctor!] ?? 'offline';
  }

  void _showCallMissedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Missed'),
          content: Text(
              '${widget.doctor.firstName} ${widget.doctor
                  .lastName} couldn\'t receive call at the moment.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog() {
    double rating = 5.0; // Initial rating
    String feedbackText = '';
    String ratingText = "I had an excellent experience!"; // Default rating text

    // Function to determine the rating text based on the selected rating
    String getRatingText(double rating) {
      switch (rating.toInt()) {
        case 1:
          return "I was extremely dissatisfied.";
        case 2:
          return "I was dissatisfied with the doctor's service.";
        case 3:
          return "The doctor's service was adequate.";
        case 4:
          return "I was pleased with the doctor's service.";
        case 5:
          return "I had an excellent experience!";
        default:
          return "I had an excellent experience!"; // Default in case of unexpected value
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          content: StatefulBuilder( // Use StatefulBuilder
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView( // Make it scrollable
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your Prescription will be available in\n'Prescription' tab in 5 to 10 minutes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Rate the Doctor",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "How would you rate your experience with the doctor?",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 30.0,
                        // Reduced the star size
                        unratedColor: Colors.grey[300],
                        itemPadding: const EdgeInsets.symmetric(
                            horizontal: 4.0),
                        itemBuilder: (context, _) =>
                        const Icon(
                          Icons.star,
                          color: Colors.orangeAccent,
                        ),
                        onRatingUpdate: (newRating) {
                          setState(() {
                            rating = newRating;
                            ratingText =
                                getRatingText(newRating); // Update rating text
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ratingText, // Display rating text
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: "Please write your feedback here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (text) {
                          feedbackText = text;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              foregroundColor: Colors.black,
                              // changed text color
                              shape: RoundedRectangleBorder( // changed shape
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Later"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Disable the button immediately after pressing
                              // Show loading indicator (optional)
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return  Center(
                                    child: CircularProgressIndicator( // Added color here
                                      valueColor: AlwaysStoppedAnimation<Color>(Global.getColorFromHex(Global.THEME_COLOR_CODE)),
                                    ),
                                  );
                                },
                              );

                              try {
                                // Call the SaveFeedback API
                                final String? patientId =
                                SharedPreferencesManager.getString('id');
                                final String doctorId = widget.doctor
                                    .doctorId ?? '0';

                                final UserCheckResponse? response =
                                await _apiService.saveFeedback(context: context,
                                  feedBackText: feedbackText,
                                  feedBackRating: rating.toInt(),
                                  doctorId: doctorId,
                                  patientId: patientId!,
                                );

                                if (response != null &&
                                    response.responseCode == '0000') {
                                  // Success
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text(
                                            'Feedback submitted successfully!')),
                                  );
                                } else {
                                  // Failure
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to submit feedback: ${response
                                                ?.message ??
                                                'Unknown error'}')),
                                  );
                                }
                              } catch (e) {
                                // Error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occurred: $e')),
                                );
                              } finally {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(); // Close dialog
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: screenHeight * 0.35,
              pinned: true,
              backgroundColor:
              Global.getColorFromHex(Global.THEME_COLOR_CODE),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white), // Always white
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '${widget.doctor.firstName} ${widget.doctor.lastName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
                      builder: (BuildContext context,
                          BoxConstraints constraints) {
                        return CachedNetworkImage(
                          imageUrl: widget.doctor.imgLink!,
                          fit: BoxFit.cover,
                          // Changed to BoxFit.cover
                          alignment: Alignment.topCenter,
                          // Added Alignment.topCenter
                          width: constraints.maxWidth,
                          placeholder: (context, url) =>
                              Center(
                                child: CircularProgressIndicator( // Added color here
                                  valueColor: AlwaysStoppedAnimation<Color>(Global.getColorFromHex(Global.THEME_COLOR_CODE)),
                                ),
                              ),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _DoctorStatusDelegate(
                doctorStatus: _doctorStatus,
                height: screenHeight * 0.05,  // Adjust the height as needed.
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DoctorSummaryCard(
                      doctor: widget.doctor, doctorStatus: _doctorStatus),
                  SizedBox(height: screenHeight * 0.02),
                  AboutDoctorSection(
                    doctor: widget.doctor,
                    isExpanded: _isExpanded,
                    onToggle: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    maxLines: _maxLines,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  CallButtonsSection(startCall: _startCall),
                  SizedBox(height: screenHeight * 0.04),
                  SuggestedDoctorsSection(
                    suggestedDoctors: Global.allDoctorsList,
                    isLoadingSuggestedDoctors: _isLoadingSuggestedDoctors,
                    getDoctorStatus: _getDoctorStatus,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorStatusDelegate extends SliverPersistentHeaderDelegate {
  final String doctorStatus;
  final double height;

  _DoctorStatusDelegate({required this.doctorStatus, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      //color: Global.getColorFromHex(Global.THEME_COLOR_WHITE), // Set background color
      color: Colors.transparent, // Set background color
      child: Center(
        child: DoctorStatusBadge(doctorStatus: doctorStatus),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({super.key, required this.doctorStatus});

  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (doctorStatus) {
      case 'online':
        statusColor = Colors.green;
        statusText = 'Available';
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusText = 'Busy';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard(
      {Key? key, required this.doctor, required this.doctorStatus})
      : super(key: key);

  final Doctor doctor;
  final String doctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${doctor.firstName} ${doctor.lastName}',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800]),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            doctor.doctorSpecialty ?? 'Specialty not available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                  Icons.work, 'Experience', doctor.experience ?? 'N/A'),
              _buildInfoItem(Icons.star, 'Rating', doctor.rate ?? 'N/A'),
              _buildInfoItem(Icons.location_on, 'Country', 'Pakistan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Global.getColorFromHex(Global.THEME_COLOR_CODE),
            size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AboutDoctorSection extends StatelessWidget {
  const AboutDoctorSection({
    Key? key,
    required this.doctor,
    required this.isExpanded,
    required this.onToggle,
    required this.maxLines,
  }) : super(key: key);

  final Doctor doctor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Doctor',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 75.0),
              child: Text(
                doctor.profileMessage ?? 'No profile message available.',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: isExpanded ? null : maxLines,
              ),
            ),
          ),
          if ((doctor.profileMessage?.length ?? 0) > 70)
            InkWell(
              child: Text(
                isExpanded ? 'Read Less' : 'Read More',
                style: TextStyle(
                    color: Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    fontWeight: FontWeight.w600),
              ),
              onTap: onToggle,
            ),
        ],
      ),
    );
  }
}

class CallButtonsSection extends StatelessWidget {
  const CallButtonsSection({
    Key? key,
    required this.startCall,
  }) : super(key: key);

  final Function(String) startCall;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => startCall('audio'),
            icon: const Icon(Icons.phone, color: Colors.white),
            label:
            const Text('Audio', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Global.getColorFromHex(Global.THEME_COLOR_CODE),
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.03),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => startCall('video'),
            icon: const Icon(Icons.videocam, color: Colors.white),
            label:
            const Text('Video', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Global.getColorFromHex(Global.THEME_COLOR_CODE),
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.03),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestedDoctorsSection extends StatelessWidget {
  const SuggestedDoctorsSection({
    Key? key,
    required this.suggestedDoctors,
    required this.isLoadingSuggestedDoctors,
    required this.getDoctorStatus, // Add this line
  }) : super(key: key);

  final List<Doctor> suggestedDoctors;
  final bool isLoadingSuggestedDoctors;
  final String Function(Doctor) getDoctorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Doctors',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: screenHeight * 0.18,
            child: isLoadingSuggestedDoctors
                ?  Center(
              child: CircularProgressIndicator( // Added color here
                valueColor: AlwaysStoppedAnimation<Color>(Global.getColorFromHex(Global.THEME_COLOR_CODE)),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedDoctors.length,
              itemBuilder: (context, index) {
                final doctor = suggestedDoctors[index];
                return Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.03),
                  child: SuggestedDoctorListItem(
                    doctor: doctor,
                    doctorStatus: getDoctorStatus(doctor),
                    onTap: () {
                      Global.docPosition = index;
                      // Navigate using CupertinoPageRoute for page replacement
                      // Navigator.pushReplacement(
                      //   context,
                      //   CupertinoPageRoute(
                      //     builder: (context) =>
                      //         DoctorProfileScreen(doctor: doctor),
                      //   ),
                      // );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DoctorProfileScreen(  doctor: doctor,
                        )
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}*/


