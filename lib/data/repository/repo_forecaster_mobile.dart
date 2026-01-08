import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'i_repo_forecaster.dart';

class RepoForecasterMobile with LogMixin implements IRepoForecaster{
  Interpreter? _interpreter;
  List<String> _areas = [];
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ai/safety_forecaster.tflite');
      String jsonString = await rootBundle.loadString('assets/ai/area_map.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _areas = jsonMap.keys.toList();
      _isLoaded = true;
    } catch (e) {
      logError("Error loading forecaster: $e");
    }
  }

  // Input: List of counts for the last 4 weeks. 
  // Example: [ [2,0,1], [0,0,1], [3,1,0], [1,0,0] ]
  // (Must match the number of areas in area_map.json)
  @override
  Future<Map<String, double>> predictNextWeek(List<List<double>> last4Weeks) async{
    if (!_isLoaded) return {};

    // 1. Prepare Input: [1, 4, Num_Areas]
    var input = [last4Weeks]; 
    
    // 2. Prepare Output: [1, Num_Areas]
    var output = List.filled(1 * _areas.length, 0.0).reshape([1, _areas.length]);

    // 3. Run
    _interpreter!.run(input, output);

    // 4. Map results to Area Names
    List<double> predictions = List<double>.from(output[0]);
    Map<String, double> risks = {};
    
    for (int i = 0; i < _areas.length; i++) {
      // If prediction is negative (math artifact), clip to 0
      double risk = predictions[i] < 0 ? 0 : predictions[i];
      risks[_areas[i]] = risk;
    }
    
    return risks;
  }
}