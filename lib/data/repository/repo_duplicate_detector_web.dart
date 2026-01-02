import 'dart:convert';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:tflite_web/tflite_web.dart';

class RepoDuplicateDetectorWeb with LogMixin implements IRepoDuplicateDetector {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  List<String>? _areaLabels;
  bool _isLoaded = false;
  static bool _wasmInitialized = false;

  // Must match MAX_LEN from your Python training script (120)
  static const int _maxLen = 120; 

  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      print("Loading Embedding Model (Web - 64dim)...");
      
      if (!_wasmInitialized) {
        await TFLiteWeb.initializeUsingCDN();
        _wasmInitialized = true;
      }

      // FIX: Flutter Web serves assets at assets/assets/... 
      _model = await TFLiteModel.fromUrl('assets/assets/ai/safety_embedding_model.tflite');
      
      final vocabData = await rootBundle.loadString('assets/ai/vocab.json');
      _vocab = Map<String, int>.from(jsonDecode(vocabData));

      // Load area labels to map the area string to its training index
      try {
        final areaData = await rootBundle.loadString('ai/labels_area.json');
        _areaLabels = List<String>.from(jsonDecode(areaData));
      } catch (e) {
        print("Note: labels_area.json not found, using index 0 for all areas.");
      }
      
      _isLoaded = true;
      print("✅ Web Embedding Model Loaded successfully.");
    } catch (e) {
      print("❌ Web Embedding Load Error: $e");
    }
  }

  @override
  Future<List<double>> getEmbedding(String text, [String? area]) async {
    if (!_isLoaded) await loadModel();
    if (_model == null) return [];

    try {
      // 1. Prepare Input 1: Text Tokens
      var tokens = _tokenize(text, _maxLen);
      final textBuffer = Float32List.fromList(tokens);
      
      // 2. Prepare Input 2: Area Index
      // Even if area isn't provided, we MUST provide the second tensor if the model expects it.
      double areaIdx = 0.0;
      if (area != null && _areaLabels != null) {
        int found = _areaLabels!.indexOf(area);
        if (found != -1) areaIdx = found.toDouble();
      }
      final areaBuffer = Float32List.fromList([areaIdx]);

      // 3. Run Inference for Multi-Input Model
      // CRITICAL FIX: We pass a List of length 2 [TextTensor, AreaTensor]
      final output = _model!.predict<List<dynamic>>([textBuffer, areaBuffer]);
      
      // 4. Extract 64-dim vector
      if (output.isNotEmpty && output[0] is List) {
        final rawList = output[0] as List;
        return rawList.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      print("⚠️ Web AI Inference Error: $e");
      return List.filled(64, 0.0);
    }
    
    return [];
  }

  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) {
      print("Similarity Error: Vector length mismatch (${vecA.length} vs ${vecB.length})");
      return 0.0;
    }
    
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

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<double> tokens = [];
    
    for (String word in words) {
      if (tokens.length >= maxLen) break;
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
      int? index = _vocab![cleanWord];
      tokens.add((index ?? 1).toDouble()); 
    }
    
    while (tokens.length < maxLen) tokens.add(0.0);
    return tokens;
  }
}