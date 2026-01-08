class ModelDepartmentMetric {
  final String name;
  final int pending;
  final int closed;
  final double totalRisk;

  ModelDepartmentMetric({required this.name, required this.pending, required this.closed, required this.totalRisk});
  double get efficiency => (pending + closed) == 0 ? 0 : (closed / (pending + closed)) * 100;
}