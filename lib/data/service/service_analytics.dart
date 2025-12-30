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
  final Map<String, int> levelWeights = {
    'low': 1,
    'medium': 3,
    'high': 5,
  };

  final Map<String, int> typeWeights = {
    'unsafe_condition': 1,
    'unsafe_behavior': 2,
    'nm': 5,
    'fa': 10,
  };

  /// [Recommended] Live Stream of Analytics
  /// Use this with a StreamBuilder in your UI for real-time updates.
  Stream<List<RiskMetric>> get analyticsStream {
    return FirebaseDatabase.instance.ref('atr').onValue.map((event) {
      return _processSnapshot(event.snapshot);
    });
  }

  /// [Legacy] One-time Fetch
  /// Useful for explicit "Refresh" buttons.
  Future<List<RiskMetric>> calculateAreaRisks() async {
    try {
      print("📊 [Analytics] Fetching data once...");
      final snapshot = await FirebaseDatabase.instance.ref('atr').get();
      return _processSnapshot(snapshot);
    } catch (e) {
      print("❌ [Analytics] Error calculating risks: $e");
      return [];
    }
  }

  /// Shared Logic to process raw Firebase data into Metrics
  List<RiskMetric> _processSnapshot(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) {
      print("⚠️ [Analytics] Data is empty.");
      return [];
    }

    // 1. Robust Parsing (Handles both List and Map formats from Firebase)
    Map<dynamic, dynamic> data = {};
    final rawValue = snapshot.value;

    if (rawValue is Map) {
      data = rawValue;
    } else if (rawValue is List) {
      for (int i = 0; i < rawValue.length; i++) {
        if (rawValue[i] != null) {
          data[i.toString()] = rawValue[i];
        }
      }
    } else {
      return [];
    }

    // 2. Calculate Risk Scores
    Map<String, List<double>> areaScores = {};

    data.forEach((key, value) {
      if (value is! Map && value is! Map<Object?, Object?>) return;

      final record = value as Map;
      String area = (record['area'] ?? 'Unknown').toString();
      String level = (record['level'] ?? 'low').toString().toLowerCase().trim();
      String type = (record['type'] ?? 'unsafe_condition').toString().toLowerCase().trim();

      int lWeight = levelWeights[level] ?? 1;
      int tWeight = typeWeights[type] ?? 1;
      double reportRisk = (lWeight * tWeight).toDouble();

      if (!areaScores.containsKey(area)) {
        areaScores[area] = [];
      }
      areaScores[area]!.add(reportRisk);
    });

    // 3. Create Metric Objects
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

    // 4. Sort by Highest Risk
    metrics.sort((a, b) => b.totalRiskScore.compareTo(a.totalRiskScore));
    
    print("✅ [Analytics] Processed ${metrics.length} areas from live data.");
    return metrics;
  }
}