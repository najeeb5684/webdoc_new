// lib/widgets/payment_method_tile.dart

import 'package:flutter/material.dart';

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    Key? key,
    required this.leadingWidget, // This is the Widget (Image.asset or Icon)
    required this.title,
    required this.onTap,
  }) : super(key: key);

  final Widget leadingWidget;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Fixed size for the leading icon/image container to ensure text alignment
    const double leadingWidgetSize = 40.0; // Consistent size for the icon area

    return InkWell( // Use InkWell for tap effect
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.0), // Match container's border radius
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0), // Slightly reduced vertical margin between tiles
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding inside the tile
        decoration: BoxDecoration(
          color: Colors.white, // White background
          borderRadius: BorderRadius.circular(15.0), // More rounded corners
          // Removed border line as requested
          boxShadow: [ // Enhanced black shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Subtle black shadow with transparency
              spreadRadius: 0, // No spread
              blurRadius: 8, // Increased blur
              offset: const Offset(0, 4), // More prominent vertical offset
            ),
          ],
        ),
        child: Row(
          children: [
            // Fixed-size container for the leading widget
            SizedBox(
              width: leadingWidgetSize,
              height: leadingWidgetSize,
              child: Center( // Center the actual image/icon within the box
                child: leadingWidget,
              ),
            ),
            const SizedBox(width: 16), // Consistent space between icon area and text
            Expanded( // Use Expanded to prevent text overflow
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16, // Slightly smaller text font
                  fontWeight: FontWeight.w500, // Medium font weight
                  color: Colors.black87, // Slight grey tint
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16), // Slightly smaller arrow icon
          ],
        ),
      ),
    );
  }
}