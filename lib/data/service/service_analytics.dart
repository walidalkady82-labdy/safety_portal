import 'package:firebase_database/firebase_database.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/service/service_atr.dart';

import '../../locator.dart';
import '../model/model_analitcs_summery.dart';
import '../model/model_department_metric.dart';
import '../model/model_risk_metric.dart';
import '../model/model_user_stats.dart';

class ServiceAnalytics {
  final _atrService = sl<AtrService>();

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
    try{
    if (_cachedSummary != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedSummary!;
    }

    // 1. Fetch real data
       // 1. Fetch real data
      final reports = await _atrService.getAtrs(limit: limit ?? 100);

      // 2. Process
      if (reports.isEmpty) {
        return _emptySummary();
      }

    _cachedSummary = await _calculateStats(reports);
    _lastFetch = DateTime.now();
    return _cachedSummary!;
    } catch (e) {
      print("Analytics Error: $e");
      return _emptySummary();
      }
  }
  
  Future<ModelAnalyticsSummary> _calculateStats(List<ModelAtr> reports,{int limit = 100}) async {
    int open = 0;
    int closed = 0;
    int critical = 0;
    Map<String, int> dailyVolume = {};
    Map<String, int> riskTypes = {};

    for (var r in reports) {
      // Counts
      if (r.status.toLowerCase() == 'closed') {
        closed++;
      } else {
        open++;
      }

      if (r.level?.toLowerCase() == 'high' || r.type == 'FA') {
        critical++;
      }

      // Daily Volume (YYYY-MM-DD)
      if (r.issueDate.isNotEmpty) {
        // Normalize date if needed (e.g., take first 10 chars)
        String dateKey = r.issueDate.length >= 10 
            ? r.issueDate.substring(0, 10) 
            : r.issueDate;
        dailyVolume[dateKey] = (dailyVolume[dateKey] ?? 0) + 1;
      }

      // Risk Types
      String type = r.type ?? "Unknown";
      riskTypes[type] = (riskTypes[type] ?? 0) + 1;
    }

    // Sort Top Risks
    // (Optional: limit to top 5)
    
    // Safety Score (Simple Logic)
    int total = open + closed;
    double score = total == 0 ? 100 : (100 - (critical * 5) - (open * 2)).clamp(0, 100).toDouble();
    final areaRisks = await getAreaRiskMetrics( );
    final depMetrics =await  getDepartmentMetrics(limit: limit);
    final leaderboard =await getLeaderboard(limit: limit);


    return ModelAnalyticsSummary(
      plantSafetyScore: score,
      totalOpenRisks: open,
      mitigatedRisks: closed,
      criticalCount: critical,
      dailyVolume: dailyVolume,
      topRisks: riskTypes,
      areaRisks: areaRisks,
      deptMetrics: depMetrics,
      leaderboard: leaderboard,
      totalReports: reports.length,
      timestamp: DateTime.now(),
    );
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

    /// --- 5. AREA SPECIFIC ANALYTICS (NEW) ---
  Map<String, dynamic> getAreaMetrics(String area, List<ModelAtr> reports) {
    // Dynamic Status
    int score = reports.where((x)=> x.area == area).length;
    String status = 'Critical';
    if (score < 50) status = 'Stable';
    if (score >= 50 && score < 80) status = 'Warning';  
    return {
      'riskScore':score, 
      'status': status,
      'reports': reports
    };
  }

  /// --- 6. LEADERBOARD ---
  Future<List<Map<String, dynamic>>> getAreaLeaderboard(String area) async {
      return [
        {'name': 'John Doe', 'score': 1540, 'rank': 1},
        {'name': 'Sarah Smith', 'score': 1200, 'rank': 2},
        {'name': 'Mike Ross', 'score': 980, 'rank': 3},
      ];
    }
  

  // ModelAnalyticsSummary _processRawData(Map<dynamic, dynamic> rawData) {
  //   final areaRisks = _processAreaRisks(rawData);
  //   final deptMetrics = _processDepartmentMetrics(rawData);
  //   final leaderboard = _processLeaderboard(rawData);

  //   return ModelAnalyticsSummary(
  //     areaRisks: areaRisks,
  //     deptMetrics: deptMetrics,
  //     leaderboard: leaderboard,
  //     totalReports: rawData.length,
  //     timestamp: DateTime.now(),
  //   );
  // }

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