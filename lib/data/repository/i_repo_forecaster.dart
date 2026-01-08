abstract class IRepoForecaster {
  Future<void> loadModel();
  Future<Map<String, double>> predictNextWeek(List<List<double>> last4Weeks);
  bool get isLoaded;
}