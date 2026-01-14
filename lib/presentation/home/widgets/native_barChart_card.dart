import 'dart:math' as math;
import 'package:flutter/material.dart';

class NativeHorizontalBarChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<MapEntry<String, double>> data;
  final Color barColor;
  final double labelWidth; // Added to allow customization of the left text column

  const NativeHorizontalBarChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.emptyMessage,
    this.barColor = Colors.blue,
    this.labelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Handle Empty State
    if (data.isEmpty) {
      return _buildWrapper(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    // 2. Calculation Logic
    final double maxVal = data.map((e) => e.value).reduce(math.max);
    final double safeMax = maxVal == 0 ? 1.0 : maxVal;

    return _buildWrapper(
      child: Column(
        children: data.map((e) {
          final double wFactor = e.value / safeMax;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Category Label
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    e.key,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Progress Bar Segment
                Expanded(
                  child: Stack(
                    children: [
                      // Background track
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Colored progress
                      FractionallySizedBox(
                        widthFactor: wFactor,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Value Label
                Text(
                  e.value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Shared container to keep UI consistent with your other cards
  Widget _buildWrapper({required Widget child}) {
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