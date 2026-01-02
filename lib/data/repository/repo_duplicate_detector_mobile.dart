import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class RepoDuplicateDetectorMobile implements IRepoDuplicateDetector {
  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  bool _isLoaded = false;

  // Match this to your Python script's MAX_LEN
  static const int _maxLen = 256; 

  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      print("Loading Embedding Model (Mobile - 64dim)...");
      
      // 1. Load the new 64-dim embedding model
      _interpreter = await Interpreter.fromAsset('assets/ai/safety_embedding_model.tflite');
      
      // 2. Load Vocab
      final vocabData = await rootBundle.loadString('assets/ai/vocab.json');
      _vocab = Map<String, int>.from(jsonDecode(vocabData));
      
      _isLoaded = true;
      print("Mobile Embedding Model (64-dim) Loaded.");
    } catch (e) {
      print("Error loading Mobile Embedding Model: $e");
    }
  }

  @override
  Future<List<double>> getEmbedding(String text, [String? area]) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) return [];

    // 1. Tokenize (Input Shape: [1, 256]) - Using INTEGERS
    var input = [_tokenize(text, _maxLen)];

    // 2. Output Buffer (Output Shape: [1, 64])
    var output = List.filled(1 * 64, 0.0).reshape([1, 64]);

    // 3. Run Inference
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      print("Mobile Inference Error: $e");
      return [];
    }
    
    // 4. Extract 64-dim vector
    return List<double>.from(output[0]);
  }

  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) return 0.0;
    
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  // Changed return type to List<int> for Embedding Layer
  List<int> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0); // 0 padding
    
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<int> tokens = [];
    
    for (String word in words) {
      if (tokens.length >= maxLen) break;
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
      int? index = _vocab![cleanWord];
      // Use 1 for <OOV>, do NOT convert to double
      tokens.add(index ?? 1); 
    }
    
    // Pad with 0s
    while (tokens.length < maxLen) tokens.add(0);
    return tokens;
  }
}