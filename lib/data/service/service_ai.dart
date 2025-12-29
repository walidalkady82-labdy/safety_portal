import 'package:safety_portal/data/repository/switcher_duplication_detection.dart';

import '../repository/i_repo_hazard_classifier.dart';
import '../repository/switcher_hazard_classifier.dart';

class ServiceAI {
  // Singleton pattern
  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  final IRepoHazardClassifier classifier = RepoHazardClassifier();
  final RealDuplicateDetector duplicateService = RealDuplicateDetector();

  bool _isInitialized = false;

  Future<void> initAllModels() async {
    if (_isInitialized) return;
    
    // Load models in parallel to save time
    await Future.wait([
      classifier.loadModel(),
      duplicateService.loadModel(),
    ]);
    
    _isInitialized = true;
    print("All AI Models Initialized");
  }

  /// Run all text analysis in one go
  Future<Map<String, dynamic>> analyzeObservation(String text) async {
    // We run these in parallel
    final results = await Future.wait([
      classifier.predict(text),
      duplicateService.getEmbedding(text),
    ]);

    return {
      'prediction': results[0] as Map<String, String>,
      'vector': results[1] as List<double>,
    };
  }
}