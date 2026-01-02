import 'dart:async';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:safety_portal/data/repository/i_repo_hazard_classifier.dart';
import 'package:safety_portal/locator.dart';


class ServiceAI with LogMixin{
  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  // Use the Switcher classes (which handle the conditional imports)
final classifier = sl<IRepoHazardClassifier>();
final duplicateDetector = sl<IRepoDuplicateDetector>();


  Future<Map<String, dynamic>> analyzeFull(String text, [String? area]) async {
   //if (!_isInitialized) await initAllModels();

    final results = await Future.wait([
      classifier.predict(text),
      duplicateDetector.getEmbedding(text, area),
    ]);
    logInfo("'classification': ${results[0]} , 'embedding': ${results[1]}");
    return {
      'classification': results[0] as Map<String, String>,
      'embedding': results[1] as List<double>,
    };
  }
}