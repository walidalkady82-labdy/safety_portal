import 'dart:convert';
// ignore_for_file: avoid_web_libraries_in_flutter
//import 'dart:js_util' as js_util;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_web/tflite_web.dart';

import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';

class RepoDuplicateDetectorWeb with LogMixin implements IRepoDuplicateDetector {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  bool _isLoaded = false;
  static bool _wasmInitialized = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      if (!_wasmInitialized) {
        await TFLiteWeb.initializeUsingCDN();
        _wasmInitialized = true;
      }

      // 1. Load Embedding Model
      _model = await TFLiteModel.fromUrl('/assets/ai/safety_embedding_model.tflite');

      // 2. Load Vocab
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));

      _isLoaded = true;
      logInfo("✅ Web Duplicate Detector (64-dim) Loaded.");
    } catch (e) {
      logError("❌ Web Duplicate Detector Load Error: $e");
    }
  }

@override
  Future<List<double>> getEmbedding({
    required String line,
    required String area,
    required String text,
  }) async {
    if (!_isLoaded || _model == null) await loadModel();

    try {
      // 1. Context Injection (Must match Python training logic)
      String cleanLine = line.toLowerCase().replaceAll('nan', '').replaceAll('_', ' ').trim();
      String cleanArea = area.toLowerCase().replaceAll('nan', '').replaceAll('_', ' ').trim();
      String cleanText = text.toLowerCase().replaceAll('nan', '').trim();
      
      String combined = [cleanLine, cleanArea, cleanText]
          .where((s) => s.isNotEmpty)
          .join(" ");

      // 2. Tokenize with 10k Vocab Clamp
      // 1. Prepare the raw buffer
      final inputTokens = _tokenize(combined, 120);
      final inputBuffer = Float32List.fromList(inputTokens);

      // 2. Wrap it in a Tensor object
      // Shape [1, 120] matches the (None, 120) input expected by the CNN
      final inputTensor = Tensor(
        inputBuffer, 
        shape: [1, 120], 
        type: TFLiteDataType.float32
      );

      // 3. Pass the TENSOR to the model, not the list
      final result =_model!.predict<Tensor>(inputTensor);

      final vectorTensor = result;
      List<double> vector = vectorTensor.dataSync<Float32List>().toList();
      return vector;
    } catch (e) {
      logError("⚠️ Web Embedding Error: $e");
    }
    return List.filled(128, 0.0);
  }

  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length || vecA.isEmpty) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    double similarity = dot / (sqrt(normA) * sqrt(normB));
    return similarity.isNaN ? 0.0 : similarity;
  }

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    List<String> words = text.split(RegExp(r'\s+'));
    List<double> tokens = List.filled(maxLen, 0.0);
    for (int i = 0; i < words.length && i < maxLen; i++) {
      int index = _vocab![words[i]] ?? 1;
      if (index >= 10000) index = 1; // CRITICAL: Vocab Clamp
      tokens[i] = index.toDouble();
    }
    return tokens;
  }
}
