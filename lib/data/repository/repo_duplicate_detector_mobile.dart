import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class RepoDuplicateDetectorMobile implements IRepoDuplicateDetector {
  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      print("📱 Mobile AI: Loading Embedding Model...");
      // 1. Load the 64-dimension embedding model
      _interpreter = await Interpreter.fromAsset('assets/ai/safety_embedding_model.tflite');
      
      // 2. Load the vocabulary
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      
      _isLoaded = true;
      print("✅ Mobile AI: Duplicate Detector Loaded");
    } catch (e) {
      print("❌ Mobile AI Error: $e");
    }
  }

  @override
Future<List<double>> getEmbedding({required String line,required String area,required String text}) async {
  if (!_isLoaded) await loadModel();

  // Reuse the same cleaning logic as the classifier
  String combined = "${line.toLowerCase()} ${area.toLowerCase()} ${text.toLowerCase()}";
  var input = [_tokenize(combined, 120)];

  // UPDATED SIZE: 128
  var output = List<double>.filled(1 * 128, 0.0).reshape([1, 128]);

  _interpreter!.run(input, output);
  return List<double>.from(output[0]);
}

  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length || vecA.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<double> tokens = [];
    
    for (String word in words) {
      if (tokens.length >= maxLen) break;
      int? index = _vocab![word];
      if (index == null) {
         // Remove special chars to try and find the word
         String stripped = word.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ''); 
         index = _vocab![stripped];
      }
      tokens.add((index ?? _vocab!['<OOV>'] ?? 1).toDouble());
    }
    
    // Post-padding
    while (tokens.length < maxLen) {
      tokens.add(0.0);
    }
    return tokens;
  }
}