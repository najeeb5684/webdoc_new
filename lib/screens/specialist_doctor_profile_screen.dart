import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/get_slots_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import 'payment_screen.dart';

class SpecialistDoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const SpecialistDoctorProfileScreen({Key? key, required this.doctor})
      : super(key: key);

  @override
  _SpecialistDoctorProfileScreenState createState() =>
      _SpecialistDoctorProfileScreenState();
}

class _SpecialistDoctorProfileScreenState
    extends State<SpecialistDoctorProfileScreen> {
  double _scrollOffset = 0.0;
  List<Slot> _slots = [];
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;
  bool _isLoading = true;
  String _slotAvailabilityText = '';

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoading = true;
      _slotAvailabilityText = '';
    });
    final apiService = ApiService();
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);
    final formattedDateText = DateFormat('MMM d yyyy').format(_selectedDate);
    final dayOfWeekText = dayOfWeek;

    try {
      final slots = await apiService.getSlots(
        context,
        doctorId: widget.doctor.docid.toString(),
        dayOfWeek: dayOfWeek,
        appointmentDate: formattedDate,
      );

      if (slots != null && slots.isNotEmpty) {
        setState(() {
          _slots = slots;
          _slotAvailabilityText =
          "Available time slots for $dayOfWeekText $formattedDateText";
          _selectedSlot = null;
        });
      } else {
        setState(() {
          _slots = [];
          _slotAvailabilityText = "No slots available for this date.";
          _selectedSlot = null;
        });
        print('No slots available for this date.');
      }
    } catch (e) {
      setState(() {
        _slots = [];
        _slotAvailabilityText = "Failed to load slots. Please try again.";
      });
      print('Error fetching slots: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DateTime> _generateDateList() {
    return List.generate(30, (i) => DateTime.now().add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: screenHeight * 0.45, // Cover 35% of the screen, adjust as needed
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35, // Adjust to overlap image, start from 25% of the screen
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor, // Set background color to white
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
                            10, 20, 10, 100), // Adjusted padding: left, top, right, bottom
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Align items to the center
                          children: [
                            // Doctor's Name
                            Text(
                              '${widget.doctor.firstName} ${widget.doctor.lastName}',
                              style: AppStyles.titleSmall(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTextColor),
                              textAlign: TextAlign.center, // Align text to the center
                            ),
                            const SizedBox(height: 5),

                            // Doctor's Specialty
                            Text(
                              widget.doctor.doctorSpecialties ?? 'Specialist',
                              style: AppStyles.bodyLarge(context).copyWith(color: AppColors.secondaryTextColor),
                              textAlign: TextAlign.center, // Align text to the center
                            ),
                            const SizedBox(height: 5),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time, // Icon for duty time
                                  size: 16,
                                  color: AppColors.secondaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.doctor.doctorDutyTime ?? 'Duty Time',
                                  style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryTextColor,fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center, // Align text to the center
                                ),
                              ],
                            ),



                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                    widget.doctor.experience ?? 'N/A', 'Experience', AppColors.primaryTextColor),
                                _buildInfoItem(
                                    '5/5', 'Rating', AppColors.primaryTextColor),
                                _buildInfoItem('Rs.${widget.doctor.consultationFee}' ?? 'N/A', 'Fee', AppColors.primaryTextColor),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Availability and Date selection
                            _buildAvailabilityAndDateSelection(),

                            SizedBox(height: screenHeight * 0.02),

                            //Time Slots
                            _buildTimeSlotsSection(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Book Appointment Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white, //Background color of the button
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 0,
                bottom: 2 + MediaQuery.of(context).padding.bottom,),
                child: ElevatedButton(
                onPressed: _selectedSlot == null
                    ? null
                    : () {
                  _showConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Book Appointment',
                  style: AppStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white),
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
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityAndDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Date',
            style: AppStyles.titleSmall(context).copyWith(color: AppColors.primaryTextColor,fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _generateDateList().length,
            itemBuilder: (context, index) {
              final date = _generateDateList()[index];
              final formattedDate = DateFormat('EEE, MMM d').format(date);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _fetchSlots();
                  });
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: _selectedDate.day == date.day &&
                        _selectedDate.month == date.month &&
                        _selectedDate.year == date.year
                        ? AppColors.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(
                      color: _selectedDate.day == date.day &&
                          _selectedDate.month == date.month &&
                          _selectedDate.year == date.year
                          ? Colors.black // Black border when selected
                          : Colors.black, // Original grey border
                        width: 0.5
                    ),
                  ),
                  child: Center(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedDate.day == date.day &&
                            _selectedDate.month == date.month &&
                            _selectedDate.year == date.year
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            _slotAvailabilityText,
            style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
          ),
        ),
      ],
    );
  }
  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Time Slot',
            style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor, fontWeight: FontWeight.bold),
          ),
        ),
        _isLoading
            ? const Center(
            child:  CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor),
            ))
            : _slots.isEmpty
            ? Center(
            child: Text(_slotAvailabilityText,
                style: AppStyles.bodyMedium(context)
                    .copyWith(color: AppColors.secondaryTextColor)))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,  // Adjusted aspect ratio
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _slots.length,
          itemBuilder: (context, index) {
            final slot = _slots[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSlot = slot;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedSlot == slot
                      ? AppColors.primaryColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(30.0), // Rounded corners
                  border: Border.all(
                    color: Colors.black,
                      width: 0.5// Always black border
                  ),
                ),
                child: Center(
                  child: Text(
                    slot.time ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedSlot == slot
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  /*Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Time Slot',
            style: AppStyles.titleSmall.copyWith(color: AppColors.primaryTextColor,fontWeight: FontWeight.bold),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _slots.isEmpty
            ? Center(child: Text(_slotAvailabilityText, style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryTextColor)))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _slots.length,
          itemBuilder: (context, index) {
            final slot = _slots[index];
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSlot = slot;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedSlot == slot
                    ? AppColors.primaryColor
                    : Colors.white,
                foregroundColor: _selectedSlot == slot
                    ? Colors.white
                    : Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(
                slot.time ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }*/

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        String formattedTimeSlot = 'Not Selected';
        if (_selectedSlot != null && _selectedSlot!.time != null) {
          try {
            final parsedTime = DateFormat('HH:mm').parse(_selectedSlot!.time!);
            formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
          } catch (e) {
            formattedTimeSlot = 'Invalid Time';
            print('Error formatting time: $e');
          }
        }
        final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
        final timeSlotWithValue = '$formattedDate at $formattedTimeSlot';
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 30),
              const SizedBox(width: 8),
              Text(
                'Confirm Appointment',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                          widget.doctor.imgLink ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryColor, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.doctor.firstName} ${widget.doctor.lastName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medical_services,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.doctor.doctorSpecialties ?? 'Specialist',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, height: 30),
                _ConfirmationItem(
                  icon: Icons.access_time_filled_sharp,
                  label: 'Time Slot:',
                  value: timeSlotWithValue,
                  iconColor: Colors.grey.shade700,
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                _ConfirmationItem(
                  icon: Icons.payments_rounded,
                  label: 'Fee:',
                  value: 'Rs.${widget.doctor.consultationFee}' ?? 'Not Available',
                  iconColor: Colors.grey.shade700,
                ),
                Divider(color: Colors.grey.shade300, height: 20),

                // Beautiful Disclaimer
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,  // Very light background
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade200), // Subtle border
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disclaimer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All doctor consultations and appointments conducted through the WEBDOC platform are the sole responsibility of the respective doctors. WEBDOC serves only as a facilitating platform and does not assume any liability for the medical advice, treatment, or outcomes resulting from these consultations.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4), // Increased height for better readability
                        textAlign: TextAlign.justify, // Justify the text
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                final doctorId = widget.doctor.docid;
                final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final appointmentTime = _selectedSlot!.time;
                final slotNumber = _selectedSlot!.slotNo;
                final fees = widget.doctor.consultationFee;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen.appointment(
                      doctorId: doctorId,
                      appointmentDate: appointmentDate,
                      appointmentTime: appointmentTime,
                      slotNumber: slotNumber.toString(),
                      fees: fees,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 2,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(label,
            style: AppStyles.bodyLarge(context).copyWith(color: AppColors.primaryTextColor,fontWeight: FontWeight.bold)),
        Text(value,
            style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor)),
      ],
    );
  }
}

