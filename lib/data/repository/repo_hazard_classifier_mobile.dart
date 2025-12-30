import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'i_repo_hazard_classifier.dart';

class RepoHazardClassifier implements IRepoHazardClassifier {
  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  
  // 1. Default Type List (Since the model no longer predicts this)
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
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset('assets/ai/maintenance_model.tflite');
      
      // Load Vocabulary
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      
      // Load Labels for the 3 predicted outputs
      _hazardLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_hazard.json')));
      _elecLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_elec.json')));
      _levelLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_level.json')));
      
      _isLoaded = true;
      print("Mobile TFLite Model Loaded (3 Outputs)");
    } catch (e) {
      print("Mobile Model Error: $e");
    }
  }

  @override
  Future<Map<String, String>> predict(String text) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) return {};

    // 1. Tokenize Input
    var input = [_tokenize(text, 120)];
    
    // 2. Prepare Output Buffers (Only 3 now)
    // We create a buffer for each specific output head of the model
    var outHazard = List.filled(1 * _hazardLabels.length, 0.0).reshape([1, _hazardLabels.length]);
    var outElec = List.filled(1 * _elecLabels.length, 0.0).reshape([1, _elecLabels.length]);
    var outLevel = List.filled(1 * _levelLabels.length, 0.0).reshape([1, _levelLabels.length]);

    // 3. Run Inference
    // Map keys must match the output index order of your model:
    // 0: Hazard Kind
    // 1: Electrical Kind
    // 2: Level
    _interpreter!.runForMultipleInputs([input], {0: outHazard, 1: outElec, 2: outLevel});

    // 4. Return Results
    return {
      "type": "Unsafe_Condition", // Fixed Default
      "hazard_kind": _hazardLabels[_argmax(outHazard[0])],
      "electrical_kind": _elecLabels[_argmax(outElec[0])],
      "level": _levelLabels[_argmax(outLevel[0])]
    };
  }

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<double> tokens = [];
    
    for (String word in words) {
      if (tokens.length >= maxLen) break;
      int? index = _vocab![word];
      if (index == null) {
         // Attempt to strip basic punctuation if word not found
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
      if (list[i] > maxVal) { maxVal = list[i]; maxIdx = i; }
    }
    return maxIdx;
  }
}