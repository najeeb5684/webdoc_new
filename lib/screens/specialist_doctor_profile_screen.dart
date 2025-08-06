



import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/get_slots_response.dart';
import '../models/wallet_balance_response.dart';
import '../models/book_slot_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
import 'payment_screen.dart';
import 'package:flutter/services.dart';


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

  List<Slot> _slots = [];
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;
  bool _isLoading = true;
  String _slotAvailabilityText = '';
  bool _isBookingAppointment = false;

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
              height: screenHeight * 0.45,
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(60)),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context,
                    BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.doctor.firstName} ${widget.doctor.lastName}',
                              style: AppStyles.titleSmall(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.doctor.doctorSpecialties ?? 'Specialist',
                              style: AppStyles.bodyLarge(context).copyWith(
                                  color: AppColors.secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.secondaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.doctor.doctorDutyTime ?? 'Duty Time',
                                  style: AppStyles.bodySmall(context).copyWith(
                                      color: AppColors.primaryTextColor,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                    widget.doctor.experience ?? 'N/A',
                                    'Experience',
                                    AppColors.primaryTextColor),
                                _buildInfoItem('5/5', 'Rating',
                                    AppColors.primaryTextColor),
                                _buildInfoItem(
                                    'Rs.${widget.doctor.consultationFee}' ??
                                        'N/A',
                                    'Fee',
                                    AppColors.primaryTextColor),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildAvailabilityAndDateSelection(),
                            SizedBox(height: screenHeight * 0.02),
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
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 0,
                bottom: 2 + MediaQuery.of(context).padding.bottom,
              ),
              child: ElevatedButton(
                onPressed: _selectedSlot == null || _isBookingAppointment
                    ? null
                    : () {
                  // Start the process to get wallet balance and show confirmation dialog
                  _getBookAppointment();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isBookingAppointment
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                    : Text(
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
            style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor, fontWeight: FontWeight.bold),
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
                        width: 0.5),
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
            style: AppStyles.bodyMedium(context)
                .copyWith(color: AppColors.secondaryTextColor),
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
            child: CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ))
            : _slots.isEmpty
            ? Center(
            child: Text(_slotAvailabilityText,
                style: AppStyles.bodyMedium(context).copyWith(
                    color: AppColors.secondaryTextColor)))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
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
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                      color: Colors.black, width: 0.5),
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

  // Method to encapsulate getting wallet balance and showing confirmation dialog
  Future<void> _getBookAppointment() async {
    setState(() {
      _isBookingAppointment = true;
    });

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    String walletBalance = "0"; // Initialize walletBalance

    try {
      WalletBalanceResponse? walletBalanceResponse =
      await apiService.getWalletBalance(context, patientId);

      if (walletBalanceResponse != null) {
        walletBalance = walletBalanceResponse.payLoad.balance;
      }

      if (!mounted) return; // Check if the widget is still in the tree

      // Show the confirmation dialog with the wallet balance
      _showConfirmationDialog(context, walletBalance);
    } catch (e) {
      // Handle error
      print("Error fetching wallet balance: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching wallet balance: ${e.toString()}')));
    } finally {
      setState(() {
        _isBookingAppointment = false;
      });
    }
  }

  void _showConfirmationDialog(BuildContext context, String walletBalance) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return ConfirmationDialog(
          doctor: widget.doctor,
          selectedDate: _selectedDate,
          selectedSlot: _selectedSlot,
          walletBalance: walletBalance,
          onConfirm: (couponCode, discountedFee) => _processPayment(walletBalance, couponCode, discountedFee),
          consultationFee: widget.doctor.consultationFee.toString(),
        );
      },
    );
  }

  Future<void> _processPayment(String walletBalance, String? couponCode, String? discountedFee) async {
    Navigator.of(context).pop(); // Close the confirmation dialog
    final consultationFee = widget.doctor.consultationFee is num
        ? widget.doctor.consultationFee as num
        : num.tryParse(widget.doctor.consultationFee.toString()) ?? 0;

    if (int.parse(walletBalance) >= consultationFee) {
      // Book with wallet
      _bookAppointmentWithWallet(couponCode: couponCode, discountedFee: discountedFee);
    } else {
      // Handle insufficient wallet balance
      if (int.parse(walletBalance) > 0) {
        // Partially pay with wallet and navigate to payment screen for remaining amount
        final remainingAmount = consultationFee - int.parse(walletBalance);
        _navigateToPaymentScreen(remainingAmount, couponCode: couponCode);
        Global.paymentMethod = "mixed";
      } else {
        // No wallet balance, navigate to payment screen for full amount
        _navigateToPaymentScreen(consultationFee, couponCode: couponCode);
        Global.paymentMethod = "stripe";
      }
    }
  }

  /*void _navigateToPaymentScreen(num amount, {String? couponCode}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen.appointment(
            doctorId: widget.doctor.docid,
            appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
            appointmentTime: _selectedSlot!.time,
            slotNumber: _selectedSlot!.slotNo.toString(),
            fees: amount.toString(), // Pass the remaining amount
            couponCode: couponCode
        ),
      ),
    );
  }
*/
  void _navigateToPaymentScreen(num amount, {String? couponCode}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen.appointment(
            doctorId: widget.doctor.docid,
            appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
            appointmentTime: _selectedSlot!.time,
            slotNumber: _selectedSlot!.slotNo.toString(),
            fees: amount.toString(), // Pass the remaining amount
            couponCode: couponCode ?? "" // Use empty string if null
        ),
      ),
    );
  }

  Future<void> _bookAppointmentWithWallet({String? couponCode, String? discountedFee}) async {
    // Capture the context
    final currentContext = context;

    if (!mounted) return; // Initial check

    // Show loading dialog
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColorLight,
          content: Row(
            children: const [
              CircularProgressIndicator(color: AppColors.primaryColor,),
              SizedBox(width: 10),
              Text("Booking Appointment..."),
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final doctorId = widget.doctor.docid.toString();
    final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointmentTime = _selectedSlot!.time;
    final slotNumber = _selectedSlot!.slotNo.toString();

    // Determine the price to pass based on whether a discount was applied
    String priceToPass = widget.doctor.consultationFee.toString(); // Default to original fee
    if (discountedFee != null && discountedFee.isNotEmpty) {
      priceToPass = discountedFee; // Use the discounted fee if available
    }

    try {
      BookSlotResponse? bookSlotResponse = await apiService.bookSlot(
          context: currentContext,
          patientId: patientId,
          doctorId: doctorId,
          appointmentDate: appointmentDate,
          appointmentTime: appointmentTime.toString(),
          slotNumber: slotNumber,
          paymentMethod: "wallet",
          price: priceToPass,  // Pass the correct price
          couponCode: couponCode ?? ""
      );

      // Safely close the loading dialog
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Check if still mounted after API call

      if (bookSlotResponse != null && bookSlotResponse.statusCode == 1) {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.primaryColorLight,
              title: const Text('Appointment Booked!'),
              content:
              const Text('Your appointment has been booked successfully.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: TextStyle(color: AppColors.primaryColor),),
                  onPressed: () {
                    //It is important to check for Navigator.canPop(context) before calling Navigator.pop(context). This check avoids errors when the navigator is not available or has already been popped.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Close success dialog
                    }

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => PastAppointmentsScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
              content: Text(bookSlotResponse?.statusMessage?.join(', ') ??
                  'Failed to book appointment')),
        );
      }
    } catch (e) {
      // Ensure dialog is closed in case of an error
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Final safety check

      ScaffoldMessenger.of(currentContext)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'))); // Show the error
    }
  }

  /*Future<void> _bookAppointmentWithWallet({String? couponCode}) async {
    // Capture the context
    final currentContext = context;

    if (!mounted) return; // Initial check

    // Show loading dialog
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Booking Appointment..."),
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final doctorId = widget.doctor.docid.toString();
    final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointmentTime = _selectedSlot!.time;
    final slotNumber = _selectedSlot!.slotNo.toString();

    try {
      BookSlotResponse? bookSlotResponse = await apiService.bookSlot(
          context: currentContext,
          patientId: patientId,
          doctorId: doctorId,
          appointmentDate: appointmentDate,
          appointmentTime: appointmentTime.toString(),
          slotNumber: slotNumber,
          paymentMethod: "wallet",
          price: widget.doctor.consultationFee.toString(),
          couponCode: couponCode ?? ""
      );

      // Safely close the loading dialog
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Check if still mounted after API call

      if (bookSlotResponse != null && bookSlotResponse.statusCode == 1) {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Appointment Booked!'),
              content:
              const Text('Your appointment has been booked successfully.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    //It is important to check for Navigator.canPop(context) before calling Navigator.pop(context). This check avoids errors when the navigator is not available or has already been popped.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Close success dialog
                    }

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => PastAppointmentsScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
              content: Text(bookSlotResponse?.statusMessage?.join(', ') ??
                  'Failed to book appointment')),
        );
      }
    } catch (e) {
      // Ensure dialog is closed in case of an error
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Final safety check

      ScaffoldMessenger.of(currentContext)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'))); // Show the error
    }
  }*/

  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(label,
            style: AppStyles.bodyLarge(context)
                .copyWith(color: AppColors.primaryTextColor, fontWeight: FontWeight.bold)),
        Text(value,
            style: AppStyles.bodyMedium(context)
                .copyWith(color: AppColors.secondaryTextColor)),
      ],
    );
  }
}

