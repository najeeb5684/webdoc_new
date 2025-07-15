// SuggestedDoctorListItem.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/doctor.dart';
import '../utils/global.dart';

class SuggestedDoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final String doctorStatus; // Add doctorStatus here

  const SuggestedDoctorListItem({
    Key? key,
    required this.doctor,
    required this.onTap,
    required this.doctorStatus, // Receive doctorStatus
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.all(2.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,  // Changed to top right
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: CachedNetworkImageProvider(
                    doctor.imgLink!,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0), // Add some padding
                  child: StatusIndicator(doctorStatus: doctorStatus), // Use the StatusIndicator
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${doctor.firstName} ${doctor.lastName}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final String doctorStatus;

  const StatusIndicator({Key? key, required this.doctorStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (doctorStatus) {
      case 'online':
        statusColor = Colors.green;
        break;
      case 'busy':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}