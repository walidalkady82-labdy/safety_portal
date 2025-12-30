import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_web/tflite_web.dart';
// Conditional import for web security checks
// ignore: avoid_web_libraries_in_flutter

import '../repository/switcher_hazard_classifier.dart';
import '../repository/switcher_duplicate_detector.dart';
import 'dart:html' as html; 

class ServiceAI {
  // Singleton pattern
  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  final IRepoHazardClassifier classifier = RepoHazardClassifier();
  final IRepoDuplicateDetector duplicateDetector = RepoDuplicateDetector();

  bool _isInitialized = false;
  bool _isWasmEnabled = false;

  Future<void> initAllModels() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        print("🔍 [DEBUG] Web AI: Checking browser security context...");
        
        // --- THE SECURITY CHECK ---
        bool isIsolated = false;
        try {
          // Verify if COOP/COEP headers are active. 
          // If false, Edge blocks SharedArrayBuffer and dynamic linking.
          isIsolated = (html.window as dynamic).crossOriginIsolated == true;
        } catch (e) {
          isIsolated = false;
        }
        
        if (!isIsolated) {
          print("⚠️ [CRITICAL] Browser is NOT Cross-Origin Isolated.");
          print("TFLite WASM will fail with 'Aborted (dlopen)'.");
          print("👉 FIX: You MUST build the app and visit http://localhost:5000 via Firebase Hosting Emulator.");
          print("👉 Note: 'flutter run' does NOT support the required security headers.");
        } else {
          print("✅ [DEBUG] Browser is Isolated. TFLite memory unlocked.");
        }

        print("🚀 [DEBUG] Web AI: Initializing TFLite WASM engine...");
        await TFLiteWeb.initializeUsingCDN();
        _isWasmEnabled = true;
      } else {
        // Mobile doesn't need WASM isolation
        _isWasmEnabled = true;
      }
      
      // Load specific models in parallel
      await Future.wait([
        classifier.loadModel(),
        duplicateDetector.loadModel(),
      ]);
      
      _isInitialized = true;
      print("✅ [SUCCESS] All AI Models Initialized Successfully");
    } catch (e) {
      // This is where the 'Aborted(dlopen)' error is caught
      print("❌ [ERROR] AI Service Engine Failure: $e");
      print("🔄 AI Service: Entering Fallback Mode (Keyword matching enabled).");
      
      _isWasmEnabled = false;
      _isInitialized = true; 
    }
  }

  /// The 'Unified Brain' method.
  /// Runs classification and embedding generation simultaneously.
  Future<Map<String, dynamic>> analyzeFull(String text) async {
    if (!_isInitialized) {
      await initAllModels();
    }

    // Run both AI tasks in parallel
    final results = await Future.wait([
      classifier.predict(text),
      duplicateDetector.getEmbedding(text),
    ]);

    return {
      'classification': results[0] as Map<String, String>,
      'embedding': results[1] as List<double>,
      'is_ai_active': _isWasmEnabled,
    };
  }

  bool get isReady => _isInitialized;
  bool get isAiActive => _isWasmEnabled;
}