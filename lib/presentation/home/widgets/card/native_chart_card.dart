import 'dart:math' as math;
import 'package:flutter/material.dart';

class NativeChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<MapEntry<String, double>> data;
  final Color barColor;

  const NativeChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.emptyMessage,
    this.barColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Handle Empty State early
    if (data.isEmpty) {
      return _buildContainer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    // 2. Calculation Logic
    final double maxVal = data.map((e) => e.value).reduce(math.max);
    final double safeMax = maxVal == 0 ? 1.0 : maxVal;

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0), // Spacing handled by _buildContainer
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((e) {
                // Calculate height percentage (max 100 units)
                final double h = (e.value / safeMax) * 100;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      e.value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.bold, 
                        color: barColor
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: h < 5 ? 5 : h, // Minimum height of 5
                      decoration: BoxDecoration(
                        color: barColor, 
                        borderRadius: BorderRadius.circular(4)
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.key.length > 3 ? e.key.substring(0, 3) : e.key,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  // Helper to keep the decoration consistent between empty and data states
  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}