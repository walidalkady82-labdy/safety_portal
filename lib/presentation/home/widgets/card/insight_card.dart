import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final double? width; // Added for flexible layout control

  const InsightCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Uses the provided color with very low opacity for a modern "tint"
        color: color.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevents card from taking unnecessary height
        children: [
          Text(
            title.toUpperCase(), // Often looks better for small labels
            style: TextStyle(
              fontSize: 10, 
              letterSpacing: 0.5,
              fontWeight: FontWeight.bold, 
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}