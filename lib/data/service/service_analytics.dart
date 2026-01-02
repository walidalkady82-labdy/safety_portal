import 'package:firebase_database/firebase_database.dart';

// --- Data Models ---
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

class TeamMetric {
  final String department;
  final int totalReports;
  final int closedReports;
  final int pendingReports;
  final double totalRiskHandled;

  double get closureRate => totalReports == 0 ? 0.0 : (closedReports / totalReports) * 100;

  TeamMetric({
    required this.department,
    required this.totalReports,
    required this.closedReports,
    required this.pendingReports,
    required this.totalRiskHandled,
  });
}

class ComparisonMetric {
  final String label;
  final double value;
  ComparisonMetric(this.label, this.value);
}

class CategoryMetric {
  final String label;
  final int count;
  CategoryMetric(this.label, this.count);
}

class UserStat {
  final int totalSubmitted;
  final int pending;
  final int closed;
  final String rank; // e.g., "Top Reporter", "Beginner"

  UserStat(this.totalSubmitted, this.pending, this.closed, this.rank);
}

// --- Service ---

class ServiceAnalytics {
  // Risk Weights
  final Map<String, int> levelWeights = {
    'low': 1,
    'medium': 3,
    'high': 5,
    'critical': 10,
  };

  /// Main method to fetch all analytics data at once
  Future<Map<String, dynamic>> getFullDashboardData(String? currentUserId) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('atr').get();
      if (!snapshot.exists) return {};

      // 1. Robust Data Normalization
      final rawValue = snapshot.value;
      Map<dynamic, dynamic> normalizedData = {};

      if (rawValue is Map) {
        normalizedData = rawValue;
      } else if (rawValue is List) {
        for (int i = 0; i < rawValue.length; i++) {
          if (rawValue[i] != null) {
            normalizedData[i.toString()] = rawValue[i];
          }
        }
      }

      print("Analytics: Processed ${normalizedData.length} records.");

