import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class RiskMetric {
  final String area;
  final int reportCount;
  final double totalRiskScore;
  final double avgSeverity;

  RiskMetric({
    required this.area,
    required this.reportCount,
    required this.totalRiskScore,
    required this.avgSeverity,
  });
}

class DashboardService {
  // Weights matching your Python script
  final Map<String, int> levelWeights = {
    'low': 1,
    'medium': 3,
    'high': 5,
  };

  final Map<String, int> typeWeights = {
    'unsafe_condition': 1,
    'unsafe_behavior': 2,
    'nm': 5, // Near Miss
    'fa': 10, // First Aid
  };

  Future<List<RiskMetric>> calculateAreaRisks() async {
    final snapshot = await FirebaseDatabase.instance.ref('atr').get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    Map<String, List<double>> areaScores = {};

    data.forEach((key, value) {
      String area = value['area'] ?? 'Unknown';
      String level = (value['level'] ?? 'low').toString().toLowerCase().trim();
      String type = (value['type'] ?? 'unsafe_condition').toString().toLowerCase().trim();

      // Calculate score for this specific report
      int lWeight = levelWeights[level] ?? 1;
      int tWeight = typeWeights[type] ?? 1;
      double reportRisk = (lWeight * tWeight).toDouble();

      if (!areaScores.containsKey(area)) {
        areaScores[area] = [];
      }
      areaScores[area]!.add(reportRisk);
    });

    // Convert grouped data into RiskMetric objects
    List<RiskMetric> metrics = [];
    areaScores.forEach((area, scores) {
      double total = scores.reduce((a, b) => a + b);
      metrics.add(RiskMetric(
        area: area,
        reportCount: scores.length,
        totalRiskScore: total,
        avgSeverity: total / scores.length,
      ));
    });

    // Sort by total risk (highest first)
    metrics.sort((a, b) => b.totalRiskScore.compareTo(a.totalRiskScore));
    return metrics;
  }
}