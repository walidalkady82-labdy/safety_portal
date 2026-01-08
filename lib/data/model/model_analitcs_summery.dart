import 'package:safety_portal/data/model/model_department_metric.dart';
import 'package:safety_portal/data/model/model_risk_metric.dart';
import 'package:safety_portal/data/model/model_user_stats.dart';

/// A combined result object to return all analytics in one go
class ModelAnalyticsSummary {
  final List<ModelRiskMetric> areaRisks;
  final List<ModelDepartmentMetric> deptMetrics;
  final List<ModelUserStats> leaderboard;
  final int totalReports;
  final DateTime timestamp;

  ModelAnalyticsSummary({
    required this.areaRisks,
    required this.deptMetrics,
    required this.leaderboard,
    required this.totalReports,
    required this.timestamp,
  });
}