abstract class IRepoForecaster {
  Future<void> loadModel();
  Future<Map<String, List<double>>> predict(List<List<double>> last4Weeks);
  bool get isLoaded;
  List<String> get areas;
}