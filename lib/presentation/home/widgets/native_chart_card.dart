import 'dart:math' as math;

import 'package:flutter/material.dart';

class NativeChartCard extends StatelessWidget {
  final String title, subtitle;
  final List<MapEntry<String, double>> data;

  const NativeChartCard({
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
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.isEmpty 
              ? [const Center(child: Text("No Data", style: TextStyle(color: Colors.grey)))]
              : data.map((e) {
                final double h = (e.value / maxVal) * 120;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(e.value.toInt().toString(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 20,
                      height: h < 5 ? 5 : h,
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 8),
                    Text(e.key, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
