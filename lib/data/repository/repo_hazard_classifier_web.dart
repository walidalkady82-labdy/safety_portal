import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart'; 
import 'i_repo_hazard_classifier.dart';
import 'dart:js_util' as js; // Required to handle JS Objects/Tensors

class RepoHazardClassifierWeb implements IRepoHazardClassifier {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  
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
      print("Loading Safety Classifier (Web)...");
      
      // 1. Initialize TFLite Web (if not already done globally)
      // await TFLiteWeb.initializeUsingCDN(); 
      // 2. Load the new model
      await TFLiteWeb.initializeUsingCDN();
      _model = await TFLiteModel.fromUrl('assets/ai/safety_classifier_model.tflite');
      
      // 3. Load Vocab
      final vocabData = await rootBundle.loadString('assets/ai/vocab.json');
      _vocab = Map<String, int>.from(jsonDecode(vocabData));

      // 4. Load Labels
      _hazardLabels = await _loadLabelList('assets/ai/labels_hazard.json');
      _elecLabels = await _loadLabelList('assets/ai/labels_elec.json');
      _levelLabels = await _loadLabelList('assets/ai/labels_level.json');

      _isLoaded = true;
      print("Web Classifier Loaded. Labels: H=${_hazardLabels.length}, E=${_elecLabels.length}, L=${_levelLabels.length}");
    } catch (e) {
      print("Error loading Web Classifier: $e");
    }
  }

  Future<List<String>> _loadLabelList(String path) async {
    try {
      String jsonString = await rootBundle.loadString(path);
      List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      print("Error loading label file $path: $e");
      return [];
    }
  }

  @override
  Future<Map<String, String>> predict(String text) async {
    if (!_isLoaded || _model == null) await loadModel();
    if (_model == null) return {};

    var inputTokens = _tokenize(text, 120);

    // Run inference
    // TFLite Web usually returns a list of outputs
    final output = _model!.predict<List<dynamic>>([inputTokens]);
    
    // Output Order based on training: [Hazard, Elec, Level]
    if (output.length >= 3) {
      return {
        "type": "Unsafe_Condition", // Default
        "hazard_kind": _getLabel(_hazardLabels, output[0] as List),
        "electrical_kind": _getLabel(_elecLabels, output[1] as List),
        "level": _getLabel(_levelLabels, output[2] as List)
      };
    }
    return {};
  }

  String _getLabel(List<String> labels, List<dynamic> probabilities) {
    if (labels.isEmpty) return "Unknown";
    int maxIndex = 0;
    double maxProb = -1.0;
    for (int i = 0; i < probabilities.length; i++) {
      double val = (probabilities[i] as num).toDouble();
      if (val > maxProb) {
        maxProb = val;
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