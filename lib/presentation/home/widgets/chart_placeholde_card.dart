import 'package:flutter/material.dart';

class ChartPlaceholderCard extends StatelessWidget {
  final String title, subtitle;
  final double height;
  const ChartPlaceholderCard(
      {super.key, required this.title, required this.subtitle, this.height = 250});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(Icons.auto_graph_rounded, size: 48, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                const Text('AI Visualization Engine Active', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
