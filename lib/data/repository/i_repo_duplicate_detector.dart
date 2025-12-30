abstract class IRepoDuplicateDetector {
  Future<void> loadModel();
  Future<List<double>> getEmbedding(String text);
  double calculateSimilarity(List<double> vecA, List<double> vecB);
  bool get isLoaded;
}