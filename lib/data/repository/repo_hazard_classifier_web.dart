import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart'; // Web-Specific Package
import 'i_repo_hazard_classifier.dart';

IRepoHazardClassifier createClassifier() => RepoHazardClassifierWeb();


class RepoHazardClassifierWeb with LogMixin implements IRepoHazardClassifier {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  final List<String> _typeLabels = ["Unsafe_Condition", "Unsafe_Behavior", "NM", "FA"]; 
  List<String> _hazardLabels = [];
  List<String> _elecLabels = [];
  List<String> _levelLabels = [];
  bool _isLoaded = false;

  @override List<String> get typeLabels => _typeLabels;
  @override List<String> get hazardLabels => _hazardLabels;
  @override List<String> get elecLabels => _elecLabels;
  @override List<String> get levelLabels => _levelLabels;
  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      // Model path should match assets folder structure
      //_model = await TFLiteModel.fromUrl('assets/ai/safety_model.tflite');
      logInfo("Web AI Classifier: initializing...");
      await TFLiteWeb.initializeUsingCDN();
      _model = await TFLiteModel.fromUrl("assets/ai/safety_model.tflite");

      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      _hazardLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_hazard.json')));
      _elecLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_elec.json')));
      _levelLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_level.json')));
      _isLoaded = true;
      logInfo("Web AI Classifier: Ready.");
    } catch (e) {
      logError("Web AI Classifier Error: $e");
    }
  }

  @override
  Future<Map<String, String>> predict(String text) async {
    if (!_isLoaded || _model == null) return {};
    try {
      final inputTokens = _tokenize(text, 120);
      final output = _model!.predict<List<dynamic>>(inputTokens);
      if (output.length >= 3) {
        return {
          "type": "Unsafe_Condition",
          "hazard_kind": _hazardLabels[_argmax(output[0] as List)],
          "electrical_kind": _elecLabels[_argmax(output[1] as List)],
          "level": _levelLabels[_argmax(output[2] as List)]
        };
      }
    } catch (e) { logError("Inference Error: $e"); }
    return {};
  }

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<double> tokens = words.map((w) => (_vocab![w] ?? _vocab!['<OOV>'] ?? 1).toDouble()).toList();
    while (tokens.length < maxLen) {
      tokens.add(0.0);
    }
    return tokens.take(maxLen).toList();
  }

  int _argmax(List<dynamic> list) {
    double max = -1.0; int idx = 0;
    for (int i=0; i<list.length; i++) { 
      double val = (list[i] as num).toDouble();
      if (val > max) { max = val; idx = i; } 
    }
    return idx;
  }
}