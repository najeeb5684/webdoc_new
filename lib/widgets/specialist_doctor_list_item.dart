

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/specialist_doctors_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';

class SpecialistDoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onConsultPressed;
  final VoidCallback onItemTap;

  const SpecialistDoctorListItem({
    Key? key,
    required this.doctor,
    required this.onConsultPressed,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (doctor.onlineDoctor.toString().toLowerCase()) {
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Card(
          color: AppColors.primaryColorLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                        /*  Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                        ),*/
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
                          SizedBox(height: 5),
                          Text(
                            doctor.doctorSpecialties ?? 'Specialty N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 5),
                          Row( // This Row now contains both duty time and rating
                            children: [
                              if (doctor.doctorDutyTime != null)
                                Row(
                                  children: [
                                    Text('${"5" ?? 5}', style: AppStyles.bodyMedium(context).copyWith(color: Colors.grey)),
                                    const Icon(Icons.star, color: Colors.yellow, size: 16),
                                  ],
                                ),
                              const Icon(Icons.access_time, color: Colors.grey, size: 16), // Add the icon here
                              const SizedBox(width: 2), // Add some spacing between the icon and the text
                              Expanded( // Wrap the Text widget in an Expanded widget
                                child: Text(
                                  '${doctor.doctorDutyTime}', // Display duty time
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Added to handle overflow
                                  maxLines: 1, // Limit to one line
                                ),
                              ),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(

                    onPressed: onConsultPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child:  Text('Book Appointment', style: AppStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold, color: Colors.white),),
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


/*import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/specialist_doctors_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';

class SpecialistDoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onConsultPressed;
  final VoidCallback onItemTap;

  const SpecialistDoctorListItem({
    Key? key,
    required this.doctor,
    required this.onConsultPressed,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (doctor.onlineDoctor.toString().toLowerCase()) {
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColorLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Card(
          color: AppColors.primaryColorLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                      *//*  Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                        ),*//*
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${doctor.firstName} ${doctor.lastName}',
                            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                           SizedBox(height: 5),
                          Text(
                            doctor.doctorSpecialties ?? 'Specialty N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                           SizedBox(height: 5),
                          Row( // This Row now contains both duty time and rating
                            children: [
                              if (doctor.doctorDutyTime != null)
                                Row(
                                  children: [
                                    Text('${"5" ?? 5}', style: AppStyles.bodyMedium.copyWith(color: Colors.grey)),
                                    const Icon(Icons.star, color: Colors.yellow, size: 16),
                                  ],
                                ),
                              const Icon(Icons.access_time, color: Colors.grey, size: 16), // Add the icon here
                              const SizedBox(width: 2), // Add some spacing between the icon and the text
                                Text(
                                  '${doctor.doctorDutyTime}', // Display duty time
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(

                    onPressed: onConsultPressed,
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/

/*import 'package:Webdoc/models/specialist_doctors_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SpecialistDoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onConsultPressed;
  final VoidCallback onItemTap;

  const SpecialistDoctorListItem({
    Key? key,
    required this.doctor,
    required this.onConsultPressed,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onItemTap,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
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
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${doctor.firstName ?? ''} ${doctor.lastName ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.doctorSpecialties ?? 'Specialty N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                child: const Text(
                  'Book',
                  style: TextStyle(
                    color: Colors.black, // Text color white
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
