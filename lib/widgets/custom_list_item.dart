import 'package:flutter/material.dart';

class CustomListItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const CustomListItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.blueGrey),
              const SizedBox(width: 16),
              Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}