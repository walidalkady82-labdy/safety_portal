import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart'; 
import 'i_repo_hazard_classifier.dart';

class RepoHazardClassifierWeb with LogMixin implements IRepoHazardClassifier {
  TFLiteModel? _model;
  Map<String, int>? _vocab;
  
  final List<String> _typeLabels = ["Unsafe_Condition", "Unsafe_Behavior", "NM", "FA"]; 
  List<String> _hazardLabels = [];
  List<String> _elecLabels = [];
  List<String> _levelLabels = [];
  
  bool _isLoaded = false;
  static bool _isEngineInitialized = false; 

  @override List<String> get typeLabels => _typeLabels;
  @override List<String> get hazardLabels => _hazardLabels;
  @override List<String> get elecLabels => _elecLabels;
  @override List<String> get levelLabels => _levelLabels;
  @override bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      // 1. Diagnostics & Security Check
      //_checkSecurityHeaders();

      //2. Initialize the Engine
      if (!_isEngineInitialized) {
        logInfo("🌐 [Web AI] Initializing TFLite Engine...");
        try {
            await TFLiteWeb.initializeUsingCDN();
            _isEngineInitialized = true;
        } catch (e) {
            logError("⚠️ [Web AI] Engine Init Warning: $e");
        }
      }
      
      logInfo("🌐 [Web AI] Loading Classifier Model via Blob...");
      _model = await TFLiteModel.fromUrl(
          '/assets/ai/safety_model.tflite',
        );
            // 5. Load Metadata
      final vocabStr = await rootBundle.loadString('assets/ai/vocab.json');
      _vocab = Map<String, int>.from(jsonDecode(vocabStr));

      _hazardLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_hazard.json')));
      _elecLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_elec.json')));
      _levelLabels = List<String>.from(jsonDecode(await rootBundle.loadString('assets/ai/labels_level.json')));

      _isLoaded = true;
      logInfo("✅ [Web AI] Classifier Ready.");


    } catch (e) {
      logError("❌ [Web AI] Load Failed: $e");
      if (e.toString().contains('dlopen')) {
        logError("💡 [TROUBLESHOOTING] The 'dlopen' error means your server is missing security headers.");
        logError("   Ensure your firebase.json contains: require-corp and same-origin.");
      }
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
          "hazard_kind": _getLabel(_hazardLabels, output[0] as List),
          "electrical_kind": _getLabel(_elecLabels, output[1] as List),
          "level": _getLabel(_levelLabels, output[2] as List)
        };
      }
    } catch (e) { 
      logError("❌ [Web AI] Predict Error: $e"); 
    }
    return {};
  }

  String _getLabel(List<String> labels, List<dynamic> probs) {
    int idx = _argmax(probs);
    return (idx >= 0 && idx < labels.length) ? labels[idx] : "Unknown";
  }

  List<double> _tokenize(String text, int maxLen) {
    if (_vocab == null) return List.filled(maxLen, 0.0);
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    
    List<double> tokens = [];
    for (var word in words) {
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

  int _argmax(List<dynamic> list) {
    double maxVal = -double.infinity;
    int maxIdx = 0;
    for (int i = 0; i < list.length; i++) {
      double val = (list[i] as num).toDouble();
      if (val > maxVal) {
        maxVal = val;
        maxIdx = i;
      }
    }
    return maxIdx;
  }
}