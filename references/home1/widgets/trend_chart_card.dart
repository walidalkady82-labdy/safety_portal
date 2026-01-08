import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/data/service/service_analytics.dart';
import 'package:safety_portal/locator.dart';

class TrendChartCard extends StatelessWidget {
  final analytics  = sl<ServiceAnalytics>();
  final String areaName;
  final List<double> history;
  final double prediction;

  TrendChartCard({super.key,required this.areaName,required this.history,required this.prediction});

@override
  Widget build(BuildContext context) {
    // Determine trend color (Red if rising, Green if falling)
    double lastReal = history.last;
    bool isRising = prediction > lastReal;
    Color trendColor = isRising ? Colors.red : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(areaName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isRising ? "Risk Rising 📈" : "Stable 📉",
                    style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // The Chart
            AspectRatio(
              aspectRatio: 1.70,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitleWidgets)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // 1. HISTORY LINE (Solid Blue)
                    LineChartBarData(
                      spots: _getHistorySpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                    ),
                    // 2. PREDICTION LINE (Dotted Red/Green)
                    LineChartBarData(
                      spots: _getPredictionSpots(),
                      isCurved: true,
                      color: trendColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dashArray: [5, 5], // <--- MAKES IT DOTTED
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate spots for Weeks 0, 1, 2, 3
  List<FlSpot> _getHistorySpots() {
    return List.generate(history.length, (index) {
      return FlSpot(index.toDouble(), history[index]);
    });
  }

  // Generate connection from Week 3 (Last Real) to Week 4 (Prediction)
  List<FlSpot> _getPredictionSpots() {
    return [
      FlSpot(3, history.last),      // Start where history ended
      FlSpot(4, prediction),        // End at the AI prediction
    ];
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Week 1'; break;
      case 1: text = 'Week 2'; break;
      case 2: text = 'Week 3'; break;
      case 3: text = 'Last Week'; break;
      case 4: text = 'NEXT WEEK'; break; // Highlight this
      default: return Container();
    }
    return SideTitleWidget(
      meta: TitleMeta(
        min: 0,                        // The minimum value of the axis
        max: 10,                       // The maximum value of the axis
        parentAxisSize: 100,            // The available size (width/height) for the axis
        axisPosition: 0,               // The position of this specific title on the axis
        appliedInterval: 1,            // The interval between titles
        sideTitles: const SideTitles(),// The configuration of the side titles
        formattedValue: 'Label',       // The string representation of the value
        axisSide: AxisSide.bottom,     // The side of the chart (left, right, top, bottom)
        rotationQuarterTurns: 3
      ),
    child: Text(text, style: style));
  }
}