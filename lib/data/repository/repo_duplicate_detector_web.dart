import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:js_util' as js;
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:tflite_web/tflite_web.dart';

class RepoDuplicateDetectorWeb with LogMixin implements IRepoDuplicateDetector {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  bool _isLoaded = false;
  bool _fallbackActive = false;

  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      print("Web AI: Initializing Duplicate Detector...");
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _model = await TFLiteModel.fromUrl('assets/assets/ai/safety_embedding_model.tflite?v=$timestamp');
      final vocabData = await rootBundle.loadString('assets/ai/vocab.json');
      _vocab = Map<String, int>.from(jsonDecode(vocabData));
      _isLoaded = true;
      print("Web AI: Embedding Model Loaded (v=$timestamp)");
    } catch (e) {
      print("Web AI Embedding Load Error: $e");
      _fallbackActive = true;
      _isLoaded = true; 
    }
  }

  @override
  Future<List<double>> getEmbedding(String text) async {
    if (!_isLoaded) await loadModel();
    if (_model == null || _fallbackActive) return List.filled(64, 0.0);

    try {
      List<double> tokens = _tokenize(text, 120);

      final tensor = Tensor(
        Float32List.fromList(tokens),
        shape: [1, 120],
        type: TFLiteDataType.float32,
      );

      final dynamic output = _model!.predict(tensor);
      
      if (output != null) {
        // Strategy 0: Output IS the Tensor (Direct Return)
        // This checks if the object itself has .dataSync()
        if (js.hasProperty(output, 'dataSync')) {
           return _extractTensorData(output);
        }

        // Strategy 1: Output is a List (common for TFLite)
        if (output is List && output.isNotEmpty) {
           return _extractTensorData(output[0]);
        } 
        
        // Strategy 2: Output is a JS Object (NamedTensorMap)
        try {
           final keys = js.objectKeys(output);
           if (keys is List) {
             for (var key in keys) {
               final value = js.getProperty(output, key as Object);
               
               if (value == null || value is bool || value is num || value is String) continue;

               if (js.hasProperty(value, 'dataSync')) {
                 return _extractTensorData(value);
               }
             }
           }
        } catch (e) {
           print("Web AI: Error searching output keys: $e");
        }
      } else {
        print("Web AI: Embedding model returned NULL output.");
      }
    } catch (e) {
      print("Web AI Inference Error (Embedding): $e");
    }
    return List.filled(64, 0.0);
  }

  List<double> _extractTensorData(dynamic jsObject) {
    if (jsObject == null) return [];
    
    try {
      // Method 1: TFJS .dataSync()
      if (js.hasProperty(jsObject, 'dataSync')) {
         var data = js.callMethod(jsObject, 'dataSync', []);
         return List<dynamic>.from(data).map((e) => (e as num).toDouble()).toList();
      }
      
      // Method 2: Direct Array access
      if (jsObject is List) {
         return jsObject.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      print("Tensor extraction error: $e");
    }
    return [];
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
         String stripped = word.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ''); 
         index = _vocab![stripped];
      }
      tokens.add((index ?? _vocab!['<OOV>'] ?? 1).toDouble());
    }
    while (tokens.length < maxLen) tokens.add(0.0);
    return tokens;
  }
}