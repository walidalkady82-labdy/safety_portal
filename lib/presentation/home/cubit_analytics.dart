import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/data/service/service_analytics.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/locator.dart';

class StateAnalytics {
  final bool isLoading;
  final Map<String, List<double>> risksTrend;
  final Map<String, double> risksCombined;
    final Map<String, dynamic> areaMetrics;
  final List<double> history; // Historical volume for trend line
  final String windowLabel;
  final int signalCount;

  StateAnalytics({
    this.isLoading = false,
    this.risksTrend = const {},
    this.risksCombined = const {},
    this.areaMetrics = const {"reports":[],"riskScore":0 , "status": "Stable"},
    this.history = const [0, 0, 0, 0],
    this.windowLabel = "Scanning...",
    this.signalCount = 0,
  });

  StateAnalytics copyWith({
    bool? isLoading,
    Map<String, List<double>>? risksTrend,
    Map<String, double>? risksCombined,
    Map<String, dynamic>? areaMetrics,
    List<double>? history,
    String? windowLabel,
    int? signalCount,
  }) {
    return StateAnalytics(
      isLoading: isLoading ?? this.isLoading,
      risksTrend: risksTrend ?? this.risksTrend,
      risksCombined: risksCombined ?? this.risksCombined,
      areaMetrics: areaMetrics ?? this.areaMetrics,
      history: history ?? this.history,
      windowLabel: windowLabel ?? this.windowLabel,
      signalCount: signalCount ?? this.signalCount,
    );
  }
}

class CubitAnalytics extends Cubit<StateAnalytics> with LogMixin {
  final _ai = sl<ServiceAI>();
  final _atr = sl<AtrService>();
  final _analytics = sl<ServiceAnalytics>();

  CubitAnalytics() : super(StateAnalytics()) {
    loadForecast();
  }

  Future<void> loadForecast() async {
    emit(state.copyWith(isLoading: true));
    try {
      // ✅ FETCHING 3000: 
      // Required to see deep into the 16,000+ records for historical trends.
      final reports = await _atr.getAtrs(limit: 3000); 
      
      final result = await _ai.predictAdaptive(reports);

      emit(state.copyWith(
        isLoading: false,
        risksTrend: result.risks,
        risksCombined: calculateAreaRisks(result.risks),
        history: result.bucketSums,
        windowLabel: result.windowLabel,
        signalCount: result.totalSignals,
      ));
    } catch (e) {
      logError("Forecast Load Error: $e");
      emit(state.copyWith(isLoading: false, risksTrend: {}, history: []));
    }
  }

    /// Calculates risk based on the total predicted incidents over the 4-week span
  Map<String, double> calculateAreaRisks(Map<String, List<double>> trends) {
    Map<String, double> risks = {};
    
    trends.forEach((area, trajectory) {
      // Risk = Sum of predicted incidents in the next 4 weeks
      double totalPredictedIncidents = trajectory.reduce((a, b) => a + b);
      risks[area] = totalPredictedIncidents;
    });
    
    return risks;
  }

  void getAreaMetrics(String selectedArea){
      _atr.getAtrsByArea(selectedArea).then((reports) {
        emit(state.copyWith(
          isLoading: false,
          areaMetrics: _analytics.getAreaMetrics(selectedArea, reports)
          ));
      }).catchError((e) {
        logError("Forecast Load Error: $e");
      });
  }

  String getHighRiskArea(){
    final sortedEntries = state.risksCombined.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.isNotEmpty) {
      return sortedEntries.first.key;
    }else{
      return "None";
    }
  }
}