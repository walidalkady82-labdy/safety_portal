import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendForecastView extends StatelessWidget {
  // 1. Define the inputs
  final List<double> history;
  final List<double>? forecast;
  final bool isLoading;
  final Color historyColor;
  final Color forecastColor;

  const TrendForecastView({
    super.key,
    required this.history,
    this.forecast,
    this.isLoading = false,
    this.historyColor = Colors.blue,
    this.forecastColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Handle Loading State
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    // 3. Handle Empty State
    if (history.isEmpty || history.every((e) => e == 0)) {
      return const Center(
        child: Text(
          "No Trend Data Available",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          // Historical Data (Solid)
          LineChartBarData(
            spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: historyColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          // AI Forecast Trajectory (Dashed)
          if (forecast != null)
            LineChartBarData(
              spots: forecast!.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: forecastColor,
              dashArray: [8, 4],
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
        ],
        // ... (Grid and Axis styling)
      ),
    );
  }
}