import 'package:flutter/material.dart';

class RiskCard extends StatelessWidget {
  final String area;
  final double score;
  final double maxScore; // Added to make the progress bar flexible
  final VoidCallback? onTap;

  const RiskCard({
    super.key,
    required this.area,
    required this.score,
    this.maxScore = 20.0,
    this.onTap,
  });

  // Helper to determine color based on score
  Color _getScoreColor(double value) {
    if (value > 12) return Colors.red;
    if (value > 6) return Colors.orange;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getScoreColor(score);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Set a fixed height if used in a horizontal list, 
        // or let the parent define constraints
        constraints: const BoxConstraints(minHeight: 100, maxHeight: 120),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar, size: 14, color: Colors.grey),
                const Spacer(),
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              area.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / maxScore).clamp(0.0, 1.0),
                color: statusColor,
                backgroundColor: Colors.grey.shade50,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}