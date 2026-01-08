import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart';

import 'i_repo_forecaster.dart';

class RepoForecasterWeb with LogMixin implements IRepoForecaster {
  TFLiteModel? _model;
  List<String> _areas = [];  
  bool _isLoaded = false;
  static bool _wasmInitialized = false;

  @override
  bool get isLoaded => _isLoaded;
  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      // 1. Initialize WASM Runtime
      if (!_wasmInitialized) {
        await TFLiteWeb.initializeUsingCDN();
        _wasmInitialized = true;
      }

      // 2. Load Model & Assets
      _model = await TFLiteModel.fromUrl('/assets/ai/safety_forecaster.tflite');
      String jsonString = await rootBundle.loadString('assets/ai/area_map.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _areas = jsonMap.keys.toList();

      _isLoaded = true;
      logInfo("✅ Web AI: Forecaster Loaded for ${_areas.length} areas");
    } catch (e) {
      logError("❌ Web AI Forecaster Error: $e");
    }
  }

  /// Input: List of counts for the last 4 weeks.
  /// Structure: [ [Week1_Area1, Week1_Area2...], [Week2_Area1...], ... ]
  /// Size: Must be [4] lists, each containing [N] counts (where N = areas.length)
  @override
  Future<Map<String, double>> predictNextWeek(List<List<double>> last4Weeks) async {
    if (!_isLoaded || _model == null) await loadModel();

    try {
      int numAreas = _areas.length;

      // 1. Validation
      if (last4Weeks.length != 4) {
        logWarning("⚠️ Forecaster: Expected 4 weeks of data, got ${last4Weeks.length}");
        return {};
      }

      // 2. Flatten Data for Tensor Buffer
      // We need a flat Float32List, but the Tensor Shape will define the structure [1, 4, N]
      List<double> flatData = [];
      for (var week in last4Weeks) {
        if (week.length != numAreas) {
           // Pad with 0s if area counts don't match (safety check)
           var padded = List<double>.from(week);
           while(padded.length < numAreas) padded.add(0.0);
           flatData.addAll(padded);
        } else {
           flatData.addAll(week);
        }
      }

      // 3. Create Tensor
      final inputBuffer = Float32List.fromList(flatData);
      final inputTensor = Tensor(
        inputBuffer, 
        shape: [1, 4, numAreas], // [Batch, Window, Features]
        type: TFLiteDataType.float32
      );

      // 4. Run Inference
      final vectorTensor =_model!.predict<Tensor>(inputTensor);

      List<double> vector = vectorTensor.dataSync<Float32List>().toList();
      

      // 6. Map to Area Names
      if (vector.isNotEmpty) {
        Map<String, double> risks = {};
        for (int i = 0; i < numAreas && i < vector.length; i++) {
          // Clip negatives to 0
          double val = vector[i];
          risks[_areas[i]] = val < 0 ? 0.0 : val;
        }
        return risks;
      }

    } catch (e) {
      logError("⚠️ Web Forecaster Prediction Error: $e");
    }

    return {};
  }
}