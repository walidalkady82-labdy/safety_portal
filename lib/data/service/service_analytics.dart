import 'package:firebase_database/firebase_database.dart';

import '../model/model_analitcs_summery.dart';
import '../model/model_department_metric.dart';
import '../model/model_risk_metric.dart';
import '../model/model_user_stats.dart';

class ServiceAnalytics {
  // Weights matching the training logic
  final Map<String, int> levelWeights = {'low': 1, 'medium': 3, 'high': 5};
  final Map<String, int> typeWeights = {
    'unsafe_condition': 1,
    'unsafe_behavior': 2,
    'nm': 5,
    'fa': 10
  };

  // Simple In-Memory Cache
  ModelAnalyticsSummary? _cachedSummary;
  DateTime? _lastFetch;
  final Duration _cacheDuration = const Duration(minutes: 5);
  
  Future<ModelAnalyticsSummary> getUnifiedAnalytics({int? limit}) async {
    if (_cachedSummary != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedSummary!;
    }

    final rawData = await _fetchRawData(limit);
    if (rawData.isEmpty) return _emptySummary();

    _cachedSummary = _processRawData(rawData);
    _lastFetch = DateTime.now();
    return _cachedSummary!;
  }

  Future<List<ModelRiskMetric>> getAreaRiskMetrics({int? limit}) async {
    final rawData = await _fetchRawData(limit);
    if (rawData.isEmpty) return [];
    return _processAreaRisks(rawData);
  }

  Future<List<ModelDepartmentMetric>> getDepartmentMetrics(
      {int? limit}) async {
    final rawData = await _fetchRawData(limit);
    if (rawData.isEmpty) return [];
    return _processDepartmentMetrics(rawData);
  }

  Future<List<ModelUserStats>> getLeaderboard({int? limit, int count = 10}) async {
    final rawData = await _fetchRawData(limit);
    if (rawData.isEmpty) return [];
    return _processLeaderboard(rawData, count: count);
  }

  ModelAnalyticsSummary _processRawData(Map<dynamic, dynamic> rawData) {
    final areaRisks = _processAreaRisks(rawData);
    final deptMetrics = _processDepartmentMetrics(rawData);
    final leaderboard = _processLeaderboard(rawData);

    return ModelAnalyticsSummary(
      areaRisks: areaRisks,
      deptMetrics: deptMetrics,
      leaderboard: leaderboard,
      totalReports: rawData.length,
      timestamp: DateTime.now(),
    );
  }

  List<ModelRiskMetric> _processAreaRisks(Map<dynamic, dynamic> rawData) {
    Map<String, _AreaAggregator> areas = {};

    rawData.forEach((key, value) {
      if (value == null || value is! Map) return;
      final r = value;
      String area = (r['area'] ?? 'Unknown').toString();
      double score = _calculateScore(r);
      if (!areas.containsKey(area)) areas[area] = _AreaAggregator();
      areas[area]!.add(score);
    });

    List<ModelRiskMetric> areaRisks = [];
    areas.forEach((k, v) {
      areaRisks.add(ModelRiskMetric(
        area: k,
        reportCount: v.count,
        totalRiskScore: v.totalRisk,
        avgSeverity: v.count == 0 ? 0 : v.totalRisk / v.count,
      ));
    });

    areaRisks.sort((a, b) => b.totalRiskScore.compareTo(a.totalRiskScore));
    return areaRisks;
  }

  List<ModelDepartmentMetric> _processDepartmentMetrics(
      Map<dynamic, dynamic> rawData) {
    Map<String, _TeamAggregator> teams = {};

    rawData.forEach((key, value) {
      if (value == null || value is! Map) return;
      final r = value;
      String dept = (r['respDepartment'] ?? 'Unassigned').toString();
      String status = (r['status'] ?? 'pending').toString().toLowerCase();
      double score = _calculateScore(r);
      if (!teams.containsKey(dept)) teams[dept] = _TeamAggregator();
      teams[dept]!.add(status == 'closed', score);
    });

    List<ModelDepartmentMetric> deptMetrics = [];
    teams.forEach((k, v) {
      deptMetrics.add(ModelDepartmentMetric(
        name: k,
        pending: v.pending,
        closed: v.closed,
        totalRisk: v.totalRisk,
      ));
    });

    return deptMetrics;
  }

