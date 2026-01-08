import 'dart:async';
import 'dart:math';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:safety_portal/data/repository/i_repo_hazard_classifier.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/locator.dart';

import '../repository/i_repo_forecaster.dart';


class ServiceAI with LogMixin{

  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  // Use the Switcher classes (which handle the conditional imports)
  final classifier = sl<IRepoHazardClassifier>();
  final duplicateDetector = sl<IRepoDuplicateDetector>();
  final repoForecaster = sl<IRepoForecaster>();
  final atrService = sl<AtrService>();

  bool _isInitialized = false;

  Future<void> initAllModels() async {
    if (_isInitialized) return;
    await Future.wait([
      classifier.loadModel(),
      duplicateDetector.loadModel(),
      repoForecaster.loadModel(),
    ]);
    _isInitialized = true;
    logInfo("AI Models Initialized");
  }
  
  Future<Map<String, dynamic>> analyzeFull(String text, {required line,required String area}) async {
    if (!_isInitialized) await initAllModels();

    // Ensure area is never null to prevent tensor creation errors
    final results = await Future.wait([
      classifier.predict(line:line,area: area,text:  text),
      duplicateDetector.getEmbedding(line:line,area: area,text:  text),
    ]);

    return {
      'classification': results[0] as Map<String, String>,
      'embedding': results[1] as List<double>,
    };
  }
  /// --- SMART SEARCH & SMART ACTION CORE ---
  /// Finds reports in [sourceData] that are semantically similar to [query].
  /// Returns a sorted list of matches with a 'similarity' score.
  Future<List<Map<String, dynamic>>> searchSimilarReports(
    String query, 
    List<ModelAtr> sourceData, 
    {double threshold = 0.5, int limit = 10}
  ) async {
    if (!_isInitialized) await initAllModels();
    if (query.isEmpty) return [];

    // 1. Get embedding for the query
    List<double> queryVector = await duplicateDetector.getEmbedding(line:"",area:"",text:query);
    if (queryVector.isEmpty || (queryVector.length == 1 && queryVector[0] == 0)) {
      return [];
    }

    // 2. Compare with all source reports
    List<Map<String, dynamic>> matches = [];

    for (var report in sourceData) {
      if (report.vector == null || report.vector!.isEmpty) continue;

      double score = duplicateDetector.calculateSimilarity(queryVector, report.vector!);
      
      if (score >= threshold) {
        matches.add({
          'report': report,
          'score': score,
        });
      }
    }

    // 3. Sort by similarity (Highest first)
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return matches.take(limit).toList();
  }

  /// --- Returns a score from 0.0 (Bad) to 1.0 (Perfect) ---
  /// 
  // 1. Hardcode a few "Perfect" descriptions to act as the Gold Standard
  final List<String> _goldStandardExamples = [
    "Oil leakage detected in the main pump seal causing slip hazard",
    "Emergency stop button broken on conveyor belt 5",
    "High voltage cable insulation damaged near the walkway",
    "Workers not wearing safety helmet in the construction zone",
    "Fire extinguisher pressure gauge is reading zero/empty"
  ];

  // Cache the "Gold Vector" so we don't calculate it every time
  List<double>? _goldVector;

  Future<double> getQualityScore(String text) async {
    if (!_isInitialized) await initAllModels();

  // 1. Calculate Gold Vector (Once)
  if (_goldVector == null) {
    var vectors = <List<double>>[];
    for (var ex in _goldStandardExamples) {
      vectors.add(await duplicateDetector.getEmbedding(line: '', area: '', text: ex));
    }
    // Average them to create a "Perfect Safety Concept"
    _goldVector = List.filled(128, 0.0);
    for (var v in vectors) {
      for (int i = 0; i < 128; i++) _goldVector![i] += v[i];
    }
    // Normalize
    for (int i = 0; i < 128; i++) _goldVector![i] /= vectors.length;
    }

    // 2. Get User Vector
    // We only care about the text content for quality
    List<double> userVector = await duplicateDetector.getEmbedding(line: '', area: '', text: text);

    // 3. Compare
    double similarity = duplicateDetector.calculateSimilarity(userVector, _goldVector!);

    // 4. Map Similarity (0.3 to 0.8) to Score (0 to 100)
    // (Embeddings are rarely < 0.3 or > 0.9 for this type of data)
    double score = (similarity - 0.3) / (0.8 - 0.3);
    if (score < 0) score = 0;
    if (score > 1) score = 1;

    return score; 
  }

}

// --- Isolate Helpers ---

class _SearchArgs {
  final List<ModelAtr> reports;
  final List<double> queryVector;
  _SearchArgs(this.reports, this.queryVector);
}

List<Map<String, dynamic>> _findNearestNeighbors(_SearchArgs args) {
  List<Map<String, dynamic>> results = [];

  for (var record in args.reports) {
    if (record.vector == null || record.vector!.isEmpty) continue;
    
    // Manual Cosine Similarity to avoid passing Service dependencies
    double dot = 0.0, magA = 0.0, magB = 0.0;
    for (int i = 0; i < args.queryVector.length; i++) {
      dot += args.queryVector[i] * record.vector![i];
      magA += args.queryVector[i] * args.queryVector[i];
      magB += record.vector![i] * record.vector![i];
    }
    double score = (magA == 0 || magB == 0) ? 0.0 : dot / (sqrt(magA) * sqrt(magB));

    if (score > 0.65) {
      results.add({'record': record, 'score': score});
    }
  }

  results.sort((a, b) => b['score'].compareTo(a['score']));
  return results.take(5).toList();
}