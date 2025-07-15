
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/doctor.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';

class DoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onConsultPressed;
  final bool isPackageActivated;
  final VoidCallback onItemTap;

  const DoctorListItem({
    Key? key,
    required this.doctor,
    required this.onConsultPressed,
    required this.isPackageActivated,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (doctor.isOnline?.toLowerCase()) {
      case 'online':
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusIcon = Icons.circle;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.circle;
    }

    return GestureDetector(
      onTap: onItemTap,
      child: Container( // Added Container for border
        decoration: BoxDecoration( // Box decoration for border
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2), // Stroke color
            width: 1, // Stroke width
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Card(
          color: AppColors.primaryColorLight, // Use a light color for the card
          elevation: 0, // Remove default shadow to prevent overlapping
          margin: EdgeInsets.zero, // Remove default Card margin

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: doctor.imgLink ??
                                  'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Global.getColorFromHex(Global.THEME_COLOR_CODE)),
                                  )),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${doctor.firstName} ${doctor.lastName}',
                            style: AppStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          Text('${doctor.doctorSpecialty ?? 'Medical Officer'}', style: AppStyles.bodyMedium(context).copyWith(color: Colors.grey)),

                          Row(
                            children: [
                              Text('${doctor.rate ?? 4.8}', style: AppStyles.bodyMedium(context).copyWith(color: Colors.grey)),
                              const Icon(Icons.star, color: Colors.yellow, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.call_outlined, color: Colors.white),
                    label: Text(isPackageActivated ? 'Call Now' : 'Subscribe', style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold, color: Colors.white),),
                    onPressed: onConsultPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image
import '../models/doctor.dart';
import '../utils/global.dart';

class DoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onConsultPressed;
  final bool isPackageActivated;
  final VoidCallback onItemTap;  // Add this

  const DoctorListItem({
    Key? key,
    required this.doctor,
    required this.onConsultPressed,
    required this.isPackageActivated,
    required this.onItemTap, // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (doctor.isOnline?.toLowerCase()) {
      case 'online':
        statusColor = Colors.green;
        statusIcon = Icons.online_prediction;
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.offline_bolt;
    }

    return GestureDetector( // Wrap the entire card with GestureDetector
      onTap: onItemTap,  // Assign onItemTap callback
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.all(8.0),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: ClipOval(
                  // To make sure CachedNetworkImage respects the CircleAvatar's shape
                  child: CachedNetworkImage(
                    imageUrl: doctor.imgLink ??
                        'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                    fit: BoxFit.cover,
                    width: 60, // Match CircleAvatar's diameter (radius * 2)
                    height: 60, // Match CircleAvatar's diameter (radius * 2)
                    placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          // Added color here
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Global.getColorFromHex(Global.THEME_COLOR_CODE)),
                        )),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${doctor.firstName} ${doctor.lastName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black // added
                      ),
                    ),
                    Text(doctor.doctorSpecialty ?? 'Specialty N/A'),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          doctor.isOnline?.toUpperCase() ?? 'OFFLINE',
                          style: TextStyle(color: statusColor),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Rating: ${doctor.rate ?? 0.0}'),
                        const Icon(Icons.star, color: Colors.orangeAccent),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onConsultPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 3, // <-- add elevation here
                  backgroundColor: Colors.white, // Button color black
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                    isPackageActivated ? 'Consult' : 'Subscribe',
                  style: TextStyle(
                  color: Colors.black, // Text color white
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),),
                // Modify this line
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
