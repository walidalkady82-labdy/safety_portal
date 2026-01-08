import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_web/tflite_web.dart';
import 'i_repo_hazard_classifier.dart';

class RepoHazardClassifierMobile implements IRepoHazardClassifier {
  Interpreter? _interpreter;
  Map<String, int>? _vocab;
  
  // Lists to hold loaded labels for the 6 outputs
  List<String> _typeLabels = [];
  List<String> _hazardLabels = [];
  List<String> _detailedLabels = [];
  List<String> _levelLabels = [];
  List<String> _actionLabels = [];
  List<String> _deptLabels = [];
  
  bool _isLoaded = false;

  // Getters required by the interface
  @override List<String> get typeLabels => _typeLabels;
  @override List<String> get hazardLabels => _hazardLabels;
  @override List<String> get detailedLabels => _detailedLabels;
  @override List<String> get levelLabels => _levelLabels;
  @override List<String> get actionLabels => _actionLabels;
  @override List<String> get deptLabels => _deptLabels;
  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      print("📱 Mobile AI: Loading Safety Model Full...");
      // 1. Load the new 6-head model
      TFLiteWeb.initializeUsingCDN();
      _interpreter = await Interpreter.fromAsset('assets/ai/safety_model_full.tflite');
      
      // 2. Load Vocab
      _vocab = Map<String, int>.from(jsonDecode(await rootBundle.loadString('assets/ai/vocab.json')));
      
      // 3. Load all 6 Label JSON files
      _typeLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_type.json')));
      _hazardLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_hazard.json')));
      _detailedLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_detailed_kind.json')));
      _levelLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_level.json')));
      _actionLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_action.json')));
      _deptLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_dept.json')));

      _isLoaded = true;
      print("✅ Mobile AI: Loaded Successfully");
    } catch (e) {
      print("❌ Mobile AI Error: $e");
    }
  }

  @override
Future<Map<String, String>> predict({required String line,required String area,required String text}) async {
  if (!_isLoaded) await loadModel();

  // 1. MATCH THE PYTHON CLEANING LOGIC
  String cleanLine = line.toLowerCase().replaceAll('nan', '').replaceAll('_', ' ').trim();
  String cleanArea = area.toLowerCase().replaceAll('nan', '').replaceAll('_', ' ').trim();
  String cleanText = text.toLowerCase().replaceAll('nan', '').trim();
  
  // Join only non-empty parts
  String combined = [cleanLine, cleanArea, cleanText]
      .where((s) => s.isNotEmpty)
      .join(" ");

  var input = [_tokenize(combined, 120)];

  // 2. UPDATED OUTPUT SHAPES (Match your specific labels count)
  var outType = [List<double>.filled(4, 0)];
  var outHazard = [List<double>.filled(38, 0)];   // Updated to 38
  var outDetailed = [List<double>.filled(16, 0)]; 
  var outLevel = [List<double>.filled(3, 0)];
  var outAction = [List<double>.filled(76, 0)]; 
  var outDept = [List<double>.filled(10, 0)];

  // 3. RUN MULTI-OUTPUT INFERENCE
  _interpreter!.runForMultipleInputs([input], {
    0: outType,
    1: outHazard,
    2: outDetailed,
    3: outLevel,
    4: outAction,
    5: outDept,
  });

  return {
    "type": _typeLabels[_argmax(outType[0])],
    "hazard_kind": _hazardLabels[_argmax(outHazard[0])],
    "detailed_kind": _detailedLabels[_argmax(outDetailed[0])],
    "level": _levelLabels[_argmax(outLevel[0])],
    "action": _actionLabels[_argmax(outAction[0])],
    "respDepartment": _deptLabels[_argmax(outDept[0])],
  };
}

List<double> _tokenize(String text, int maxLen) {
  if (_vocab == null) return List.filled(maxLen, 0.0);
  List<String> words = text.split(RegExp(r'\s+'));
  List<double> tokens = List.filled(maxLen, 0.0);
  
  for (int i = 0; i < words.length && i < maxLen; i++) {
    int index = _vocab![words[i]] ?? _vocab!['<OOV>'] ?? 1;
    // CRITICAL: Clamp to 10k to prevent "Gather index out of bounds"
    if (index >= 10000) index = 1; 
    tokens[i] = index.toDouble();
  }
  return tokens;
}

  int _argmax(List<dynamic> probs) {
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

  //Smart Action
  @override
  Future<List<Map<String, dynamic>>> predictTopActions(String line, String area, String text) async {
    if (!_isLoaded) await loadModel();

    // 1. PREPARE INPUT (Same logic as predict)
    String cleanLine = line.toLowerCase().replaceAll('nan', '').replaceAll('_', ' ').trim();
    String cleanArea = area.toLowerCase().replaceAll('nan', '').replaceAll('_', ' ').trim();
    String cleanText = text.toLowerCase().replaceAll('nan', '').trim();
    String combined = [cleanLine, cleanArea, cleanText].where((s) => s.isNotEmpty).join(" ");
    
    var input = [_tokenize(combined, 120)];

    // 2. DEFINE 'OUTPUT'
    // We create a map of empty buffers for all 6 heads.
    // Head #4 is 'out_action' (size 76).
    var output = {
      0: [List<double>.filled(4, 0)],   // type
      1: [List<double>.filled(38, 0)],  // hazard
      2: [List<double>.filled(16, 0)],  // detailed
      3: [List<double>.filled(3, 0)],   // level
      4: [List<double>.filled(76, 0)],  // action <--- THIS IS WHAT WE NEED
      5: [List<double>.filled(10, 0)],  // dept
    };

    // 3. RUN INFERENCE
    _interpreter!.runForMultipleInputs([input], output);

    // 4. PROCESS RESULTS
    // Now 'output' is filled with data. We grab index 4.
    var actionProbs = output[4]![0] as List<double>;

    // Sort and take Top 3
    var indexed = List.generate(actionProbs.length, (i) => i);
    indexed.sort((a, b) => actionProbs[b].compareTo(actionProbs[a]));

    return indexed.take(3).map((i) => {
      'action': _actionLabels[i],
      'confidence': "${(actionProbs[i] * 100).toStringAsFixed(0)}%"
    }).toList();
  }
}