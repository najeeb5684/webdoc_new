
import 'package:Webdoc/screens/payment_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/get_slots_response.dart';
import '../models/specialist_doctors_response.dart';
import '../services/api_service.dart';
import '../utils/global.dart';

class BookSlotScreen extends StatefulWidget {
  final Doctor doctor;

  const BookSlotScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  _BookSlotScreenState createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
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
       // doctorId: "1f86f06e-1a17-48ea-870a-cad92b23c30d",
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
      appBar: AppBar(
        title: const Text('Select Slot'),
        backgroundColor: Global.getColorFromHex(Global.THEME_COLOR_WHITE),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Details Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipOval(  // Clip the image to a circle
                      child: CachedNetworkImage(
                        imageUrl: widget.doctor.imgLink ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2), //Black Color
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error), // Show error icon if loading fails
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medical_services,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              widget.doctor.doctorSpecialties ?? 'Specialist',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monetization_on,
                                    size: 16, color: Colors.black87),
                                const SizedBox(width: 4),
                                const Text(
                                  'Fees:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs.100',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Appointment Dates Section
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

          // Availability Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              _slotAvailabilityText,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),

          // Time Slots Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _slots.isEmpty
                ? Center(child: Text(_slotAvailabilityText))
                : GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Show 3 slots per row
                childAspectRatio: 2, // Adjusted aspect ratio for smaller slots
                crossAxisSpacing: 8, // Reduced spacing
                mainAxisSpacing: 8, // Reduced spacing
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
                      borderRadius: BorderRadius.circular(20), // More rounded corners
                    ),
                    textStyle: const TextStyle(fontSize: 14), // Smaller font size
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
          ),

          // Next Button Section
          Align( // Use Align to center the button
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selectedSlot == null
                    ? null
                    : () {
                  _showConfirmationDialog(context);
                },
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
                child: const Text('Next', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
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
                        fees: fees,
                        couponCode: ""
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
}