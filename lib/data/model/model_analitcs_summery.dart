import 'package:safety_portal/data/model/model_department_metric.dart';
import 'package:safety_portal/data/model/model_risk_metric.dart';
import 'package:safety_portal/data/model/model_user_stats.dart';

/// A combined result object to return all analytics in one go
class ModelAnalyticsSummary {
  final double plantSafetyScore;
  final int totalOpenRisks;
  final int mitigatedRisks;
  final int criticalCount;
  final Map<String, int> topRisks;
  final Map<String, int> dailyVolume;
  final List<ModelRiskMetric> areaRisks;
  final List<ModelDepartmentMetric> deptMetrics;
  final List<ModelUserStats> leaderboard;
  final int totalReports;
  final DateTime timestamp;

  ModelAnalyticsSummary({
    required this.plantSafetyScore,
    required this.totalOpenRisks,
    required this.mitigatedRisks,
    required this.criticalCount,
    required this.dailyVolume,
    required this.topRisks,
    required this.areaRisks,
    required this.deptMetrics,
    required this.leaderboard,
    required this.totalReports,
    required this.timestamp,
  });
  static ModelAnalyticsSummary empty() => ModelAnalyticsSummary(
    plantSafetyScore: 0.0,
    totalOpenRisks: 0,
    mitigatedRisks: 0,
    criticalCount: 0,
    dailyVolume: {},
    topRisks: {},
    areaRisks: [],
    deptMetrics: [],
    leaderboard: [],
    totalReports: 0,
    timestamp: DateTime.now(),
  );
}