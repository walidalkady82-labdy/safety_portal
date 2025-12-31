import 'dart:async';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:safety_portal/data/repository/i_repo_hazard_classifier.dart';
import '../repository/switcher_hazard_classifier.dart';
import '../repository/switcher_duplicate_detector.dart';

class ServiceAI with LogMixin{
  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  // Use the Switcher classes (which handle the conditional imports)
  final IRepoHazardClassifier classifier = createClassifier();
  final IRepoDuplicateDetector duplicateDetector = createDuplicateDetector();

  bool _isInitialized = false;

  Future<void> initAllModels() async {
    if (_isInitialized) return;

    try {   
      // 3. Load models (Now safe to do in parallel)
      logInfo("ServiceAI: initializing AI models");
      await Future.wait([
        classifier.loadModel(),
        duplicateDetector.loadModel(),
      ]);
      
      _isInitialized = true;
      logInfo("✅ [SUCCESS] All AI Models Initialized Successfully");
    } catch (e) {
      logError("❌ [ERROR] AI Service Init Failure: $e");
      // Mark as initialized so the UI doesn't hang (it will use keyword fallback)
      _isInitialized = true; 
    }
  }

  Future<Map<String, dynamic>> analyzeFull(String text) async {
    if (!_isInitialized) await initAllModels();

    final results = await Future.wait([
      classifier.predict(text),
      duplicateDetector.getEmbedding(text),
    ]);

    return {
      'classification': results[0] as Map<String, String>,
      'embedding': results[1] as List<double>,
    };
  }
}