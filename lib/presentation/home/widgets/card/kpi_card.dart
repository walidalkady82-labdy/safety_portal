import 'package:flutter/material.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtext;
  final bool trendUp;
  final bool isAlert;
  final VoidCallback? onTap;
  final double width; // Added to make it flexible for different layouts

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtext,
    this.trendUp = true,
    this.isAlert = false,
    this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, // Background color goes here for InkWell to work
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink( // Use Ink for decorations to allow ripples to show over it
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAlert ? color.withOpacity(0.5) : Colors.grey.shade200,
              width: isAlert ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Wrap content height
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildValue(),
              const SizedBox(height: 8),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods to keep the build method clean
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(icon, color: color, size: 20),
      ],
    );
  }

  Widget _buildValue() {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          isAlert ? Icons.warning_amber_rounded : Icons.info_outline,
          size: 14,
          color: isAlert ? color : Colors.grey,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isAlert ? color : Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}