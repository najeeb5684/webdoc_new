import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../models/specialist_prescription_response.dart';  // Correct import!
import '../screens/specialist_prescription_detail_screen.dart';
import '../theme/app_styles.dart';


class SpecialistPrescriptionItem extends StatelessWidget {
  final Consultationdetail detail;

  const SpecialistPrescriptionItem({Key? key, required this.detail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColorLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.medicineName ?? "N/A",
            style: AppStyles.titleSmall(context).copyWith(
                fontWeight: FontWeight.bold, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Days: ${detail.noOfDays ?? "N/A"}',
                  style: AppStyles.bodyMedium(context)
                      .copyWith(color: Colors.black87)),
              Text(
                'Dosage: ${detail.morning ?? "0"}+${detail.day ?? "0"}+${detail.night ?? "0"}',
                style: AppStyles.bodyMedium(context)
                    .copyWith(color: Colors.black87),
              ),
            ],
          ),
          if (detail.additionalNotes != null &&
              detail.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes:',
              style: AppStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            ExpandableText(text: detail.additionalNotes!),
          ],
        ],
      ),
    );
  }
}