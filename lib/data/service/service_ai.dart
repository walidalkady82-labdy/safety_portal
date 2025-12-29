import 'package:safety_portal/data/repository/switcher_duplication_detection.dart';

import '../repository/i_repo_hazard_classifier.dart';
import '../repository/switcher_hazard_classifier.dart';

class ServiceAI {
  // Singleton pattern
  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  final IRepoHazardClassifier classifier = RepoHazardClassifier();
  final RealDuplicateDetector duplicateDetector = RealDuplicateDetector();

  bool _isInitialized = false;

  Future<void> initAllModels() async {
    if (_isInitialized) return;
    
    // Load models in parallel to save time
    await Future.wait([
      classifier.loadModel(),
      duplicateDetector.loadModel(),
    ]);
    
    _isInitialized = true;
    print("All AI Models Initialized");
  }

  /// The 'Unified Brain' method.
  /// Runs classification and embedding generation simultaneously.
  Future<Map<String, dynamic>> analyzeFull(String text) async {
    // Safety check to ensure models are ready
    if (!_isInitialized) {
      await initAllModels();
    }

    // Run both AI tasks in parallel to minimize waiting time for the user
    final results = await Future.wait([
      classifier.predict(text),
      duplicateDetector.getEmbedding(text),
    ]);

    // results[0] is the Map<String, String> from the Classifier
    // results[1] is the List<double> (512 vector) from the Duplicate Detector
    return {
      'classification': results[0] as Map<String, String>,
      'embedding': results[1] as List<double>,
    };
  }

  /// Helper to check if AI is ready to use
  bool get isReady => _isInitialized;
}