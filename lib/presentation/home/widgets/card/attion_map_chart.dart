import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttentionMapChart extends StatelessWidget {
  // 1. Define Inputs
  final Map<String, double> riskData;
  final bool isLoading;
  final int maxItems; // Allow customizing the "Top X" limit

  const AttentionMapChart({
    super.key,
    required this.riskData,
    this.isLoading = false,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Handle Loading
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    // 3. Process Data (Sort and Limit)
    List<MapEntry<String, double>> entries = riskData.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    if (entries.length > maxItems) {
      entries = entries.sublist(0, maxItems);
    }

    // 4. Handle Empty State
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          "No Risk Data Available",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    // 5. Dynamic Scaling Logic
    double topValue = entries.first.value;
    double maxY = topValue * 1.2;
    if (maxY < 10) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index < 0 || index >= entries.length) return const SizedBox();
                
                String label = entries[index].key;
                // Safely substring the label
                String shortLabel = label.substring(0, math.min(4, label.length));
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((e) {
          final double value = e.value.value;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: value,
                // Color logic based on value input
                color: value > 15 ? Colors.redAccent : Colors.orange,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
}