class _ConfirmationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _ConfirmationItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/*import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';


import '../models/get_slots_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import 'payment_screen.dart';

class SpecialistDoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const SpecialistDoctorProfileScreen({Key? key, required this.doctor})
      : super(key: key);

  @override
  _SpecialistDoctorProfileScreenState createState() =>
      _SpecialistDoctorProfileScreenState();
}

class _SpecialistDoctorProfileScreenState
    extends State<SpecialistDoctorProfileScreen> {
  double _scrollOffset = 0.0;
  List<Slot> _slots = [];
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;
  bool _isLoading = true;
  String _slotAvailabilityText = '';

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoading = true;
      _slotAvailabilityText = '';
    });
    final apiService = ApiService();
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);
    final formattedDateText = DateFormat('MMM d yyyy').format(_selectedDate);
    final dayOfWeekText = dayOfWeek;

    try {
      final slots = await apiService.getSlots(
        context,
        doctorId: widget.doctor.docid.toString(),
        dayOfWeek: dayOfWeek,
        appointmentDate: formattedDate,
      );

      if (slots != null && slots.isNotEmpty) {
        setState(() {
          _slots = slots;
          _slotAvailabilityText =
          "Available time slots for $dayOfWeekText $formattedDateText";
          _selectedSlot = null;
        });
      } else {
        setState(() {
          _slots = [];
          _slotAvailabilityText = "No slots available for this date.";
          _selectedSlot = null;
        });
        print('No slots available for this date.');
      }
    } catch (e) {
      setState(() {
        _slots = [];
        _slotAvailabilityText = "Failed to load slots. Please try again.";
      });
      print('Error fetching slots: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DateTime> _generateDateList() {
    return List.generate(30, (i) => DateTime.now().add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  setState(() {
                    _scrollOffset = scrollNotification.metrics.pixels;
                  });
                }
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.35,
                    pinned: true,
                    backgroundColor: AppColors.primaryColor,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: _scrollOffset > 50
                              ? Colors.white
                              : Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        '', // Empty title
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
                                alignment: Alignment.topCenter,
                                width: constraints.maxWidth,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Global.getColorFromHex(
                                              Global.THEME_COLOR_CODE))),
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
                  SliverToBoxAdapter( // Wrap in SliverToBoxAdapter
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.doctor.firstName} ${widget.doctor.lastName}',
                            style: AppStyles.titleMedium.copyWith(color: AppColors.primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.doctor.doctorSpecialties ?? 'Specialist',
                            style: AppStyles.bodyMedium.copyWith(color: AppColors.primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.doctor.doctorDutyTime ?? 'Duty Time', // Example Duty Time
                           style: AppStyles.bodyMedium.copyWith(color: AppColors.primaryTextColor),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                  widget.doctor.experience ?? 'N/A'   ,'Experience', AppColors.primaryTextColor),
                              _buildInfoItem(
                                  '5', 'Rating',AppColors.primaryTextColor),
                              _buildInfoItem( 'Pakistan','Country', AppColors.primaryTextColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // Availability and Date selection
                        _buildAvailabilityAndDateSelection(),

                        SizedBox(height: screenHeight * 0.02),

                        //Time Slots
                        _buildTimeSlotsSection(),

                        SizedBox(height: screenHeight * 0.12),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02),
                child: ElevatedButton(
                  onPressed: _selectedSlot == null
                      ? null
                      : () {
                    _showConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child:  Text('Book Appointment', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityAndDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Date',
            style: AppStyles.titleSmall,
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _generateDateList().length,
            itemBuilder: (context, index) {
              final date = _generateDateList()[index];
              final formattedDate = DateFormat('EEE, MMM d').format(date);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _fetchSlots();
                  });
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: _selectedDate.day == date.day &&
                        _selectedDate.month == date.month &&
                        _selectedDate.year == date.year
                        ? AppColors.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: _selectedDate.day == date.day &&
                          _selectedDate.month == date.month &&
                          _selectedDate.year == date.year
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedDate.day == date.day &&
                            _selectedDate.month == date.month &&
                            _selectedDate.year == date.year
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            _slotAvailabilityText,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Time Slot',
            style: AppStyles.titleSmall,
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _slots.isEmpty
            ? Center(child: Text(_slotAvailabilityText))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _slots.length,
          itemBuilder: (context, index) {
            final slot = _slots[index];
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSlot = slot;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedSlot == slot
                    ? AppColors.primaryColor
                    : Colors.white,
                foregroundColor: _selectedSlot == slot ? Colors.white : Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(
                slot.time ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        String formattedTimeSlot = 'Not Selected';
        if (_selectedSlot != null && _selectedSlot!.time != null) {
          try {
            final parsedTime = DateFormat('HH:mm').parse(_selectedSlot!.time!);
            formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
          } catch (e) {
            formattedTimeSlot = 'Invalid Time';
            print('Error formatting time: $e');
          }
        }
        final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
        final timeSlotWithValue = '$formattedDate at $formattedTimeSlot';
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 30),
              const SizedBox(width: 8),
              Text(
                'Confirm Appointment',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 20, // Smaller text size
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.doctor.imgLink ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.doctor.firstName} ${widget.doctor.lastName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.doctor.doctorSpecialties ?? 'Specialist',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, height: 30),
                _ConfirmationItem(
                  icon: Icons.access_time_filled_sharp,
                  label: 'Time Slot:',
                  value: timeSlotWithValue,
                  iconColor: Colors.grey.shade700,
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                _ConfirmationItem(
                  icon: Icons.monetization_on,
                  label: 'Fee:',
                  value: 'Rs. 100',
                  iconColor: Colors.grey.shade700,
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                const SizedBox(height: 8),
                const Text(
                  'Please review the details before confirming.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                //  Extract data here
                final doctorId = widget.doctor.docid; //widget.doctor.id.toString();
                final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final appointmentTime = _selectedSlot!.time;
                final slotNumber = _selectedSlot!.slotNo;
                final fees = "1";

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen.appointment( // Use the named constructor
                        doctorId: doctorId,
                        appointmentDate: appointmentDate,
                        appointmentTime: appointmentTime,
                        slotNumber: slotNumber.toString(),
                        fees: fees
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem( String label, String value,Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: textColor)),
        Text(value,
            style: TextStyle(fontSize: 16, color: AppColors.secondaryTextColor)),
      ],
    );
  }
}


class _ConfirmationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _ConfirmationItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}*/



