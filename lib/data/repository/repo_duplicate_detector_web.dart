import 'dart:math';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:tflite_web/tflite_web.dart';


class RepoDuplicateDetectorWeb with LogMixin implements IRepoDuplicateDetector {
  TFLiteModel? _model;
  bool _isLoaded = false;
  bool _fallbackActive = false;

  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      logInfo("Web AI duplicate detector: initializing...");
      await TFLiteWeb.initialize();
      _model = await TFLiteModel.fromUrl("/assets/ai//embedding_model.tflite");
      logInfo("Web AI duplicate detector: ready...");
      _isLoaded = true;
    } catch (e) {
      logError("Web AI Notice: Embedding WASM failed. : ${e.toString()}");
      _fallbackActive = true;
      _isLoaded = true;
    }
  }

  @override
  Future<List<double>> getEmbedding(String text) async {
    if (!_isLoaded) await loadModel();
    // Return empty vector if AI failed
    return List.filled(64, 0.0);
  }

  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    // If we have real vectors, calculate cosine similarity
    if (vecA.isEmpty || vecB.isEmpty || vecA.every((v) => v == 0)) return 0.0;
    
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
}

// class RealDuplicateDetector implements IRepoDuplicationDetection {
// TFLiteModel? _model;
//   Map<String, int>? _vocab;
//   bool _isLoaded = false;
//   static bool _wasmInitialized = false;

//   @override
//   bool get isLoaded => _isLoaded;

//   @override
//   Future<void> loadModel() async {
//     if (_isLoaded) return;
//     try {
//       // 1. Initialize TFLite WASM binaries from Google CDN
//       if (!_wasmInitialized) {
//         print("Web AI: Initializing WASM...");
//         await TFLiteWeb.initializeUsingCDN();
//         _wasmInitialized = true;
//       }

//       // 2. Load the 64-dimension embedding model
//       _model = await TFLiteModel.fromUrl('assets/embedding_model.tflite');
      
//       // 3. Load the shared vocabulary
//       final vocabData = await rootBundle.loadString('assets/vocab.json');
//       _vocab = Map<String, int>.from(jsonDecode(vocabData));
      
//       _isLoaded = true;
//       print("Web AI: Duplicate Detector (64-dim) Ready.");
//     } catch (e) {
//       print("Web AI Load Error: $e");
//     }
//   }

//   @override
//   Future<List<double>> getEmbedding(String text) async {
//     if (!_isLoaded) await loadModel();
//     if (_model == null) return [];

//     try {
//       // MODIFICATION: Use Float32List for Web AI compatibility
//       // MaxLen must match MAX_LEN = 120 from Python
//       final tokens = _tokenize(text, 120);
//       final input = Float32List.fromList(tokens);
      
//       // Run prediction
//       final output = _model!.predict<List<dynamic>>(input);
      
//       if (output.isNotEmpty) {
//         // Explicitly cast to num then double to handle JS number types safely
//         final rawList = output[0] as List;
//         return rawList.map((e) => (e as num).toDouble()).toList();
//       }
//     } catch (e) {
//       print("Web AI Inference Error: $e");
//     }
    
//     return [];
//   }

//   @override
//   double calculateSimilarity(List<double> vecA, List<double> vecB) {
//     if (vecA.length != vecB.length) {
//       print("Web AI Similarity Error: Vector length mismatch (${vecA.length} vs ${vecB.length})");
//       return 0.0;
//     }
    
//     double dotProduct = 0.0;
//     double normA = 0.0;
//     double normB = 0.0;
    
//     for (int i = 0; i < vecA.length; i++) {
//       dotProduct += vecA[i] * vecB[i];
//       normA += vecA[i] * vecA[i];
//       normB += vecB[i] * vecB[i];
//     }
    
//     if (normA == 0 || normB == 0) return 0;
//     return dotProduct / (sqrt(normA) * sqrt(normB));
//   }

//   List<double> _tokenize(String text, int maxLen) {
//     if (_vocab == null) return List.filled(maxLen, 0.0);
    
//     List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    
//     // Explicitly convert all tokens to doubles for Web safety
//     List<double> tokens = words.map((w) {
//       final id = (_vocab![w] ?? _vocab!['<OOV>'] ?? 1);
//       return id.toDouble();
//     }).toList();
    
//     // Standard Padding/Truncating to 120
//     if (tokens.length > maxLen) {
//       return tokens.sublist(0, maxLen);
//     }
//     while (tokens.length < maxLen) {
//       tokens.add(0.0);
//     }
//     return tokens;
//   }
// }