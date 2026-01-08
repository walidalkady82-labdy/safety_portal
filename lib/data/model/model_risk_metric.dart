class ModelRiskMetric {
  final String area;
  final int reportCount;
  final double totalRiskScore;
  final double avgSeverity;

  ModelRiskMetric({required this.area, required this.reportCount, required this.totalRiskScore, required this.avgSeverity});
}