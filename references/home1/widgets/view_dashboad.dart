import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/model/model_analitcs_summery.dart';

class ViewDashboard extends StatelessWidget {
  final ModelAnalyticsSummary? summary;

  const ViewDashboard({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: Text("No Data Available"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Stats
          _buildSummaryCard(summary!),
          const SizedBox(height: 24),

          // 2. Risk Chart
          const Text("Risk by Area", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: summary!.areaRisks.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalRiskScore,
                        color: _getRiskColor(e.value.totalRiskScore),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() < summary!.areaRisks.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              summary!.areaRisks[val.toInt()].area.substring(0, 3), // Truncate
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 3. Department Efficiency
          const Text("Department Response", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...summary!.deptMetrics.map((dept) => ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.2),
              child: Text("${dept.efficiency.toInt()}%", style: const TextStyle(fontSize: 12)),
            ),
            title: Text(dept.name),
            subtitle: LinearProgressIndicator(
              value: dept.efficiency / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            trailing: Text("${dept.closed}/${dept.closed + dept.pending}"),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ModelAnalyticsSummary data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Reports", style: TextStyle(color: Colors.white70)),
              Text("${data.totalReports}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.analytics_outlined, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Color _getRiskColor(double score) {
    if (score > 50) return Colors.red;
    if (score > 20) return Colors.orange;
    return Colors.green;
  }
}