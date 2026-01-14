import 'dart:convert';
import 'dart:math' as math show max;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'i_repo_forecaster.dart';

class RepoForecasterMobile with LogMixin implements IRepoForecaster{
  Interpreter? _interpreter;
  List<String> _areaMap = [];
  List<double> _minValues = [];
  List<double> _maxValues = [];
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  List<String> get areas => _areaMap;

  @override
  Future<void> loadModel() async {
    try {
      // 1. Load the TFLite Model
      _interpreter = await Interpreter.fromAsset('assets/ai/safety_forecaster_model.tflite');
      // 2. Load the Scaling Metadata
      final String metadataString = await rootBundle.loadString('assets/ai/safety_forecaster_metadata.json');
      final Map<String, dynamic> metadata = json.decode(metadataString);

      _areaMap = List<String>.from(metadata['areas']);
      _minValues = List<double>.from(metadata['min']);
      _maxValues = List<double>.from(metadata['scale']);
      _isLoaded = true;
    } catch (e) {
      logError("Error loading forecaster: $e");
    }
  }

  // Input: List of counts for the last 4 weeks. 
  // Example: [ [2,0,1], [0,0,1], [3,1,0], [1,0,0] ]
  // (Must match the number of areas in area_map.json)
  /// Takes last 4 weeks of raw incident counts [4][56]
  /// Returns a Map of Area Names and Predicted Incidents

  Future<Map<String, double>> predict1(List<List<double>> last4Weeks) async{
    if (!_isLoaded) {
      logInfo("Forecaster model not loaded in predict, returning empty risks.");
      return {};
    }
    logInfo("Input matrix to forecaster: $last4Weeks"); // Log input to model

    // 1. Prepare Input: [1, 4, Num_Areas]
    var input = [last4Weeks]; 
    
    // 2. Prepare Output: [1, Num_Areas]
    var output = List.filled(1 * _areaMap.length, 0.0).reshape([1, _areaMap.length]);

    // 3. Run
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      logError("Error running forecaster interpreter: $e");
      return {};
    }
    
    logInfo("Raw output from forecaster interpreter: $output"); // Log raw output

    // 4. Map results to Area Names
    List<double> predictions = List<double>.from(output[0]);
    Map<String, double> risks = {};
    
    for (int i = 0; i < _areaMap.length; i++) {
      // If prediction is negative (math artifact), clip to 0
      double risk = predictions[i] < 0 ? 0 : predictions[i];
      risks[_areaMap[i]] = risk;
    }
    logInfo("Processed risks before return: $risks"); // Log processed risks
    
    return risks;
  }

  @override
  /// Predicts 4-week trajectory for ALL areas
  /// Output: Map<AreaName, List<4WeeksValue>>
  Future<Map<String, List<double>>> predict(List<List<double>> historyMatrix)  async{
    if (_interpreter == null) return {};

    int numAreas = _areaMap.length;
    int windowSize = 8;
    int predictSteps = 4;

    // 1. COMPLIANCE: Prepare TENSOR input
    // TFLite Web runners require typed data to interface with WASM correctly.
    final inputTensor = _scaleInputToTensor(historyMatrix);
    
    // Reshape for the interpreter: [Batch, Window, Areas]
    final input = inputTensor.reshape([1, windowSize, numAreas]);

    // 2. Prepare TENSOR output buffer
    final output = List.generate(
      1, 
      (i) => List.generate(
        predictSteps, 
        (j) => List.generate(numAreas, (k) => 0.0)
      )
    );

    // Run inference (Synchronous on Web via WASM)
    _interpreter!.run(input, output);

    // 3. Post-process: Map and Unscale
    Map<String, List<double>> finalTrends = {};
    for (int a = 0; a < numAreas; a++) {
      String areaName = _areaMap[a];
      List<double> areaTrajectory = [];
      
      for (int w = 0; w < predictSteps; w++) {
        double scaledVal = output[0][w][a];
        double actualVal = (scaledVal * (_maxValues[a] - _minValues[a])) + _minValues[a];
        areaTrajectory.add(math.max(0.0, actualVal));
      }
      finalTrends[areaName] = areaTrajectory;
    }

    return finalTrends;
  }

  /// Converts raw history to a Flattened Tensor (Float32List)
  Float32List _scaleInputToTensor(List<List<double>> matrix) {
    int numAreas = _areaMap.length;
    int windowSize = 8;
    
    // Create a flat Float32List to be used as a Tensor
    final Float32List tensor = Float32List(windowSize * numAreas);

    for (int w = 0; w < windowSize; w++) {
      for (int a = 0; a < numAreas; a++) {
        double min = _minValues[a];
        double max = _maxValues[a];
        double rawValue = matrix[w][a];
        
        // Min-Max Normalization
        double scaled = (max - min == 0) ? 0.0 : (rawValue - min) / (max - min);
        
        // Flattened index for [week * numAreas + area]
        tensor[w * numAreas + a] = scaled;
      }
    }
    return tensor;
  }

}