import 'package:Webdoc/screens/video_call_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/upcoming_appointments_response.dart';
import '../screens/specialist_category_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/permission_util.dart';
import '../utils/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';

class UpcomingAppointmentsList extends StatelessWidget {
  final List<UpcomingAppointment> appointments;

  const UpcomingAppointmentsList({Key? key, required this.appointments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return appointments.isNotEmpty
        ? SizedBox(
      height: 180, // Adjust height to fit card properly
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return Container(
            width: 270, // Adjust card width as needed to fit content
            margin: const EdgeInsets.only(right: 8.0),
            child: AppointmentCard(appointment: appointment),
          );
        },
      ),
    )
        : const NoAppointments();
  }
}





class AppointmentCard extends StatefulWidget {
  final UpcomingAppointment appointment;

  const AppointmentCard({Key? key, required this.appointment}) : super(key: key);

  @override
  _AppointmentCardState createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  Duration? _timeUntilAppointment;
  Timer? _timer;
  bool _appointmentReady = false;
  bool _imageLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilAppointment(); // Initial calculation
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant AppointmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the appointment data has changed
    if (widget.appointment != oldWidget.appointment) {
      _stopTimer();
      _calculateTimeUntilAppointment(); // Re-calculate on update
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // Separate function to calculate the time
  void _calculateTimeUntilAppointment() {
    try {
      final appointmentDateTime = DateFormat('dd-MMM-yyyy hh:mm a').parse('${widget.appointment.appointmentDate} ${widget.appointment.appointmentTime}');
      final now = DateTime.now(); // Capture the current time at the moment of calculation
      _timeUntilAppointment = appointmentDateTime.difference(now);

      // Handle cases where the appointment has already passed
      if (_timeUntilAppointment!.isNegative) {
        _timeUntilAppointment = Duration.zero; // Prevent negative duration
        _setAppointmentReady(true); //Set to true using the method to update the UI
      } else {
        _setAppointmentReady(false);  //Set to false using the method to update the UI
      }
    } catch (e) {
      print('Error parsing date: $e');
      _setAppointmentReady(false); // Default to timer if parsing fails
    }
  }

  void _startTimer() {
    // Cancel any existing timer
    _stopTimer();

    if(_appointmentReady) return; //If button is already ready

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _calculateTimeUntilAppointment();

      setState(() {
        if (_timeUntilAppointment!.inSeconds <= 0) {
          _setAppointmentReady(true);
          _stopTimer();
        }
      });
    });
  }

  // Method to safely update _appointmentReady and trigger a UI update.
  void _setAppointmentReady(bool ready) {
    if (mounted) {
      setState(() {
        _appointmentReady = ready;
      });
    }
  }


  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> forwardToVideoRoom(String? docEmail, String? appointmentNo) async {
    try {
      /*final DatabaseReference referenceNew = FirebaseDatabase.instance
          .ref()
          .child("DoctorCall")
          .child(docEmail!.replaceAll(".", ""));

      final Map<String, dynamic> hashMap = {
        "AppointmentID": appointmentNo,
        "CallType": "Incoming Video Call",
        "CallingPlatform": "Webdoc Flutter",
        "IsCalling": "true",
        "SenderEmail": '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
      };

      await referenceNew.update(hashMap);*/
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VideoCallScreen(
                channelName: widget.appointment.email.toString(),
                doctorName: widget.appointment.firstName.toString(),
                doctorImageUrl: widget.appointment.imgLink.toString())),
      );
      Global.appointmentNo = appointmentNo;
    } catch (e) {
      print("Error forwarding to video room: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to start the call. Please try again."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDateTime = DateFormat('dd-MMM-yyyy hh:mm a')
        .parse('${widget.appointment.appointmentDate} ${widget.appointment.appointmentTime}');
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(appointmentDateTime);
    final formattedTime = DateFormat('h:mm a').format(appointmentDateTime);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: AppColors.primaryColor,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important for dynamic size
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30), //Circular profile pic
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            widget.appointment.imgLink ?? 'URL_TO_DEFAULT_IMAGE',
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _imageLoading = false;
                                    });
                                  }
                                });
                                return child;
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.backgroundColor,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              }
                            },
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          ),
                          if (_imageLoading)
                            Container(
                              color: Colors.black.withOpacity(0.1),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.appointment.firstName} ${widget.appointment.lastName}',
                          style: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.w700, color: AppColors.backgroundColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        /* Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              'Cardiologist',
                              style: AppStyles.bodyMedium.copyWith(color: AppColors.backgroundColor),
                            ),
                          ],
                        ),*/
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.backgroundColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: AppStyles.bodySmall(context).copyWith(color: AppColors.backgroundColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.backgroundColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$formattedTime',
                              style: AppStyles.bodySmall(context).copyWith(color: AppColors.backgroundColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Conditionally show timer or Join Call button
              _appointmentReady
                  ? Center(
                child: ElevatedButton(
                  onPressed: () async {
                    bool hasPermissions = true;
                    if (Platform.isAndroid) {
                      hasPermissions = await PermissionUtil.requestPermissions(context);
                    }

                    if (hasPermissions) {
                      forwardToVideoRoom(widget.appointment.email, widget.appointment.appointmentNo);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Less Rounded button
                    ),
                  ),
                  child: const Text('Join Call'),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Time:',
                    style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.backgroundColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.timer, color: AppColors.backgroundColor, size: 20),
                      Text(
                        _formatDuration(_timeUntilAppointment!),
                        style: AppStyles.bodyLarge(context).copyWith(color: AppColors.backgroundColor, fontWeight: FontWeight.bold),
                      ),


                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*class AppointmentCard extends StatefulWidget {
  final UpcomingAppointment appointment;

  const AppointmentCard({Key? key, required this.appointment}) : super(key: key);

  @override
  _AppointmentCardState createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  Duration? _timeUntilAppointment;
  Timer? _timer;
  bool _appointmentReady = false;
  bool _imageLoading = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    try {
      final appointmentDateTime = DateFormat('dd-MMM-yyyy hh:mm a').parse('${widget.appointment.appointmentDate} ${widget.appointment.appointmentTime}');

      _timeUntilAppointment = appointmentDateTime.difference(DateTime.now());

      if (_timeUntilAppointment!.isNegative) {
        setState(() {
          _appointmentReady = true;
        });
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _timeUntilAppointment = appointmentDateTime.difference(DateTime.now());

          if (_timeUntilAppointment!.isNegative) {
            _appointmentReady = true;
            _timer?.cancel();
          }
        });
      });
    } catch (e) {
      print('Error parsing date: $e');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> forwardToVideoRoom(String? docEmail, String? appointmentNo) async {
    try {
      *//*final DatabaseReference referenceNew = FirebaseDatabase.instance
          .ref()
          .child("DoctorCall")
          .child(docEmail!.replaceAll(".", ""));

      final Map<String, dynamic> hashMap = {
        "AppointmentID": appointmentNo,
        "CallType": "Incoming Video Call",
        "CallingPlatform": "Webdoc Flutter",
        "IsCalling": "true",
        "SenderEmail": '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
      };

      await referenceNew.update(hashMap);*//*
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VideoCallScreen(
                channelName: widget.appointment.email.toString(),
                doctorName: widget.appointment.firstName.toString(),
                doctorImageUrl: widget.appointment.imgLink.toString())),
      );
      Global.appointmentNo = appointmentNo;
    } catch (e) {
      print("Error forwarding to video room: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to start the call. Please try again."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDateTime = DateFormat('dd-MMM-yyyy hh:mm a')
        .parse('${widget.appointment.appointmentDate} ${widget.appointment.appointmentTime}');
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(appointmentDateTime);
    final formattedTime = DateFormat('h:mm a').format(appointmentDateTime);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: AppColors.primaryColor,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important for dynamic size
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30), //Circular profile pic
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            widget.appointment.imgLink ?? 'URL_TO_DEFAULT_IMAGE',
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _imageLoading = false;
                                    });
                                  }
                                });
                                return child;
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.backgroundColor,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              }
                            },
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          ),
                          if (_imageLoading)
                            Container(
                              color: Colors.black.withOpacity(0.1),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.appointment.firstName} ${widget.appointment.lastName}',
                          style: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.w700, color: AppColors.backgroundColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                       *//* Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              'Cardiologist',
                              style: AppStyles.bodyMedium.copyWith(color: AppColors.backgroundColor),
                            ),
                          ],
                        ),*//*
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.backgroundColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: AppStyles.bodySmall(context).copyWith(color: AppColors.backgroundColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.backgroundColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$formattedTime',
                              style: AppStyles.bodySmall(context).copyWith(color: AppColors.backgroundColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Conditionally show timer or Join Call button
              _appointmentReady
                  ? Center(
                child: ElevatedButton(
                  onPressed: () async {
                    bool hasPermissions = true;
                    if (Platform.isAndroid) {
                      hasPermissions = await PermissionUtil.requestPermissions(context);
                    }

                    if (hasPermissions) {
                      forwardToVideoRoom(widget.appointment.email, widget.appointment.appointmentNo);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Less Rounded button
                    ),
                  ),
                  child: const Text('Join Call'),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Time:',
                    style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.backgroundColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.timer, color: AppColors.backgroundColor, size: 20),
                      Text(
                        _formatDuration(_timeUntilAppointment!),
                        style: AppStyles.bodyLarge(context).copyWith(color: AppColors.backgroundColor, fontWeight: FontWeight.bold),
                      ),


                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/

class NoAppointments extends StatelessWidget {
  const NoAppointments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/no_appointments.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                "No upcoming appointments",
                style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w500, color: AppColors.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Schedule one now to get started!",
                style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SpecialistCategoryScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Schedule Appointment"),
              ),
            ],
          ),
        ));
  }
}