/*import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/get_slots_response.dart';
import '../services/api_service.dart';
import '../utils/global.dart';
import 'payment_screen.dart';

class SpecialistDoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const SpecialistDoctorProfileScreen({Key? key, required this.doctor})
      : super(key: key);

  @override
  _SpecialistDoctorProfileScreenState createState() =>
      _SpecialistDoctorProfileScreenState();
}

class _SpecialistDoctorProfileScreenState
    extends State<SpecialistDoctorProfileScreen> {
  double _scrollOffset = 0.0;
  List<Slot> _slots = [];
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;
  bool _isLoading = true;
  String _slotAvailabilityText = '';

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoading = true;
      _slotAvailabilityText = '';
    });
    final apiService = ApiService();
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);
    final formattedDateText = DateFormat('MMM d yyyy').format(_selectedDate);
    final dayOfWeekText = dayOfWeek;

    try {
      final slots = await apiService.getSlots(
        context,
        doctorId: widget.doctor.docid.toString(),
        dayOfWeek: dayOfWeek,
        appointmentDate: formattedDate,
      );

      if (slots != null && slots.isNotEmpty) {
        setState(() {
          _slots = slots;
          _slotAvailabilityText = "Available time slots for $dayOfWeekText $formattedDateText";
          _selectedSlot = null;
        });
      } else {
        setState(() {
          _slots = [];
          _slotAvailabilityText = "No slots available for this date.";
          _selectedSlot = null;
        });
        print('No slots available for this date.');
      }
    } catch (e) {
      setState(() {
        _slots = [];
        _slotAvailabilityText = "Failed to load slots. Please try again.";
      });
      print('Error fetching slots: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DateTime> _generateDateList() {
    return List.generate(30, (i) => DateTime.now().add(Duration(days: i)));
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  setState(() {
                    _scrollOffset = scrollNotification.metrics.pixels;
                  });
                }
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.35,
                    pinned: true,
                    backgroundColor:
                    Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: _scrollOffset > 50
                              ? Colors.white
                              : Colors.black),
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
                                alignment: Alignment.topCenter,
                                width: constraints.maxWidth,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Global.getColorFromHex(
                                              Global.THEME_COLOR_CODE))),
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
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        DoctorSummaryCard(doctor: widget.doctor),
                        SizedBox(height: screenHeight * 0.02),
                        AboutDoctorSection(doctor: widget.doctor),
                        SizedBox(height: screenHeight * 0.02),

                        // Availability and Date selection
                        _buildAvailabilityAndDateSelection(),

                        SizedBox(height: screenHeight * 0.02),

                        //Time Slots
                        _buildTimeSlotsSection(),

                        SizedBox(height: screenHeight * 0.12),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02),
                child: ElevatedButton(
                  onPressed: _selectedSlot == null
                      ? null
                      : () {
                    _showConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSlot == null ? Colors.grey :
                    Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.03),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Book Appointment',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityAndDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Appointment Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _generateDateList().length,
            itemBuilder: (context, index) {
              final date = _generateDateList()[index];
              final formattedDate = DateFormat('EEE, MMM d').format(date);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _fetchSlots();
                  });
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: _selectedDate.day == date.day &&
                        _selectedDate.month == date.month &&
                        _selectedDate.year == date.year
                        ? Global.getColorFromHex(Global.THEME_COLOR_CODE)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: _selectedDate.day == date.day &&
                          _selectedDate.month == date.month &&
                          _selectedDate.year == date.year
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedDate.day == date.day &&
                            _selectedDate.month == date.month &&
                            _selectedDate.year == date.year
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            _slotAvailabilityText,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Select Time Slot',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _slots.isEmpty
            ? Center(child: Text(_slotAvailabilityText))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _slots.length,
          itemBuilder: (context, index) {
            final slot = _slots[index];
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSlot = slot;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedSlot == slot
                    ? Global.getColorFromHex(Global.THEME_COLOR_CODE)
                    : Colors.white,
                foregroundColor: _selectedSlot == slot ? Colors.white : Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(
                slot.time ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        String formattedTimeSlot = 'Not Selected';
        if (_selectedSlot != null && _selectedSlot!.time != null) {
          try {
            final parsedTime = DateFormat('HH:mm').parse(_selectedSlot!.time!);
            formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
          } catch (e) {
            formattedTimeSlot = 'Invalid Time';
            print('Error formatting time: $e');
          }
        }
        final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
        final timeSlotWithValue = '$formattedDate at $formattedTimeSlot';
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 30),
              const SizedBox(width: 8),
              Text(
                'Confirm Appointment',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 20, // Smaller text size
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.doctor.imgLink ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.doctor.firstName} ${widget.doctor.lastName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.doctor.doctorSpecialties ?? 'Specialist',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, height: 30),
                _ConfirmationItem(
                  icon: Icons.access_time_filled_sharp,
                  label: 'Time Slot:',
                  value: timeSlotWithValue,
                  iconColor: Colors.grey.shade700,
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                _ConfirmationItem(
                  icon: Icons.monetization_on,
                  label: 'Fee:',
                  value: 'Rs. 100',
                  iconColor: Colors.grey.shade700,
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                const SizedBox(height: 8),
                const Text(
                  'Please review the details before confirming.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                //  Extract data here
                final doctorId = widget.doctor.docid; //widget.doctor.id.toString();
                final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final appointmentTime = _selectedSlot!.time;
                final slotNumber = _selectedSlot!.slotNo;
                final fees = "1";

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen.appointment( // Use the named constructor
                        doctorId: doctorId,
                        appointmentDate: appointmentDate,
                        appointmentTime: appointmentTime,
                        slotNumber: slotNumber.toString(),
                        fees: fees
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard({
    Key? key,
    required this.doctor,
  }) : super(key: key);

  final Doctor doctor;

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
            doctor.doctorSpecialties ?? 'Specialty not available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                  Icons.work, 'Experience', doctor.experience ?? 'N/A'),
              _buildInfoItem(
                  Icons.star, 'Rating', doctor.averageRating ?? 'N/A'),
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
        Icon(icon,
            color: Global.getColorFromHex(Global.THEME_COLOR_CODE), size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AboutDoctorSection extends StatefulWidget {
  const AboutDoctorSection({
    Key? key,
    required this.doctor,
  }) : super(key: key);

  final Doctor doctor;

  @override
  _AboutDoctorSectionState createState() => _AboutDoctorSectionState();
}

class _AboutDoctorSectionState extends State<AboutDoctorSection> {
  bool _isExpanded = false;
  final int _maxLines = 3;

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
              constraints: _isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 75.0),
              child: Text(
                widget.doctor.detailedInformation ??
                    'No profile message available.',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: _isExpanded ? null : _maxLines,
              ),
            ),
          ),
          if ((widget.doctor.detailedInformation?.length ?? 0) > 70)
            InkWell(
              child: Text(
                _isExpanded ? 'Read Less' : 'Read More',
                style: TextStyle(
                    color: Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    fontWeight: FontWeight.w600),
              ),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
        ],
      ),
    );
  }
}

class _ConfirmationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _ConfirmationItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}*/

