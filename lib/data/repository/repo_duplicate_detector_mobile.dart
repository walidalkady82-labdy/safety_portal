import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RepoDuplicateDetector implements IRepoDuplicateDetector {
  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      // Load the specialized embedding model (USE-Lite)
      _interpreter = await Interpreter.fromAsset('assets/ai/embedding_model.tflite');
      
      // Load the vocabulary for tokenization
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      
      _isLoaded = true;
      print("Mobile Embedding Model Loaded successfully.");
    } catch (e) {
      print("Mobile Embedding Model Error: $e");
    }
  }

  /// Converts text to a 512-dimension vector using TFLite on Mobile
  @override
  Future<List<double>> getEmbedding(String text) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) return [];

    // 1. Tokenize the input text
    var input = [_tokenize(text, 120)];
    
    // 2. Prepare output buffer (USE Lite outputs a 512-dimension vector)
    var output = List.filled(1 * 512, 0.0).reshape([1, 512]);

    // 3. Run inference
    _interpreter!.run(input, output);
    
    return List<double>.from(output[0]);
  }

  /// Calculates Cosine Similarity between two vectors (0.0 to 1.0)
  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  List<int> _tokenize(String text, int maxLen) {
    // Basic tokenization matching the vocabulary provided
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<int> tokens = words.map((w) => _vocab![w] ?? 1).toList();
    
    // Pad or truncate to maxLen
    while (tokens.length < maxLen) {
      tokens.add(0);
    }
    return tokens.take(maxLen).toList();
  }
}