class ConfirmationDialog extends StatefulWidget {
  final Doctor doctor;
  final DateTime selectedDate;
  final Slot? selectedSlot;
  final String walletBalance;
  final String consultationFee;
  final Function(String?, String?) onConfirm;

  const ConfirmationDialog({
    Key? key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedSlot,
    required this.walletBalance,
    required this.onConfirm,
    required this.consultationFee,
  }) : super(key: key);

  @override
  ConfirmationDialogState createState() => ConfirmationDialogState();
}

class ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _isFollowUpChecked = false;
  bool _isLoadingCouponCheck = false;
  String? _followUpCode;
  String? _discountedFee;
  final TextEditingController _followUpController = TextEditingController();

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }
  Future<void> _checkFollowUpCode() async {
    setState(() {
      _isLoadingCouponCheck = true;
    });

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final doctorId = widget.doctor.docid.toString();

    String message = "";  // Initialize message with a default value

    try {
      final response = await apiService.checkFollowUpCoupon(
        context: context,
        patientId: patientId,
        doctorId: doctorId,
        couponCode: _followUpCode??"", // Pass _followUpCode which can be null
      );


      if (response != null && response.statusCode == 1) {
        // Success, calculate discounted fee
        final originalFee = num.parse(widget.consultationFee);
        final discounted = originalFee * 0.5;

        // Convert to integer and then to string to remove trailing .0
        final discountedFeeString = discounted.toInt().toString();

        setState(() {
          _discountedFee = discountedFeeString; // Store the string value
          message = 'Coupon applied successfully! You now get 50% off.';
        });
      } else {
        // Error
        setState(() {
          _discountedFee = null;
          message = response?.statusMessage.join(', ') ?? 'Invalid coupon code.';
        });
      }

      // Show message in the confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.primaryColorLight, // set the back ground color
            title: const Text('Coupon Status'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child:  Text('OK', style: TextStyle(color: AppColors.primaryColor),), // Text color here
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _discountedFee = null;
        message = 'Error checking coupon: ${e.toString()}';  // Assign value in catch as well

        // Show error message in dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.primaryColorLight, // set the back ground color
              title: const Text('Coupon Error'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: TextStyle(color: AppColors.primaryColor),),  // Text color here
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
    } finally {
      setState(() {
        _isLoadingCouponCheck = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formattedTimeSlot = 'Not Selected';
    if (widget.selectedSlot != null && widget.selectedSlot!.time != null) {
      try {
        final parsedTime =
        DateFormat('HH:mm').parse(widget.selectedSlot!.time!);
        formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
      } catch (e) {
        formattedTimeSlot = 'Invalid Time';
        print('Error formatting time: $e');
      }
    }
    final formattedDate = DateFormat('MMM d, yyyy').format(widget.selectedDate);
    final timeSlotWithValue = '$formattedDate at $formattedTimeSlot';

    num consultationFee;
    if (_discountedFee != null) {
      consultationFee = num.parse(_discountedFee!);
    } else {
      consultationFee = widget.doctor.consultationFee is num
          ? widget.doctor.consultationFee as num
          : num.tryParse(widget.doctor.consultationFee.toString()) ?? 0;
    }
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
              value: _discountedFee != null ? 'Rs.$_discountedFee' : 'Rs.${widget.consultationFee}',
              iconColor: Colors.grey.shade700,
            ),
            Divider(color: Colors.grey.shade300, height: 20),
            _ConfirmationItem(
              icon: Icons.account_balance_wallet,
              label: 'Wallet Balance:',
              value: 'Rs.${widget.walletBalance}',
              iconColor: Colors.green, // Or any color to indicate wallet
            ),
            Divider(color: Colors.grey.shade300, height: 20),
            // Checkbox for Follow Up Consultation
            Row(
              children: [
                Checkbox(
                  value: _isFollowUpChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isFollowUpChecked = value!;
                      _followUpCode = null;
                      _discountedFee = null;
                    });
                  },
                  checkColor: Colors.white, // Color of the tick
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.primaryColor; // Color when checked
                      }
                      return Colors.transparent;   // Make the check box transparent.
                    },
                  ),
                  side:  _isFollowUpChecked ? BorderSide(color: AppColors.primaryColor, width: 2) : BorderSide(color: Colors.grey, width: 1),  // Primary color on when cheked


                ),
                const Text('Follow Up Consultation'),
              ],
            ),
            if (_isFollowUpChecked)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _followUpController,
                      decoration: InputDecoration(
                        labelText: 'Enter Follow Up Code',
                        labelStyle: TextStyle(color: AppColors.primaryColor),
                        hintText: 'Enter Code',  // Set the hint text
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey), // Hint text style
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryColor), // Primary color border
                        ),
                        focusedBorder: OutlineInputBorder(  // Color when focused
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),

                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _followUpCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _followUpCode == null || _followUpCode!.isEmpty
                          ? null
                          : () {
                        _checkFollowUpCode();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,  // Use primary color
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoadingCouponCheck
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ))
                          : const Text('Submit Code'),
                    ),
                  ],
                ),
              ),

            Divider(color: Colors.grey.shade300, height: 20),
            // Beautiful Disclaimer
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
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
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel', style: TextStyle(color: AppColors.primaryColor),),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_followUpCode, _discountedFee);
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
            flex: 4,
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


