
import 'package:Webdoc/models/prescription_response_new.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/prescription_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class PrescriptionHistoryItem extends StatelessWidget {
  final PrescriptionPayload consultation;

  const PrescriptionHistoryItem({Key? key, required this.consultation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedDate = 'Invalid Date';

    try {
      if (consultation.consultationDate != null) {
        // Define the expected input format
        final inputFormat = DateFormat("dd-MMM-yyyy hh:mm:ss a", 'en_US');
        // Parse the date string into a DateTime object.
        final dateTime = inputFormat.parse(consultation.consultationDate!);

        // Format the DateTime object into the desired output format.
        final outputFormat = DateFormat('dd MMM yyyy hh:mm a');
        formattedDate = outputFormat.format(dateTime);
      }
    } catch (e) {
      print("Error formatting date: $e");
    }

    return Card(
      color: AppColors.primaryColorLight,
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionDetailScreen(consultation: consultation),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                consultation.doctorFirstName ?? 'Unknown Doctor',
                style: AppStyles.bodyLarge(context).copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.healing, size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      consultation.complaint ?? 'No Complaint',
                      style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,  // Use the formattedDate variable
                    style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
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

/*
import 'package:Webdoc/models/prescription_response_new.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prescription_response.dart';
import '../screens/prescription_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class PrescriptionHistoryItem extends StatelessWidget {
  final PrescriptionPayload consultation;

  const PrescriptionHistoryItem({Key? key, required this.consultation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryColorLight,  // Setting background color to white here
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionDetailScreen(consultation: consultation),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                consultation.doctorFirstName ?? 'Unknown Doctor',
                style: AppStyles.bodyLarge(context).copyWith(color: AppColors.primaryColor,fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.healing, size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      consultation.complaint ?? 'No Complaint',
                      style: AppStyles.bodyMedium(context).copyWith(color: AppColors.secondaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 4),
                  Text(
                    consultation.consultationDate != null
                        ? DateFormat('dd MMM yyyy hh:mm a').format(
                        DateFormat('dd MMM yyyy hh:mm:ss a', 'en_US').parse(consultation.consultationDate!))
                        : 'No Date',
                    style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
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