/*import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/global.dart';
import 'book_slot_screen.dart';

class SpecialistDoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const SpecialistDoctorProfileScreen({Key? key, required this.doctor})
      : super(key: key);

  @override
  _SpecialistDoctorProfileScreenState createState() =>
      _SpecialistDoctorProfileScreenState();
}

class _SpecialistDoctorProfileScreenState
    extends State<SpecialistDoctorProfileScreen> {
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  setState(() {
                    _scrollOffset = scrollNotification.metrics.pixels;
                  });
                }
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.35,
                    pinned: true,
                    backgroundColor:
                    Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: _scrollOffset > 50
                              ? Colors.white
                              : Colors.black),
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
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    // Added color here
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Global.getColorFromHex(
                                              Global.THEME_COLOR_CODE))),
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
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        DoctorSummaryCard(doctor: widget.doctor),
                        SizedBox(height: screenHeight * 0.02),
                        AboutDoctorSection(doctor: widget.doctor),
                        SizedBox(height: screenHeight * 0.12), // Added extra space
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity, //Take up full width
              color: Colors.transparent, // Make the Container transparent
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookSlotScreen(
                          doctor: widget.doctor,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.03),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Book Appointment',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorSummaryCard extends StatelessWidget {
  const DoctorSummaryCard({
    Key? key,
    required this.doctor,
  }) : super(key: key);

  final Doctor doctor;

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
            doctor.doctorSpecialties ?? 'Specialty not available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                  Icons.work, 'Experience', doctor.experience ?? 'N/A'),
              _buildInfoItem(
                  Icons.star, 'Rating', doctor.averageRating ?? 'N/A'),
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
        Icon(icon,
            color: Global.getColorFromHex(Global.THEME_COLOR_CODE), size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AboutDoctorSection extends StatefulWidget {
  const AboutDoctorSection({
    Key? key,
    required this.doctor,
  }) : super(key: key);

  final Doctor doctor;

  @override
  _AboutDoctorSectionState createState() => _AboutDoctorSectionState();
}

class _AboutDoctorSectionState extends State<AboutDoctorSection> {
  bool _isExpanded = false;
  final int _maxLines = 3;

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
              constraints: _isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 75.0),
              child: Text(
                widget.doctor.detailedInformation ??
                    'No profile message available.',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                softWrap: true,
                overflow: TextOverflow.fade,
                maxLines: _isExpanded ? null : _maxLines,
              ),
            ),
          ),
          if ((widget.doctor.detailedInformation?.length ?? 0) > 70)
            InkWell(
              child: Text(
                _isExpanded ? 'Read Less' : 'Read More',
                style: TextStyle(
                    color: Global.getColorFromHex(Global.THEME_COLOR_CODE),
                    fontWeight: FontWeight.w600),
              ),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
        ],
      ),
    );
  }
}*/


