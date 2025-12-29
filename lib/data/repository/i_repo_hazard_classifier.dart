abstract class IRepoHazardClassifier {
  Future<void> loadModel();
  Future<Map<String, String>> predict(String text);
  List<String> get typeLabels;
  List<String> get hazardLabels;
  List<String> get elecLabels;
  List<String> get levelLabels;
  bool get isLoaded;
}