      return {
        'areaRisks': _calculateAreaRisks(normalizedData),
        'teamPerformance': _calculateTeamPerformance(normalizedData),
        'monthlyTrend': _calculateMonthlyTrend(normalizedData),
        
        // New Analytics
        'typeBreakdown': _calculateBreakdown(normalizedData, 'type'),
        'hazardBreakdown': _calculateBreakdown(normalizedData, 'hazard_kind'),
        'electricalBreakdown': _calculateBreakdown(normalizedData, 'electrical_kind'),
        'levelBreakdown': _calculateBreakdown(normalizedData, 'level'),
        'userStats': _calculateUserStats(normalizedData, currentUserId),
        'existingVectors': _extractVectorsForDupCheck(normalizedData),
      };
    } catch (e) {
      print("Analytics Critical Error: $e");
      return {};
    }
  }

  // --- Helper: Generic Breakdown Calculator ---
  List<CategoryMetric> _calculateBreakdown(Map<dynamic, dynamic> data, String fieldKey) {
    Map<String, int> counts = {};
    data.forEach((key, value) {
      if (value is! Map) return;
      String label = (value[fieldKey] ?? 'Unknown').toString();
      // Clean up common variations if needed
      if (label.isEmpty) label = 'Unknown';
      counts[label] = (counts[label] ?? 0) + 1;
    });

    List<CategoryMetric> result = [];
    counts.forEach((k, v) => result.add(CategoryMetric(k, v)));
    result.sort((a, b) => b.count.compareTo(a.count)); // Sort Descending
    return result;
  }

  // --- Helper: User Stats ---
  UserStat _calculateUserStats(Map<dynamic, dynamic> data, String? userId) {
    if (userId == null) return UserStat(0, 0, 0, "Guest");

    int total = 0;
    int pending = 0;
    int closed = 0;

    data.forEach((key, value) {
      if (value is! Map) return;
      
      // Check if this report belongs to the user (by email or ID depending on your storage)
      // Assuming 'reporter' stores email, we might need to match vaguely if userId is passed as UID
      // For this example, let's assume 'reporter' field holds the email and we filter client-side 
      // OR we just count everything if we can't match. 
      // Ideally: if (value['uid'] == userId) ...
      
      // Since we stored 'reporter' as email in previous files, we can't strictly match UID without user email.
      // We will count stats for *ALL* records here as a "Global View" if userId match fails, 
      // OR you must pass the user's email to this function instead of UID.
      // Let's assume the UI passes the email for accurate matching.
      String reporter = (value['reporter'] ?? '').toString();
      if (reporter == userId) { // userId here should be the email passed from UI
        total++;
        String status = (value['status'] ?? 'Pending').toString().toLowerCase();
        if (status.contains('closed') || status.contains('done')) {
          closed++;
        } else {
          pending++;
        }
      }
    });

    String rank = "Beginner";
    if (total > 5) rank = "Observer";
    if (total > 15) rank = "Safety Scout";
    if (total > 50) rank = "Guardian";

    return UserStat(total, pending, closed, rank);
  }

  // --- Helper: Extract Vectors for Duplicate Detection ---
  List<Map<String, dynamic>> _extractVectorsForDupCheck(Map<dynamic, dynamic> data) {
    List<Map<String, dynamic>> vectors = [];
    data.forEach((key, value) {
      if (value is! Map) return;
      if (value['vector'] != null && value['observationOrIssueOrHazard'] != null) {
        try {
          // Handle dynamic list conversion safely
          List<dynamic> rawVec = value['vector'] is List ? value['vector'] : [];
          if (rawVec.isNotEmpty) {
             vectors.add({
               'id': key,
               'text': value['observationOrIssueOrHazard'].toString(),
               'vector': rawVec.map((e) => (e as num).toDouble()).toList(),
             });
          }
        } catch (e) {
          // ignore malformed vectors
        }
      }
    });
    return vectors;
  }

  // --- Existing Calculators (Preserved) ---
  
  List<RiskMetric> _calculateAreaRisks(Map<dynamic, dynamic> data) {
    Map<String, List<double>> areaScores = {};
    data.forEach((key, value) {
      if (value is! Map) return;
      String area = (value['area'] ?? 'Unknown').toString();
      String level = (value['level'] ?? 'low').toString().toLowerCase().trim();
      int lWeight = levelWeights[level] ?? 1;
      if (!areaScores.containsKey(area)) areaScores[area] = [];
      areaScores[area]!.add(lWeight.toDouble());
    });

    List<RiskMetric> metrics = [];
    areaScores.forEach((area, scores) {
      double total = scores.fold(0.0, (sum, item) => sum + item);
      metrics.add(RiskMetric(
        area: area,
        reportCount: scores.length,
        totalRiskScore: total,
        avgSeverity: scores.isEmpty ? 0 : total / scores.length,
      ));
    });
    metrics.sort((a, b) => b.totalRiskScore.compareTo(a.totalRiskScore));
    return metrics;
  }

  List<TeamMetric> _calculateTeamPerformance(Map<dynamic, dynamic> data) {
    Map<String, Map<String, dynamic>> teamStats = {};
    data.forEach((key, value) {
       if (value is! Map) return;
       String dept = (value['respDepartment'] ?? 'General').toString();
       String status = (value['status'] ?? 'Pending').toString().toLowerCase();
       if (!teamStats.containsKey(dept)) teamStats[dept] = {'total': 0, 'closed': 0, 'pending': 0, 'risk': 0.0};
       teamStats[dept]!['total'] += 1;
       if (status.contains('closed') || status.contains('done')) {
         teamStats[dept]!['closed'] += 1;
       } else {
         teamStats[dept]!['pending'] += 1;
       }
    });
    List<TeamMetric> metrics = [];
    teamStats.forEach((dept, stats) {
      metrics.add(TeamMetric(
        department: dept,
        totalReports: stats['total'],
        closedReports: stats['closed'],
        pendingReports: stats['pending'],
        totalRiskHandled: stats['risk'],
      ));
    });
    metrics.sort((a, b) => b.closureRate.compareTo(a.closureRate));
    return metrics;
  }

  List<ComparisonMetric> _calculateMonthlyTrend(Map<dynamic, dynamic> data) {
    Map<String, int> counts = {};
    data.forEach((key, value) {
      if (value is! Map) return;
      if (value['issueDate'] != null) {
        try {
          DateTime date = DateTime.parse(value['issueDate']);
          String k = "${date.month}/${date.year}";
          counts[k] = (counts[k] ?? 0) + 1;
        } catch (_) {}
      }
    });
    List<ComparisonMetric> trend = [];
    counts.forEach((k, v) => trend.add(ComparisonMetric(k, v.toDouble())));
    return trend;
  }
}