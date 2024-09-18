import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String label;
  final String image;
  final VoidCallback onTap;
  final bool isSelected; // Add isSelected parameter

  const CategoryItem({
    super.key,
    required this.label,
    required this.image,
    required this.onTap,
    required this.isSelected, // Initialize the new parameter
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [Colors.blue, Colors.purple, Colors.pink]
                : [Colors.grey, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            width: 2.0,
            color: Colors.transparent,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -10.0, // Adjust to control how much of the image is outside
              bottom: 8.0, // Adjust as needed
              child: Image.asset(
                image,
                width: 60.0, // Adjust the width as needed
                height: 60,
                fit: BoxFit.contain, // Ensure the image fits within the provided space
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 60.0), // Adjust this value to align text with image
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