  List<ModelUserStats> _processLeaderboard(Map<dynamic, dynamic> rawData, {int count = 10}) {
    Map<String, int> userCounts = {};

    rawData.forEach((key, value) {
      if (value == null || value is! Map) return;
      final r = value;
      String reporter = (r['reporter'] ?? 'Anonymous').toString();
      userCounts[reporter] = (userCounts[reporter] ?? 0) + 1;
    });

    List<ModelUserStats> leaderboard = [];
    userCounts.forEach((k, v) {
      leaderboard.add(ModelUserStats(email: k, reportCount: v));
    });

    leaderboard.sort((a, b) => b.reportCount.compareTo(a.reportCount));
    return leaderboard.take(count).toList();
  }
  
  TrendAnalysis getTrendAnalysis(
      String areaName,
      List<double> history,
      double prediction,
  ) {
    return TrendAnalysis(
      areaName,
      history,
      prediction,
    );
  }
  // --- HELPERS ---

  ModelAnalyticsSummary _emptySummary() {
    return ModelAnalyticsSummary(
      areaRisks: [],
      deptMetrics: [],
      leaderboard: [],
      totalReports: 0,
      timestamp: DateTime.now(),
    );
  }

  Future<Map<dynamic, dynamic>> _fetchRawData(int? limit) async {
    try {
      Query query = FirebaseDatabase.instance.ref('atr');
      if (limit != null) {
        query = query.limitToLast(limit);
      }
      
      final snapshot = await query.get();
      if (!snapshot.exists) return {};

      final val = snapshot.value;
      
      // Handle Firebase returning a List (common if keys are integers)
      if (val is List) {
        Map<dynamic, dynamic> map = {};
        for (int i = 0; i < val.length; i++) {
          if (val[i] != null) {
            map[i.toString()] = val[i];
          }
        }
        return map;
      }
      
      // Handle standard Map
      if (val is Map) {
        return val;
      }

      return {};
    } catch (e) {
      print("Analytics Fetch Error: $e");
      return {};
    }
  }

  double _calculateScore(dynamic report) {
    if (report == null || report is! Map) return 0.0;
    
    String level = (report['level'] ?? 'low').toString().toLowerCase().trim();
    String type = (report['type'] ?? 'unsafe_condition').toString().toLowerCase().trim();
    
    int lWeight = levelWeights[level] ?? 1;
    int tWeight = typeWeights[type] ?? 1;
    
    return (lWeight * tWeight).toDouble();
  }
  
}

// Internal helper to keep counts before converting to final classes
class _TeamAggregator {
  int closed = 0;
  int pending = 0;
  double totalRisk = 0.0;

  void add(bool isClosed, double risk) {
    if (isClosed) closed++; else pending++;
    totalRisk += risk;
  }
}

class _AreaAggregator {
  int count = 0;
  double totalRisk = 0.0;

  void add(double risk) {
    count++;
    totalRisk += risk;
  }
}

class TrendAnalysis {
  final String areaName;
  final List<double> history; // Last 4 weeks
  final double prediction;    // Next week (AI Forecast)

  TrendAnalysis(this.areaName, this.history, this.prediction);

  // Is the risk going up or down?
  double get trendPercentage {
    if (history.isEmpty) return 0.0;
    double averageHistory = history.reduce((a, b) => a + b) / history.length;
    if (averageHistory == 0) return prediction > 0 ? 100.0 : 0.0;
    return ((prediction - averageHistory) / averageHistory) * 100;
  }

  bool get isCritical => trendPercentage > 20.0 && prediction > 2.0; // Rising >20% & significant count
}