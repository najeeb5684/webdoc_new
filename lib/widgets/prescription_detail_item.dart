import 'package:Webdoc/models/prescription_response_new.dart';
import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../models/prescription_response.dart';
import '../screens/prescription_detail_screen.dart';
import '../theme/app_styles.dart';


class PrescriptionDetailItem extends StatelessWidget {
  final ConsultationDetail detail;

  const PrescriptionDetailItem({Key? key, required this.detail}) : super(key: key);

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
            style: AppStyles.titleSmall(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Days: ${detail.days ?? "N/A"}', style: AppStyles.bodyMedium(context).copyWith(color: Colors.black87)),
              Text(
                'Dosage: ${detail.morning ?? "0"}+${detail.day ?? "0"}+${detail.night ?? "0"}',
                style: AppStyles.bodyMedium(context).copyWith(color: Colors.black87),
              ),
            ],
          ),
          if (detail.additionalNotes != null && detail.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes:',
              style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
            ),
            ExpandableText(text: detail.additionalNotes!),
          ],
        ],
      ),
    );
  }
}

/*
class ExpandableText extends StatefulWidget {
  final String text;

  const ExpandableText({Key? key, required this.text}) : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints size) {
        final span = TextSpan(text: widget.text);
        final tp = TextPainter(
          maxLines: 2,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          text: span,
        );
        tp.layout(maxWidth: size.maxWidth);

        final exceeded = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: ConstrainedBox(
                constraints: isExpanded
                    ? const BoxConstraints()
                    : const BoxConstraints(maxHeight: 40),
                child: Text(
                  widget.text,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
            if (exceeded)
              InkWell(
                child: Text(
                  isExpanded ? "Read less" : "Read more",
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
                onTap: () {
                  setState(() => isExpanded = !isExpanded);
                },
              ),
          ],
        );
      },
    );
  }
}*/
