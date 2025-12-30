import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_web/tflite_web.dart';
import '../repository/switcher_hazard_classifier.dart';
import '../repository/switcher_duplicate_detector.dart';

class ServiceAI {
  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  // Use the Switcher classes (which handle the conditional imports)
  final IRepoHazardClassifier classifier = RepoHazardClassifier();
  final IRepoDuplicateDetector duplicateDetector = RepoDuplicateDetector();

  bool _isInitialized = false;

  Future<void> initAllModels() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        print("🚀 [DEBUG] Web AI: Initializing TFLite WASM engine...");
        await TFLiteWeb.initializeUsingCDN();
      }
      
      // 3. Load models (Now safe to do in parallel)
      await Future.wait([
        classifier.loadModel(),
        duplicateDetector.loadModel(),
      ]);
      
      _isInitialized = true;
      print("✅ [SUCCESS] All AI Models Initialized Successfully");
    } catch (e) {
      print("❌ [ERROR] AI Service Init Failure: $e");
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