/*
import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/get_slots_response.dart';
import '../models/wallet_balance_response.dart';
import '../models/book_slot_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
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
  bool _isBookingAppointment = false;

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
              height: screenHeight * 0.45,
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(60)),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context,
                    BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.doctor.firstName} ${widget.doctor.lastName}',
                              style: AppStyles.titleSmall(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.doctor.doctorSpecialties ?? 'Specialist',
                              style: AppStyles.bodyLarge(context).copyWith(
                                  color: AppColors.secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.secondaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.doctor.doctorDutyTime ?? 'Duty Time',
                                  style: AppStyles.bodySmall(context).copyWith(
                                      color: AppColors.primaryTextColor,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                    widget.doctor.experience ?? 'N/A',
                                    'Experience',
                                    AppColors.primaryTextColor),
                                _buildInfoItem('5/5', 'Rating',
                                    AppColors.primaryTextColor),
                                _buildInfoItem(
                                    'Rs.${widget.doctor.consultationFee}' ??
                                        'N/A',
                                    'Fee',
                                    AppColors.primaryTextColor),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildAvailabilityAndDateSelection(),
                            SizedBox(height: screenHeight * 0.02),
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
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 0,
                bottom: 2 + MediaQuery.of(context).padding.bottom,
              ),
              child: ElevatedButton(
                onPressed: _selectedSlot == null || _isBookingAppointment
                    ? null
                    : () {
                  // Start the process to get wallet balance and show confirmation dialog
                  _getBookAppointment();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isBookingAppointment
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                    : Text(
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
            style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor, fontWeight: FontWeight.bold),
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
                        width: 0.5),
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
            style: AppStyles.bodyMedium(context)
                .copyWith(color: AppColors.secondaryTextColor),
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
            child: CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ))
            : _slots.isEmpty
            ? Center(
            child: Text(_slotAvailabilityText,
                style: AppStyles.bodyMedium(context).copyWith(
                    color: AppColors.secondaryTextColor)))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
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
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                      color: Colors.black, width: 0.5),
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

  // Method to encapsulate getting wallet balance and showing confirmation dialog
  Future<void> _getBookAppointment() async {
    setState(() {
      _isBookingAppointment = true;
    });

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    String walletBalance = "0"; // Initialize walletBalance

    try {
      WalletBalanceResponse? walletBalanceResponse =
      await apiService.getWalletBalance(context, patientId);

      if (walletBalanceResponse != null) {
        walletBalance = walletBalanceResponse.payLoad.balance;
      }

      if (!mounted) return; // Check if the widget is still in the tree

      // Show the confirmation dialog with the wallet balance
      _showConfirmationDialog(context, walletBalance);
    } catch (e) {
      // Handle error
      print("Error fetching wallet balance: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching wallet balance: ${e.toString()}')));
    } finally {
      setState(() {
        _isBookingAppointment = false;
      });
    }
  }

  void _showConfirmationDialog(BuildContext context, String walletBalance) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return ConfirmationDialog(
          doctor: widget.doctor,
          selectedDate: _selectedDate,
          selectedSlot: _selectedSlot,
          walletBalance: walletBalance,
          onConfirm: () => _processPayment(walletBalance),
        );
      },
    );
  }

  Future<void> _processPayment(String walletBalance) async {
    Navigator.of(context).pop(); // Close the confirmation dialog
    final consultationFee = widget.doctor.consultationFee is num
        ? widget.doctor.consultationFee as num
        : num.tryParse(widget.doctor.consultationFee.toString()) ?? 0;

    if (int.parse(walletBalance) >= consultationFee) {
      // Book with wallet
      _bookAppointmentWithWallet();
    } else {
      // Handle insufficient wallet balance
      if (int.parse(walletBalance) > 0) {
        // Partially pay with wallet and navigate to payment screen for remaining amount
        final remainingAmount = consultationFee - int.parse(walletBalance);
        _navigateToPaymentScreen(remainingAmount);
        Global.paymentMethod = "mixed";
      } else {
        // No wallet balance, navigate to payment screen for full amount
        _navigateToPaymentScreen(consultationFee);
        Global.paymentMethod = "stripe";
      }
    }
  }

  void _navigateToPaymentScreen(num amount) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen.appointment(
          doctorId: widget.doctor.docid,
          appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          appointmentTime: _selectedSlot!.time,
          slotNumber: _selectedSlot!.slotNo.toString(),
          fees: amount.toString(), // Pass the remaining amount
        ),
      ),
    );
  }

  Future<void> _bookAppointmentWithWallet() async {
    // Capture the context
    final currentContext = context;

    if (!mounted) return; // Initial check

    // Show loading dialog
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Booking Appointment..."),
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final doctorId = widget.doctor.docid.toString();
    final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointmentTime = _selectedSlot!.time;
    final slotNumber = _selectedSlot!.slotNo.toString();

    try {
      BookSlotResponse? bookSlotResponse = await apiService.bookSlot(
        context: currentContext,
        patientId: patientId,
        doctorId: doctorId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime.toString(),
        slotNumber: slotNumber,
        paymentMethod: "wallet",
        price: widget.doctor.consultationFee.toString(),
        couponCode: ""
      );

      // Safely close the loading dialog
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Check if still mounted after API call

      if (bookSlotResponse != null && bookSlotResponse.statusCode == 1) {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Appointment Booked!'),
              content:
              const Text('Your appointment has been booked successfully.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    //It is important to check for Navigator.canPop(context) before calling Navigator.pop(context). This check avoids errors when the navigator is not available or has already been popped.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Close success dialog
                    }

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => PastAppointmentsScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
              content: Text(bookSlotResponse?.statusMessage?.join(', ') ??
                  'Failed to book appointment')),
        );
      }
    } catch (e) {
      // Ensure dialog is closed in case of an error
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Final safety check

      ScaffoldMessenger.of(currentContext)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'))); // Show the error
    }
  }

  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(label,
            style: AppStyles.bodyLarge(context)
                .copyWith(color: AppColors.primaryTextColor, fontWeight: FontWeight.bold)),
        Text(value,
            style: AppStyles.bodyMedium(context)
                .copyWith(color: AppColors.secondaryTextColor)),
      ],
    );
  }
}

class ConfirmationDialog extends StatefulWidget {
  final Doctor doctor;
  final DateTime selectedDate;
  final Slot? selectedSlot;
  final String walletBalance;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    Key? key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedSlot,
    required this.walletBalance,
    required this.onConfirm,
  }) : super(key: key);

  @override
  ConfirmationDialogState createState() => ConfirmationDialogState();
}

class ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formattedTimeSlot = 'Not Selected';
    if (widget.selectedSlot != null && widget.selectedSlot!.time != null) {
      try {
        final parsedTime =
        DateFormat('HH:mm').parse(widget.selectedSlot!.time!);
        formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
      } catch (e) {
        formattedTimeSlot = 'Invalid Time';
        print('Error formatting time: $e');
      }
    }
    final formattedDate = DateFormat('MMM d, yyyy').format(widget.selectedDate);
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
            _ConfirmationItem(
              icon: Icons.account_balance_wallet,
              label: 'Wallet Balance:',
              value: 'Rs.${widget.walletBalance}',
              iconColor: Colors.green, // Or any color to indicate wallet
            ),
            Divider(color: Colors.grey.shade300, height: 20),
            // Beautiful Disclaimer
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
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
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.onConfirm,
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
            flex: 4,
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
*/




