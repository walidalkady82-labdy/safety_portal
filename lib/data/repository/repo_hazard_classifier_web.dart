import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart'; 
import 'i_repo_hazard_classifier.dart';
// ignore: avoid_web_libraries_in_flutter
// import 'dart:js_util' as js_util;

class RepoHazardClassifierWeb with LogMixin implements IRepoHazardClassifier {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  
  // Lists to hold loaded labels for the 6 outputs
  List<String> _typeLabels = [];
  List<String> _hazardLabels = [];
  List<String> _detailedLabels = [];
  List<String> _levelLabels = [];
  List<String> _actionLabels = [];
  List<String> _deptLabels = [];
  
  bool _isLoaded = false;
  static bool _wasmInitialized = false;

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
      logInfo("🌐 Web AI: Loading Safety Model Full...");
      
      if (!_wasmInitialized) {
        await TFLiteWeb.initializeUsingCDN();
        _wasmInitialized = true;
      }
      
      // 1. Load Model
      _model = await TFLiteModel.fromUrl('/assets/ai/safety_classifier_model.tflite');
      
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
      logInfo("✅ Web AI: Loaded Successfully");
    } catch (e) {
      logError("❌ Web AI Error: $e");
    }
  }
  
  @override
  Future<Map<String, String>> predict({required String line,required String area,required String text}) async {
    if (!_isLoaded) await loadModel();

    try {
      // 1. Prepare Input
      String combined = "$line $area $text".toLowerCase().replaceAll('nan', '').trim();
      var inputTokens = _tokenize(combined, 120);

      final inputTensor = Tensor(
        Float32List.fromList(inputTokens),
        shape: [1, 120],
        type: TFLiteDataType.float32,
      );

      final NamedTensorMap result = _model!.predict<NamedTensorMap>(inputTensor);
      final outResults =  {
        'type': _getBestLabel(result['StatefulPartitionedCall_1:0'], _typeLabels),
        'hazard': _getBestLabel(result['StatefulPartitionedCall_1:1'], _hazardLabels),
        'detailed': _getBestLabel(result['StatefulPartitionedCall_1:2'], _detailedLabels),
        'level': _getBestLabel(result['StatefulPartitionedCall_1:3'], _levelLabels),
        'action': _getBestLabel(result['StatefulPartitionedCall_1:4'], _actionLabels),
        'dept': _getBestLabel(result['StatefulPartitionedCall_1:5'], _deptLabels),
      };
      logInfo(
        "type: ${outResults['type']}\n"
        "hazard: ${outResults['hazard']}\n"
        "detailed: ${outResults['detailed']}\n"
        "level: ${outResults['level']}\n"
        "action: ${outResults['action']}\n"
        "dept: ${outResults['dept']}\n"
      );
      return outResults;
    }  
    catch (e) {
      logError("❌ Web AI Error: $e");
      return {};
    }
  }

  /// Helper to extract the label with the highest probability from a tensor
  String _getBestLabel(Tensor? tensor, List<String> labels) {
    if (tensor == null) return "Unknown";
    
    final List<double> probs = tensor.dataSync<Float32List>().toList();
    
    int maxIdx = 0;
    double maxVal = -1.0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }
    
    return (maxIdx < labels.length) ? labels[maxIdx] : "Unknown";
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
    while (tokens.length < maxLen) {
      tokens.add(0.0);
    }
    return tokens;
  }

  //Smart Action
  @override
  Future<List<Map<String, dynamic>>> predictTopActions(String line, String area, String text) async {
    if (!_isLoaded) await loadModel();

    // 1. PREPARE INPUT
    String combined = "$line $area $text".toLowerCase().replaceAll('nan', '').trim();
    var inputTokens = _tokenize(combined, 120);
    var inputTensor = Tensor(Float32List.fromList(inputTokens), shape: [1, 120], type: TFLiteDataType.float32);

    // 2. RUN INFERENCE
    // 'result' here is the "output"
    final dynamic result = _model!.predict<NamedTensorMap>(inputTensor);

    // 3. EXTRACT 'out_action'
    List<double> actionProbs = result['StatefulPartitionedCall_1:4'].dataSync<Float32List>().toList();
    
    if (actionProbs.isEmpty) return [];

    // 4. SORT & RETURN
    var indexed = List.generate(actionProbs.length, (i) => i);
    indexed.sort((a, b) => actionProbs[b].compareTo(actionProbs[a]));

    return indexed.take(3).map((i) => {
      'action': _actionLabels[i],
      'confidence': "${(actionProbs[i] * 100).toStringAsFixed(0)}%"
    }).toList();
  }
}