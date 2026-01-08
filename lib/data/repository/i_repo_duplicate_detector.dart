abstract class IRepoDuplicateDetector {
  Future<void> loadModel();
  Future<List<double>> getEmbedding({
    required String line, 
    required String area, 
    required String text
  });
  double calculateSimilarity(List<double> vecA, List<double> vecB);
  bool get isLoaded;
}