/*import 'package:Webdoc/screens/dashboard_screen.dart';
import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:Webdoc/screens/past_appointments_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/get_slots_response.dart';
import '../models/wallet_balance_response.dart';
import '../models/book_slot_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import '../utils/shared_preferences.dart';
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
              height: screenHeight * 0.45,
              child: CachedNetworkImage(
                imageUrl: widget.doctor.imgLink!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          // Content Card
          Positioned(
            top: screenHeight * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(60)),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context,
                    BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.doctor.firstName} ${widget.doctor.lastName}',
                              style: AppStyles.titleSmall(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.doctor.doctorSpecialties ?? 'Specialist',
                              style: AppStyles.bodyLarge(context).copyWith(
                                  color: AppColors.secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.secondaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.doctor.doctorDutyTime ?? 'Duty Time',
                                  style: AppStyles.bodySmall(context).copyWith(
                                      color: AppColors.primaryTextColor,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                    widget.doctor.experience ?? 'N/A',
                                    'Experience',
                                    AppColors.primaryTextColor),
                                _buildInfoItem('5/5', 'Rating',
                                    AppColors.primaryTextColor),
                                _buildInfoItem(
                                    'Rs.${widget.doctor.consultationFee}' ??
                                        'N/A',
                                    'Fee',
                                    AppColors.primaryTextColor),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildAvailabilityAndDateSelection(),
                            SizedBox(height: screenHeight * 0.02),
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
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 0,
                bottom: 2 + MediaQuery.of(context).padding.bottom,
              ),
              child: ElevatedButton(
                onPressed: _selectedSlot == null
                    ? null
                    : () {
                  _showConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            style: AppStyles.titleSmall(context).copyWith(
                color: AppColors.primaryTextColor, fontWeight: FontWeight.bold),
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
                        width: 0.5),
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
            style: AppStyles.bodyMedium(context)
                .copyWith(color: AppColors.secondaryTextColor),
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
            child: CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ))
            : _slots.isEmpty
            ? Center(
            child: Text(_slotAvailabilityText,
                style: AppStyles.bodyMedium(context).copyWith(
                    color: AppColors.secondaryTextColor)))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
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
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                      color: Colors.black, width: 0.5),
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

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return ConfirmationDialog(
          doctor: widget.doctor,
          selectedDate: _selectedDate,
          selectedSlot: _selectedSlot,
          onConfirm: () => _checkWalletBalanceAndShowOptions(),
        );
      },
    );
  }

  Future<void> _checkWalletBalanceAndShowOptions() async {


    // Capture the context *before* the asynchronous operation
    final currentContext = context;

    if (!mounted) return; // Check if the widget is still in the tree

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(color: AppColors.primaryColor),
              SizedBox(width: 10),
              Text("Checking Wallet Balance..."),
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final consultationFee = widget.doctor.consultationFee ?? 0;

    try {
      WalletBalanceResponse? walletBalanceResponse = await apiService.getWalletBalance(currentContext, patientId);

      // Safely close the dialog using the captured context
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }


      if (!mounted) return; // Check again after the API call


      if (walletBalanceResponse != null) {
        int walletBalance = int.tryParse(walletBalanceResponse.payLoad.balance) ?? 0;

        if (walletBalance >= (consultationFee is num ? consultationFee : num.tryParse(consultationFee.toString()) ?? 0)) {
          // Show the payment options dialog
          showDialog(
            context: currentContext,
            builder: (BuildContext context) {
              return PaymentOptionsDialog(
                doctor: widget.doctor,
                selectedDate: _selectedDate,
                selectedSlot: _selectedSlot,
                walletBalance: walletBalance,
                onWalletSelected: () => _bookAppointmentWithWallet(),
                onBankSelected: () {
                  Navigator.pushReplacement(
                    currentContext, // Use captured context
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen.appointment(
                        doctorId: widget.doctor.docid,
                        appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                        appointmentTime: _selectedSlot!.time,
                        slotNumber: _selectedSlot!.slotNo.toString(),
                        fees: widget.doctor.consultationFee,
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else {
          // Directly navigate to the payment screen
          Navigator.pushReplacement(
            currentContext, // Use captured context
            MaterialPageRoute(
              builder: (context) => PaymentScreen.appointment(
                doctorId: widget.doctor.docid,
                appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                appointmentTime: _selectedSlot!.time,
                slotNumber: _selectedSlot!.slotNo.toString(),
                fees: widget.doctor.consultationFee,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(  //Use captured context
          const SnackBar(content: Text('Failed to load wallet balance.')),
        );
      }
    } catch (e) {
      // Safely close the dialog if it's still open
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return;  // Final check before using context

      ScaffoldMessenger.of(currentContext).showSnackBar( // Use captured context
        SnackBar(content: Text('Error: ${e.toString()}')),
      ); // Show the error
    }
  }


  Future<void> _bookAppointmentWithWallet() async {
    // Capture the context
    final currentContext = context;

    if (!mounted) return; // Initial check

    // Show loading dialog
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Booking Appointment..."),
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    final patientId = SharedPreferencesManager.getString("id") ?? "0";
    final doctorId = widget.doctor.docid.toString();
    final appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointmentTime = _selectedSlot!.time;
    final slotNumber = _selectedSlot!.slotNo.toString();

    try {
      BookSlotResponse? bookSlotResponse = await apiService.bookSlot(
        context: currentContext,
        patientId: patientId,
        doctorId: doctorId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime.toString(),
        slotNumber: slotNumber,
        paymentMethod: "wallet",
      );

      // Safely close the loading dialog
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Check if still mounted after API call


      if (bookSlotResponse != null && bookSlotResponse.statusCode == 1) {

        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Appointment Booked!'),
              content: const Text('Your appointment has been booked successfully.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    //It is important to check for Navigator.canPop(context) before calling Navigator.pop(context). This check avoids errors when the navigator is not available or has already been popped.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Close success dialog
                    }



                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => PastAppointmentsScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {

        ScaffoldMessenger.of(currentContext).showSnackBar(  // captured context
          SnackBar(
              content: Text(bookSlotResponse?.statusMessage?.join(', ') ??
                  'Failed to book appointment')),
        );
      }
    } catch (e) {
      // Ensure dialog is closed in case of an error
      if (Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (!mounted) return; // Final safety check

      ScaffoldMessenger.of(currentContext).showSnackBar( // captured context
          SnackBar(content: Text('Error: ${e.toString()}'))); // Show the error
    }
  }


  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(label,
            style: AppStyles.bodyLarge(context)
                .copyWith(color: AppColors.primaryTextColor, fontWeight: FontWeight.bold)),
        Text(value,
            style: AppStyles.bodyMedium(context)
                .copyWith(color: AppColors.secondaryTextColor)),
      ],
    );
  }
}

class ConfirmationDialog extends StatefulWidget {
  final Doctor doctor;
  final DateTime selectedDate;
  final Slot? selectedSlot;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    Key? key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onConfirm,
  }) : super(key: key);

  @override
  ConfirmationDialogState createState() => ConfirmationDialogState();
}

class ConfirmationDialogState extends State<ConfirmationDialog> {


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formattedTimeSlot = 'Not Selected';
    if (widget.selectedSlot != null && widget.selectedSlot!.time != null) {
      try {
        final parsedTime = DateFormat('HH:mm').parse(widget.selectedSlot!.time!);
        formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
      } catch (e) {
        formattedTimeSlot = 'Invalid Time';
        print('Error formatting time: $e');
      }
    }
    final formattedDate = DateFormat('MMM d, yyyy').format(widget.selectedDate);
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
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.onConfirm,
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
  }
}

class PaymentOptionsDialog extends StatefulWidget {
  final Doctor doctor;
  final DateTime selectedDate;
  final Slot? selectedSlot;
  final int walletBalance;
  final VoidCallback onWalletSelected;
  final VoidCallback onBankSelected;

  const PaymentOptionsDialog({
    Key? key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedSlot,
    required this.walletBalance,
    required this.onWalletSelected,
    required this.onBankSelected,
  }) : super(key: key);

  @override
  PaymentOptionsDialogState createState() => PaymentOptionsDialogState();
}

class PaymentOptionsDialogState extends State<PaymentOptionsDialog> {


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final consultationFee = widget.doctor.consultationFee;

    String formattedTimeSlot = 'Not Selected';
    if (widget.selectedSlot != null && widget.selectedSlot!.time != null) {
      try {
        final parsedTime = DateFormat('HH:mm').parse(widget.selectedSlot!.time!);
        formattedTimeSlot = DateFormat('h:mm a').format(parsedTime);
      } catch (e) {
        formattedTimeSlot = 'Invalid Time';
        print('Error formatting time: $e');
      }
    }
    final formattedDate = DateFormat('MMM d, yyyy').format(widget.selectedDate);
    final timeSlotWithValue = '$formattedDate at $formattedTimeSlot';
    final walletBalanceText = 'PKR/- ${widget.walletBalance}';

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: Row(
        children: [
          Icon(Icons.payment, color: AppColors.primaryColor, size: 30),
          const SizedBox(width: 8),
          Text(
            'Choose Payment Option',
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
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have $walletBalanceText in your wallet. Do you want to use it to book this appointment?',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.onWalletSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 2,
          ),
          child: const Text('Wallet'),
        ),
        ElevatedButton(
          onPressed: widget.onBankSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 2,
          ),
          child: const Text('Bank'),
        ),
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
}*/





/*
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
  */
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
  }*//*


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

*/
