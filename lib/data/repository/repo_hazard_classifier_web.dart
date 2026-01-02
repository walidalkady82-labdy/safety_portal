import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart'; 
import 'i_repo_hazard_classifier.dart';
import 'dart:typed_data'; // Required for Float32List
import 'dart:js_util' as js; // Required to handle JS Objects/Tensors

class RepoHazardClassifierWeb implements IRepoHazardClassifier {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _model = await TFLiteModel.fromUrl('assets/assets/ai/safety_classifier_model.tflite?v=$timestamp');
      
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      _hazardLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_hazard.json')));
      _elecLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_elec.json')));
      _levelLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_level.json')));

      _isLoaded = true;
      print("Web AI: Safety Model Loaded (v=$timestamp)");
    } catch (e) {
      print("Web AI Error loading safety model: $e");
    }
  }

  @override
  Future<Map<String, String>> predict(String text) async {
    if (!_isLoaded) await loadModel();
    if (_model == null) return {};

    try {
      List<double> tokens = _tokenize(text, 120);
      final tensor = Tensor(
        Float32List.fromList(tokens),
        shape: [1, 120], 
        type: TFLiteDataType.float32,
      );

      final dynamic output = _model!.predict(tensor);
      if (output == null) return {};

      // Collect all Tensors found in the output
      List<List<double>> validOutputs = [];

      // Strategy 0: Output IS the Tensor (Direct Return - e.g. Single Head)
      if (js.hasProperty(output, 'dataSync')) {
         print("Web AI Hazard: Single Tensor detected.");
         validOutputs.add(_extractTensorData(output));
      } 
      // Strategy 1: Output is a List
      else if (output is List) {
        print("Web AI Hazard: List detected.");
        for (var item in output) {
          validOutputs.add(_extractTensorData(item));
        }
      } 
      // Strategy 2: JS Object (NamedTensorMap)
      else {
        try {
          final keys = js.objectKeys(output);
          print("Web AI Hazard Keys: $keys");

          if (keys is List) {
             // We sort keys to try and maintain deterministic order 
             List<String> sortedKeys = [];
             for (var k in keys) sortedKeys.add(k.toString());
             sortedKeys.sort();

             for (var key in sortedKeys) {
               final value = js.getProperty(output, key as Object);
               // Skip metadata/primitives
               if (value == null || value is bool || value is num || value is String) continue;

               if (js.hasProperty(value, 'dataSync')) {
                 validOutputs.add(_extractTensorData(value));
               }
             }
          }
        } catch (e) {
           print("Web AI Hazard Object parse error: $e");
        }
      }

      if (validOutputs.isEmpty) {
        print("Web AI: No valid tensors found in hazard output");
        return {};
      }

      print("Web AI Hazard: Found ${validOutputs.length} output tensors.");

      // Map outputs to labels based on count
      // Smart Heuristic: Match vector length to label list length
      List<double> hazardProbs = [];
      List<double> elecProbs = [];
      List<double> levelProbs = [];
      
      for (var out in validOutputs) {
        if (out.length == _hazardLabels.length) hazardProbs = out;
        else if (out.length == _elecLabels.length) elecProbs = out;
        else if (out.length == _levelLabels.length) levelProbs = out;
        // Fallback filling if lengths are ambiguous
        else if (hazardProbs.isEmpty) hazardProbs = out;
        else if (elecProbs.isEmpty) elecProbs = out;
        else if (levelProbs.isEmpty) levelProbs = out;
      }

      return {
        "type": "Unsafe_Condition",
        "hazard_kind": _getLabel(_hazardLabels, hazardProbs),
        "electrical_kind": _getLabel(_elecLabels, elecProbs),
        "level": _getLabel(_levelLabels, levelProbs)
      };

    } catch (e) {
      print("Web AI Prediction Error: $e");
      return {};
    }
  }

  String _getLabel(List<String> labels, List<double> probs) {
    if (probs.isEmpty || labels.isEmpty) return "Unknown";
    int idx = _argmax(probs);
    if (idx < labels.length) return labels[idx];
    return labels[0];
  }

  List<double> _extractTensorData(dynamic jsObject) {
    if (jsObject == null) return [];
    try {
      if (js.hasProperty(jsObject, 'dataSync')) {
         var data = js.callMethod(jsObject, 'dataSync', []);
         return List<dynamic>.from(data).map((e) => (e as num).toDouble()).toList();
      }
      if (jsObject is List) {
         return jsObject.map((e) => (e as num).toDouble()).toList();
      }
    } catch (e) {
      print("Tensor extraction error: $e");
    }
    return [];
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

  int _argmax(List<double> probs) {
    if (probs.isEmpty) return 0;
    double maxVal = -1.0;
    int maxIdx = 0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }
}