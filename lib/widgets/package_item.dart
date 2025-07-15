// lib/widgets/package_item_widget.dart

import 'package:flutter/material.dart';
import '../models/package_response.dart'; // <-- Use the combined models file

class PackageItemWidget extends StatelessWidget {
  const PackageItemWidget({
    Key? key,
    required this.package,
    required this.onBuyPressed,
  }) : super(key: key);

  final Package package;
  final VoidCallback onBuyPressed; // Callback function for the button press

  @override
  Widget build(BuildContext context) {
    // More Compact and Prominent Black and White Package Item Design
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Standard margin
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(25.0), // Even more prominent rounded corners
        boxShadow: [ // More prominent black shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // Increased opacity
            spreadRadius: 2,
            blurRadius: 15, // Increased blur
            offset: const Offset(0, 8), // More prominent vertical offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Reduced padding inside
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            // Package Name & Company Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 20, // Reduced name font size slightly
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${package.company}',
                  style: TextStyle(
                    fontSize: 14, // Reduced company font size slightly
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const Divider(
              height: 24, // Reduced height
              thickness: 1,
              color: Colors.black12,
            ),

            // Details Section (Price and Duration)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price Row with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min, // Use minimum space
                      children: [
                        Icon(Icons.local_offer_outlined, color: Colors.black54, size: 18), // Smaller icon
                        const SizedBox(width: 6), // Reduced space
                        const Text(
                          'Price:',
                          style: TextStyle(
                            fontSize: 15, // Reduced label font size
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rs.${package.price}', // <-- Changed from '$' to 'Rs '
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Reduced space between rows

                // Duration Row with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min, // Use minimum space
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.black54, size: 18), // Smaller icon
                        const SizedBox(width: 6), // Reduced space
                        const Text(
                          'Duration:',
                          style: TextStyle(
                            fontSize: 15, // Reduced label font size
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      package.duration,
                      style: const TextStyle(
                        fontSize: 15, // Reduced duration font size
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Optional Image Placeholder (ensure this is handled outside or kept minimal if active)
            // TODO: Optionally display image if available
            // if (package.img != null && package.img!.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 16.0), // Reduced space above image
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(10.0),
            //       child: Image.network(
            //         package.img!,
            //         height: 100, // Reduced image height
            //         width: double.infinity,
            //         fit: BoxFit.cover,
            //         errorBuilder: (context, error, stackTrace) => Container(
            //           height: 100, // Reduced placeholder height
            //           color: Colors.grey[200],
            //           child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 30), // Smaller icon
            //         ),
            //       ),
            //     ),
            //   ),

            const SizedBox(height: 24), // Increased space before the full-width button

            // Buy Button (Full Width)
            SizedBox( // Wrap in SizedBox to ensure it takes full width
              width: double.infinity, // Make the button fill the width
              child: ElevatedButton(
                onPressed: onBuyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Black button background
                  foregroundColor: Colors.white, // White button text
                  padding: const EdgeInsets.symmetric(vertical: 14), // Only vertical padding; horizontal space comes from the parent Container's padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Slightly more rounded button corners
                  ),
                  elevation: 3.0, // Subtle button shadow
                ),
                child: const Text(
                  'Buy Now', // Use 'Buy Now' or 'Buy' as preferred
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // Slightly larger, semi-bold text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
