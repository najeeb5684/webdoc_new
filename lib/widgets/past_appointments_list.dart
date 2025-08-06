
import 'package:Webdoc/screens/specialist_prescription_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import '../models/past_appointment_response.dart';
import '../screens/prescription_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';


class PastAppointmentsList extends StatelessWidget {
  final List<Appointment> appointments;

  const PastAppointmentsList({Key? key, required this.appointments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return appointments.isEmpty
        ? SizedBox(
      height: screenHeight * 0.4, // Take up half the screen (adjust as needed)
      child: const Center(child: NoPastAppointments()), // Center the message
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, context); // Pass context
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, BuildContext context) { // Accept context

    // Determine status-related styles
    Color statusColor = Colors.grey; // Default color
    Color statusBackgroundColor = Colors.grey.shade100;

    if (appointment.status == "Completed") {
      statusColor = AppColors.primaryColor;
      statusBackgroundColor = AppColors.primaryColor.withOpacity(0.1);
    } else {
      statusColor = Colors.red;
      statusBackgroundColor = Colors.red.shade100;
    }

    return Card(
      color: AppColors.primaryColorLight,
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: AppColors.primaryColor.withOpacity(0.1), width: 1.0), // Add border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        appointment.imgLink!,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${appointment.firstName} ${appointment.lastName}',
                            style: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryTextColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: statusBackgroundColor,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              appointment.status ?? '',
                              style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      Text(
                        appointment.specialty!,
                        style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                      ),
                      Row(
                        children: [
                          Text(
                            '4.8',
                            style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                          ),
                          const Icon(Icons.star, color: Colors.yellow, size: 14),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, color: AppColors.secondaryTextColor, size: 16),
                          Text(
                            '${appointment.appointmentDate} ${appointment.appointmentTime}',
                            style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Follow-up Code Section
            if (appointment.followUpCode != null && appointment.followUpCode!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Follow-up Code: ${appointment.followUpCode}",
                        style: AppStyles.bodyMedium(context)
                            .copyWith(color: AppColors.primaryTextColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppColors.primaryColor),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: appointment.followUpCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Follow-up code copied to clipboard')),
                        );
                      },
                      tooltip: "Copy Code",
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            Column( // Arrange buttons vertically
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (appointment.status == "Completed")
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpecialistPrescriptionDetailScreen(consultationId: appointment.consultationId.toString()), // Navigate to prescription screen
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Prescription',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoPastAppointments extends StatelessWidget {
  const NoPastAppointments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_appointments.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            "No past appointments found.",
            style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}


/*

import 'package:Webdoc/screens/specialist_prescription_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/past_appointment_response.dart';
import '../screens/prescription_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';


class PastAppointmentsList extends StatelessWidget {
  final List<Appointment> appointments;

  const PastAppointmentsList({Key? key, required this.appointments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return appointments.isEmpty
        ? SizedBox(
      height: screenHeight * 0.4, // Take up half the screen (adjust as needed)
      child: const Center(child: NoPastAppointments()), // Center the message
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, context); // Pass context
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, BuildContext context) { // Accept context
    //final appointmentDateTime = DateFormat('dd-MMM-yyyy hh:mm a').parse('${appointment.appointmentDate} ${appointment.appointmentTime}');
    //final formattedDate = DateFormat('d MMM').format(appointmentDateTime);

    // Determine status-related styles
    Color statusColor = Colors.grey; // Default color
    Color statusBackgroundColor = Colors.grey.shade100;

    if (appointment.status == "Completed") {
      statusColor = AppColors.primaryColor;
      statusBackgroundColor = AppColors.primaryColor.withOpacity(0.1);
    } else {
      statusColor = Colors.red;
      statusBackgroundColor = Colors.red.shade100;
    }

    return Card(
      color: AppColors.primaryColorLight,
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: AppColors.primaryColor.withOpacity(0.1), width: 1.0), // Add border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        appointment.imgLink!,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${appointment.firstName} ${appointment.lastName}',
                            style: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryTextColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: statusBackgroundColor,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              appointment.status ?? '',
                              style: AppStyles.bodySmall(context).copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      Text(
                        appointment.specialty!,
                        style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                      ),
                      Row(
                        children: [
                          Text(
                            '4.8',
                            style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                          ),
                          const Icon(Icons.star, color: Colors.yellow, size: 14),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, color: AppColors.secondaryTextColor, size: 16),
                          Text(
                            '${appointment.appointmentDate} ${appointment.appointmentTime}',
                            style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column( // Arrange buttons vertically
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (appointment.status == "Completed")
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpecialistPrescriptionDetailScreen(consultationId: appointment.consultationId.toString()), // Navigate to prescription screen
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Prescription',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
               // else
                */
/*  ElevatedButton(
                    onPressed: () {
                      print("Reschedule appointment ${appointment.id}");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),*//*

               */
/* const SizedBox(height: 8), // Spacing between buttons
                ElevatedButton(
                  onPressed: () {
                    print("Complain about appointment ${appointment.id}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text(
                    'Complaint',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),*//*

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoPastAppointments extends StatelessWidget {
  const NoPastAppointments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_appointments.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            "No past appointments found.",
            style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}



*/
