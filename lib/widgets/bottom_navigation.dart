import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int appointmentCount; // Add this line

  const BottomNavigation({Key? key, required this.selectedIndex, required this.onItemTapped, this.appointmentCount = 0}) : super(key: key); // Initialize with default value

  @override
  Widget build(BuildContext context) {
    return Container(  // Wrap with Container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGreyStroke, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 60.0,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, 'assets/images/home.png', showBadge: false),
                _buildNavItem(context, 1, 'assets/images/prescription.png', showBadge: false),
                _buildNavItem(context, 2, 'assets/images/appointment.png', showBadge: appointmentCount > 0, badgeCount: appointmentCount), // Pass badge info
                _buildNavItem(context, 3, 'assets/images/account.png', showBadge: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath, {bool showBadge = false, int badgeCount = 0}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: Stack(  // Use Stack to overlay the badge
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
                color: isSelected ? Colors.white : AppColors.iconColor,
              ),
            ),
          ),
          if (showBadge)  // Conditionally render the badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// BottomNavigation.dart
/*import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigation({Key? key, required this.selectedIndex, required this.onItemTapped}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(  // Wrap with Container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGreyStroke, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 60.0,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, 'assets/images/home.png'),
                _buildNavItem(context, 1, 'assets/images/prescription.png'),
                _buildNavItem(context, 2, 'assets/images/account.png'),
                _buildNavItem(context, 3, 'assets/images/appointment.png'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: isSelected ? Colors.white : AppColors.iconColor,
          ),
        ),
      ),
    );
  }
}*/






/*import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigation({Key? key, required this.selectedIndex, required this.onItemTapped}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth * 0.8;

    return Container(
      width: navWidth,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.lightGreyStroke, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, 'assets/images/home.png'),
          _buildNavItem(context, 1, 'assets/images/prescription.png'),
          _buildNavItem(context, 2, 'assets/images/account.png'),
          _buildNavItem(context, 3, 'assets/images/appointment_bottom.png'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: isSelected ? Colors.white : AppColors.iconColor,
          ),
        ),
      ),
    );
  }
}*/


/*
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigation({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.white,
      color: Colors.black,
      height: 70, // Adjusted for text visibility
      index: selectedIndex,
      items: [
        _buildNavItem(Icons.home, "Home", 0),
        _buildNavItem(Icons.medical_information, "Prescription", 1),
        _buildNavItem(Icons.person, "Account", 2),
      ],
      onTap: onItemTapped,
    );
  }

  /// Builds an icon with a label that hides when selected
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 30, color: Colors.white),
        if (!isSelected) // Show text only when unselected
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
      ],
    );
  }
}
*/
