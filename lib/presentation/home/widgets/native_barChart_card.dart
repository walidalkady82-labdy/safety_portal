import 'dart:math' as math;

import 'package:flutter/material.dart';

class NativeBarChartCard extends StatelessWidget {
  final String title, subtitle;
  final List<MapEntry<String, double>> data;

  const NativeBarChartCard({
    super.key, 
    required this.title, 
    required this.subtitle,
    required this.data
  });

  @override
  Widget build(BuildContext context) {
    final double maxVal = data.isEmpty ? 1 : data.map((e) => e.value).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          ...data.map((e) {
            final double wFactor = e.value / maxVal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(
                          widthFactor: wFactor,
                          child: Container(height: 8, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4))),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value.toInt().toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}
