abstract class IRepoHazardClassifier {
  Future<void> loadModel();
  
  // Updated to return a Map with all 6 keys
  Future<Map<String, String>> predict({
    required String line, 
    required String area, 
    required String text
  });

  Future<List<Map<String, dynamic>>> predictTopActions(String line, String area, String text);

  // Getters for the label lists (loaded from JSONs)
  List<String> get typeLabels;
  List<String> get hazardLabels;
  List<String> get detailedLabels; // Renamed from elecLabels to cover generic details
  List<String> get levelLabels;
  List<String> get actionLabels;   // NEW
  List<String> get deptLabels;     // NEW
  
  bool get isLoaded;
}