import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'i_repo_hazard_classifier.dart';

class RepoHazardClassifierMobile implements IRepoHazardClassifier {
  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  
  // Dynamic Label Lists
  List<String> _hazardLabels = [];
  List<String> _elecLabels = [];
  List<String> _levelLabels = [];
  
  // Default Type List (Not predicted by model, used for UI)
  final List<String> _typeLabels = ["Unsafe_Condition", "Unsafe_Behavior", "NM", "FA"];
  
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
      print("Loading Safety Classifier (Mobile)...");
      
      // 1. Load the new model
      _interpreter = await Interpreter.fromAsset('assets/ai/safety_classifier_model.tflite');
      
      // 2. Load Vocab
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      
      // 3. Load Labels
      _hazardLabels = await _loadLabelMap('assets/ai/labels_hazard.json');
      _elecLabels = await _loadLabelMap('assets/ai/labels_elec.json');
      _levelLabels = await _loadLabelMap('assets/ai/labels_level.json');

      _isLoaded = true;
      print("Safety Classifier Loaded. Labels: H=${_hazardLabels.length}, E=${_elecLabels.length}, L=${_levelLabels.length}");
      
    } catch (e) {
      print("Error loading Safety Classifier: $e");
    }
  }

  Future<List<String>> _loadLabelMap(String path) async {
    try {
      String jsonString = await rootBundle.loadString(path);
      List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => e.toString()).toList();
    } catch (e) {
      print("Error parsing list from $path: $e");
      return [];
    }
  }

  @override
  Future<Map<String, String>> predict(String text) async {
    if (!_isLoaded) await loadModel();
    if (_interpreter == null) return {};

    // 1. Tokenize (Max Len 120)
    var input = [_tokenize(text, 120)];

    // 2. Prepare Output Buffers
    // Python Model Outputs: [out_hazard, out_elec, out_level]
    var outHazard = List.filled(1 * _hazardLabels.length, 0.0).reshape([1, _hazardLabels.length]);
    var outElec = List.filled(1 * _elecLabels.length, 0.0).reshape([1, _elecLabels.length]);
    var outLevel = List.filled(1 * _levelLabels.length, 0.0).reshape([1, _levelLabels.length]);

    // 3. Run Inference
    // We pass outputs as a map where keys correspond to the output indices of the model
    Map<int, Object> outputs = {0: outHazard, 1: outElec, 2: outLevel};
    
    // Note: If your model expects multiple inputs (like text + area), add them here. 
    // Assuming strictly text based on previous context:
    _interpreter!.runForMultipleInputs([input], outputs); 

    // 4. Decode Results
    return {
      "type": "Unsafe_Condition",
      "hazard_kind": _getLabel(_hazardLabels, outHazard[0]),
      "electrical_kind": _getLabel(_elecLabels, outElec[0]),
      "level": _getLabel(_levelLabels, outLevel[0])
    };
  }

  String _getLabel(List<String> labels, List<dynamic> probabilities) {
    if (labels.isEmpty) return "Unknown";
    int maxIndex = 0;
    double maxProb = -1.0;
    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }
    return maxIndex < labels.length ? labels[maxIndex] : "Unknown";
  }

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    List<double> tokens = [];
    
    for (String word in words) {
      if (tokens.length >= maxLen) break;
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
      int? index = _vocab![cleanWord];
      tokens.add((index ?? 1).toDouble()); // 1 is <OOV>
    }
    while (tokens.length < maxLen) tokens.add(0.0);
    return tokens;
  }
}