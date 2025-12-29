import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_web/tflite_web.dart'; // Web-Specific Package
import 'i_repo_hazard_classifier.dart';

class RepoHazardClassifier implements IRepoHazardClassifier {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  
  // Default Type list for Dropdown (since model doesn't predict it)
  List<String> _typeLabels = ["Unsafe_Condition", "Unsafe_Behavior", "NM", "FA"]; 
  
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
      await TFLiteWeb.initializeUsingCDN();
      // 1. Load Model (Web uses URL path to assets)
      _model = await TFLiteModel.fromUrl('assets/maintenance_model.tflite');
      
      // 2. Load Vocab
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/vocab.json')));
      
      // 3. Load Labels (Only for the 3 outputs)
      _hazardLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/labels_hazard.json')));
      _elecLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/labels_elec.json')));
      _levelLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/labels_level.json')));
      
      _isLoaded = true;
      print("Web TFLite Model Loaded (3 Outputs)");
    } catch (e) {
      print("Web Model Load Error: $e");
    }
  }

  @override
  Future<Map<String, String>> predict(String text) async {
    if (!_isLoaded) await loadModel();
    if (_model == null) return {};

    // 1. Tokenize Input
    var inputTokens = _tokenize(text, 256);
    
    // 2. Run Inference
    // Returns a List of output tensors (Lists of probabilities)
    final output = _model!.predict<List<dynamic>>(inputTokens);
    
    // 3. Map Outputs
    // Assumption: Order is [Hazard, Electrical, Level]
    if (output.length >= 3) {
      return {
        "type": "Unsafe_Condition", // Fixed Default
        "hazard_kind": _hazardLabels[_argmax(output[0] as List)],
        "electrical_kind": _elecLabels[_argmax(output[1] as List)],
        "level": _levelLabels[_argmax(output[2] as List)]
      };
    }
    return {};
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

  int _argmax(List<dynamic> list) {
    double maxVal = -double.infinity;
    int maxIdx = 0;
    for (int i = 0; i < list.length; i++) {
      double val = (list[i] as num).toDouble();
      if (val > maxVal) { maxVal = val; maxIdx = i; }
    }
    return maxIdx;
  }
}