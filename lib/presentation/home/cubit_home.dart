import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/model/model_analitcs_summery.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/data/service/service_analytics.dart';
import 'package:safety_portal/data/service/service_storage.dart';
import 'package:safety_portal/locator.dart';


class HomeState {
  final bool isLoading;
  final int currentIndex;
  final ModelAnalyticsSummary? analytics;
  final List<ModelAtr> recentReports;
  final String? error;
  final String? selectedArea;

  HomeState({
    this.isLoading = true,
    this.currentIndex =0,
    this.analytics,
    this.recentReports = const [],
    this.error,
    this.selectedArea
  });

  HomeState copyWith({
    bool? isLoading,
    int? currentIndex,
    ModelAnalyticsSummary? analytics,
    List<ModelAtr>? recentReports,
    String? error,
    String? selectedArea,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      currentIndex: currentIndex ?? this.currentIndex,
      analytics: analytics ?? this.analytics,
      recentReports: recentReports ?? this.recentReports,
      error: error,
      selectedArea: selectedArea ?? this.selectedArea,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final ServiceAnalytics _analyticsService = sl<ServiceAnalytics>();
  final AtrService _atrService = sl<AtrService>();
  StreamSubscription? _atrSubscription;
    final List<String> areas = ["External quarries",
"Quarry",
"Lime stone crusher",
"Samares Workshop",
"Coal storage",
"Clay crusher",
"Pre blending area",
"Raw mill",
"RDF",
"Preheater/Kiln",
"Bypass",
"Ammonia tank",
"Coal mill",
"DSS",
"Palamatic",
"Used oil tanks",
"Daily mazzot tank",
"Cooler",
"Cement mills",
"Gypsum crusher",
"Silos",
"Packing",
"Main mazzot tank",
"Electric stations",
"Electrical Tunnel",
"Utilities",
"Water Stations",
"Diesel Generator",
"Fuel station",
"Mechanical workshop ",
"Electrical workshop",
"Mobile Equp.",
"Isolation Room",
"Clinic&Ambulance",
"Labs",
"CCR Building",
"Warehouse",
"Admin Building",
"Medical Admin",
"Technical Building",
"Containers",
"Mosque",
"Warehouse",
"Site",
"Other",
"Overhead cranes",
"co2 tank",
"emergency room",
"Safety  shower",
"Jupiter protection tools",
"Emergency doors",
"Foma machine",
"fire fighting equipment",
"Bathrooms",
"Lifting tools",
"Containers inspection."
];
  
  HomeCubit() : super(HomeState()) {
    init();
  }

  void init() {
    emit(state.copyWith(isLoading: true));
    
    _atrSubscription = _atrService.getAtrStream(limit: 50).listen(
      (reports) async {
        try {
          final summary = await _analyticsService.getUnifiedAnalytics(limit: 100);
          emit(state.copyWith(
            isLoading: false,
            recentReports: reports,
            analytics: summary,
          ));
        } catch (e) {
          emit(state.copyWith(isLoading: false, error: e.toString()));
        }
      },
      onError: (e) => emit(state.copyWith(isLoading: false, error: e.toString())),
    );
    
    // _analyticsService.getLeaderboard().then((leaderboard) {
    //   emit(state.copyWith(leaderboard: leaderboard));
    // }).catchError((e) {
    //   emit(state.copyWith(error: e.toString()));
    // });
  }

  void updateIndex(int index) => emit(state.copyWith(currentIndex: index));

  void updateselectedArea(String area) => emit(state.copyWith(selectedArea: area));

  @override
  Future<void> close() {
    _atrSubscription?.cancel();
    return super.close();
  }
}
