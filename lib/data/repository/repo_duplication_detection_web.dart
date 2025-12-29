import 'dart:math';
import 'package:tflite_web/tflite_web.dart';
import 'i_repo_duplication_detection.dart';

class RealDuplicateDetector implements IRepoDuplicationDetection {
  TFLiteModel? _model;
  bool _isLoaded = false;
  static bool _wasmInitialized = false;

  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    if (!_wasmInitialized) {
      await TFLiteWeb.initializeUsingCDN();
      _wasmInitialized = true;
    }
    // Load the specialized embedding model
    _model = await TFLiteModel.fromUrl('assets/embedding_model.tflite');
    _isLoaded = true;
  }

  @override
  Future<List<double>> getEmbedding(String text) async {
    if (!_isLoaded) return [];
    // Tokenization and inference logic for Web
    final output = _model!.predict<List<dynamic>>([0.0]); // Simplified example
    return List<double>.from(output[0]);
  }

  @override
  double calculateSimilarity(List<double> vecA, List<double> vecB) {
    double dot = 0.0, nA = 0.0, nB = 0.0;
    for (int i = 0; i < vecA.length; i++) {
      dot += vecA[i] * vecB[i];
      nA += vecA[i] * vecA[i];
      nB += vecB[i] * vecB[i];
    }
    return dot / (sqrt(nA) * sqrt(nB));
  }
}