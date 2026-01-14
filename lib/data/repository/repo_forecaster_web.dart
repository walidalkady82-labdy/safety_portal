import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_web/tflite_web.dart';

import 'i_repo_forecaster.dart';

class RepoForecasterWeb with LogMixin implements IRepoForecaster {
  TFLiteModel? _interpreter;
  Map<String, dynamic> _metadata = {};
  List<String> _areaMap = [];
  List<double> _minValues = [];
  List<double> _maxValues = [];  
  bool _isLoaded = false;
  static bool _wasmInitialized = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  List<String> get areas => _areaMap;

  @override
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      // 1. Initialize WASM Runtime
      if (!_wasmInitialized) {
        await TFLiteWeb.initializeUsingCDN();
        _wasmInitialized = true;
      }
      // 1. Load the TFLite Model
      _interpreter = await TFLiteModel.fromUrl('assets/assets/ai/safety_forecaster_model.tflite');
      // 2. Load the Scaling Metadata
      final String metadataString = await rootBundle.loadString('assets/ai/safety_forecaster_metadata.json');
      _metadata = json.decode(metadataString);
      _areaMap = List<String>.from(_metadata["areas"]);
      _minValues = List<double>.from(_metadata["min"]);
      _maxValues = List<double>.from(_metadata["max"]);
      _isLoaded = true;
      logInfo("✅ Web AI: Forecaster Loaded for ${_areaMap.length} areas");
    } catch (e) {
      logError("❌ Web AI Forecaster Error: $e");
    }
  }

  
  Future<Map<String, double>> predict1(List<List<double>> last4Weeks) async {
    if (!_isLoaded || _interpreter == null) await loadModel();

    try {
      int numAreas = _areaMap.length;
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
          while(padded.length < numAreas) {
            padded.add(0.0);
          }
          flatData.addAll(padded);
        } else {
            flatData.addAll(week);
        }
      }

      // 3. Create Tensor
      final inputBuffer = Float32List.fromList(flatData);
      // Prepare Input (Shape: [1, 4, 56])
      final inputTensor = Tensor(
        inputBuffer, 
        shape: [1, 4, numAreas], // [Batch, Window, Features]
        type: TFLiteDataType.float32
      );

      // 4. Run Inference
      final vectorTensor =_interpreter!.predict<Tensor>(inputTensor);

      List<double> vector = vectorTensor.dataSync<Float32List>().toList();
      

      // 5. Map to Area Names
      if (vector.isNotEmpty) {
        Map<String, double> risks = {};
        for (int i = 0; i < numAreas && i < vector.length; i++) {
          // Clip negatives to 0
          double val = vector[i];
          risks[_areaMap[i]] = val < 0 ? 0.0 : val;
        }
        return risks;
      }

    } catch (e) {
      logError("⚠️ Web Forecaster Prediction Error: $e");
    }

    return {};
  }
  /// Multi-step Trend Prediction using TFLite Web Tensors
  @override
  Future<Map<String, List<double>>> predict(List<List<double>> historyMatrix) async {
    if (_interpreter == null) return {};

    int numAreas = _areaMap.length;
    int windowSize =8;
    int predictSteps = 4;

    // 1. Create TENSOR for input
    // The scale function now returns an actual tflite_web.Tensor object
    final inputTensor = _createInputTensor(historyMatrix, windowSize, numAreas);

    // 2. Run Inference
    // Predict returns a NamedTensorMap (or a Tensor if single output)
    final result = _interpreter!.predict<Tensor>(inputTensor);

    // Assuming the output node is named 'Identity' or the first key in the map
    final outputTensor = result;
    final List<double> flatOutput = outputTensor.dataSync<List<double>>();

    // 3. Post-process: Map and Unscale
    Map<String, List<double>> finalTrends = {};
    
    for (int a = 0; a < numAreas; a++) {
      String areaName = _areaMap[a];
      List<double> areaTrajectory = [];
      
      for (int w = 0; w < predictSteps; w++) {
        // Output indexing for flattened [week * numAreas + area]
        double scaledVal = flatOutput[w * numAreas + a];
        double actualVal = (scaledVal * (_maxValues[a] - _minValues[a])) + _minValues[a];
        areaTrajectory.add(math.max(0.0, actualVal));
      }
      finalTrends[areaName] = areaTrajectory;
    }

    return finalTrends;
  }

  /// Compliance: Creates tflite_web Tensor object
  Tensor _createInputTensor(List<List<double>> matrix, int window, int areas) {
    final Float32List buffer = Float32List(window * areas);

    for (int w = 0; w < window; w++) {
      for (int a = 0; a < areas; a++) {
        double min = _minValues[a];
        double max = _maxValues[a];
        double rawValue = matrix[w][a];
        
        // Scale to 0.0 - 1.0
        double scaled = (max - min == 0) ? 0.0 : (rawValue - min) / (max - min);
        buffer[w * areas + a] = scaled;
      }
    }

    // Return the specific Tensor class required by tflite_web
    return Tensor(
      buffer,
      shape: [1, window, areas],
      type: TFLiteDataType.float32,
    );
  }
}



// // Example usage in a Flutter Widget
// void getPredictions() {
//   // Mock data representing 4 weeks of history for 56 areas
//   List<List<double>> history = List.generate(4, (_) => List.filled(56, 0.0));
  
//   // Fill in some recent spikes to see the model react
//   history[3][0] = 20.0; // Area 1 had 20 incidents last week

//   var results = forecaster.runInference(history);
  
//   results.forEach((area, risk) {
//     if (risk > 1.0) {
//        print("⚠️ High Risk Warning: $area expects ${risk.toStringAsFixed(1)} incidents");
//     }
//   });
// }