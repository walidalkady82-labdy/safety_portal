import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/data/service/service_storage.dart';
import 'package:safety_portal/locator.dart';

enum IssueFormState{inital ,isEditing, isSubmitting , failure , success}


class ReportState {
  final double quality;
  final List<String> interventions;
  final String? smartSolution;
  
  // Atr fields
  final String? line;
  final String? area;
  final String? observation;
  final String? action;
  final String? type;
  final String? hazardKind;
  final String? detailedKind;
  
  // Predicted Fields (Silently Populated)
  final String? selectedRisk;
  final String? selectedAction;       
  final String? selectedType;         
  final String? selectedHazardKind;   
  final String? selectedDetailedKind; 
  final String? selectedLevel;
  final String? selectedRespDept;
  final String? responsiblePerson;
  final List<double>? currentVector;

  final IssueFormState issueFormState; 
  final bool isDuplicateSuspect;
  final String? duplicateWarning;
  final bool isImageAnalyzing;
  final String? error;
  final XFile? selectedImage;

  ReportState({
    this.quality = 0.0, 
    this.interventions = const [], 
    this.smartSolution,
    this.line,
    this.area,
    this.observation,
    this.action,
    this.type,
    this.hazardKind,
    this.detailedKind,
    this.selectedRespDept,
    this.selectedRisk,
    this.selectedAction,
    this.selectedType,
    this.selectedHazardKind,
    this.selectedDetailedKind,
    this.selectedLevel,
    this.responsiblePerson,
    this.currentVector = const [],
    this.issueFormState = IssueFormState.inital, 
    this.isDuplicateSuspect = false, 
    this.duplicateWarning,
    this.isImageAnalyzing = false,
    this.error,
    this.selectedImage,
  });

  ReportState copyWith({
    double? quality,
    List<String>? interventions,
    String? smartSolution,
    String? line,
    String? area,
    String? observation,
    String? action,
    String? type,
    String? hazardKind,
    String? detailedKind,
    String? selectedRespDept,
    String? selectedRisk,
    String? selectedAction,
    String? selectedType,
    String? selectedHazardKind,
    String? selectedDetailedKind,
    String? selectedLevel,
    String? responsiblePerson,
    List<double>? currentVector,
    IssueFormState? issueFormState,
    bool? isDuplicateSuspect,
    String? duplicateWarning,
    bool? isImageAnalyzing,
    String? error,
    XFile? selectedImage,
  }) {
    return ReportState(
      quality: quality ?? this.quality,
      interventions: interventions ?? this.interventions,
      smartSolution: smartSolution ?? this.smartSolution,
      line: line ?? this.line,
      area: area ?? this.area,
      observation: observation ?? this.observation,
      action: action ?? this.action,
      type: type ?? this.type,
      hazardKind: hazardKind ?? this.hazardKind,
      detailedKind: detailedKind ?? this.detailedKind,
      selectedRespDept: selectedRespDept ?? this.selectedRespDept,
      selectedRisk: selectedRisk ?? this.selectedRisk,
      selectedAction: selectedAction ?? this.selectedAction,
      selectedType: selectedType ?? this.selectedType,
      selectedHazardKind: selectedHazardKind ?? this.selectedHazardKind,
      selectedDetailedKind: selectedDetailedKind ?? this.selectedDetailedKind,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      currentVector: currentVector ?? this.currentVector,
      issueFormState: issueFormState ?? this.issueFormState,
      isDuplicateSuspect: isDuplicateSuspect ?? this.isDuplicateSuspect,
      duplicateWarning: duplicateWarning ?? this.duplicateWarning,
      isImageAnalyzing: isImageAnalyzing ?? this.isImageAnalyzing,
      error: error,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }
}

class ReportCubit extends Cubit<ReportState> with LogMixin{
  final ServiceAI _ai = sl<ServiceAI>();
  final AtrService _atrService = sl<AtrService>();
  final ServiceStorage _storage = sl<ServiceStorage>(); 
  final ImagePicker _picker = ImagePicker();
  final List<String> lines = ["1" , "2", "1&2" , "Non-Process"];
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
  final List<String> departments = ["Plant_Manag",
  "Safety",
  "Environment",
  "Production",
  "Mechanical",
  "Electrical",
  "PM",
  "Quality",
  "Stores",
  "HR",
  "Dispatch",
  "Purchasing ",
  "Security",
  "Finance",
  "Legal",
  "Contractor.",
  ];
  // reportform   
  Timer? _debounce;

  ReportCubit() : super(ReportState());

  void updateLine(String val) => emit(state.copyWith(line: val));
  void updateArea(String val) => emit(state.copyWith(area: val));
  void updateObservation(String val) {
    emit(state.copyWith(observation: val));

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      if (val.isNotEmpty && (state.area != null && val.length > 5)) {
        await analyzeText(val);
      }
    });

  }
  void updateAction(String val) => emit(state.copyWith(action: val));
  void updateType(String val) => emit(state.copyWith(type: val));
  void updateHazardKind(String val) => emit(state.copyWith(hazardKind: val));
  void updateDetailedKind(String val) => emit(state.copyWith(detailedKind: val));

  void updateResponsibleDepartment(String val) => emit(state.copyWith(selectedRespDept: val));
  void updateResponsiblePerson(String val) => emit(state.copyWith(responsiblePerson: val));
  void updateRisk(String val) => emit(state.copyWith(selectedRisk: val));
  void updateQuality(double val) => emit(state.copyWith(quality: val));
  void updateImage(XFile? val) => emit(state.copyWith(selectedImage: val));
  void updateSmartSolution(String? val) => emit(state.copyWith(smartSolution: val));


  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
      if (image != null) {
        emit(state.copyWith(selectedImage: image));
        _analyzeImageContent(image);
      }
    } catch (e) {
      logError("Error picking image: $e");
      emit(state.copyWith(error: "Failed to pick image"));
      Future.delayed(const Duration(seconds: 1), () =>{ 
        emit(state.copyWith(error: null , )),

      });
    }
  }

  Future<void> _analyzeImageContent(XFile image) async {
    emit(state.copyWith(isImageAnalyzing: true));
    try {
      final detection = await _ai.analyzeImage(image);
      if (detection != null) {
        // We keep image detections as explicit interventions because they often add new information
        final updatedInterventions = List<String>.from(state.interventions)..insert(0, "📸 AI Detected: $detection");
        emit(state.copyWith(isImageAnalyzing: false, interventions: updatedInterventions));
      } else {
        emit(state.copyWith(isImageAnalyzing: false));
      }
    }
    catch (e) {
      logError("Error picking image: $e");
      emit(state.copyWith(error: "Failed to pick image"));
      Future.delayed(const Duration(seconds: 1), () =>{ 
        emit(state.copyWith(error: null , isImageAnalyzing: false)),
      });
    }
  }

  void clearImage() {
    emit(state.copyWith(selectedImage: null));
  }
  
  Future<void> analyzeText(String text) async {
    if (text.length < 5) {
      // Clear predictions if text is too short or cleared
      emit(state.copyWith(
        quality: 0.0, 
        isDuplicateSuspect: false, 
        smartSolution: null,
        selectedRespDept: null,
        selectedRisk: null,
        selectedAction: null,
        selectedType: null,
        selectedHazardKind: null,
        selectedDetailedKind: null,
        selectedLevel: null,
        currentVector: null,
      ));
      return;
    }
    
    try {
      // 1. ai aiResults["embedding"]  aiResults["classification"] 
      final aiResults = await _ai.analyzeFull(
        text,
        line:state.line??"", 
        area:state.area??"", 
        
        ); 
      final aiClassification = aiResults['classification'] as Map<String, String>; 
      if(aiClassification.isNotEmpty) {
        emit(state.copyWith(
        selectedRisk: aiClassification['level'],
        selectedRespDept: aiClassification['dept'],
        selectedType: aiClassification['type'],
        selectedHazardKind: aiClassification['hazard'],
        selectedDetailedKind: aiClassification['detailed'],
        selectedLevel: aiClassification['level'],
      ));
      }
      final aiEmbedding = aiResults["embedding"] as List<double>?;
      if(aiEmbedding != null && aiEmbedding.isNotEmpty) {
        emit(state.copyWith(
        currentVector: aiEmbedding,
      ));
      final res = await checkForDuplicate();
      if(res != null) {
        logInfo("${res['similarity']}");
        emit(state.copyWith(
          isDuplicateSuspect: true,
          duplicateWarning: "similar issue was reported \n ${res['atr'].observation} \n  confidence:${(res['similarity'] * 100).toStringAsFixed(2)}%"
          ));
      }
      }
      
    } catch (e) {
      logError("Error analyzing text: $e");
    }
  }

    /// Checks existing records in Firebase for similarity to _currentVector
  Future<Map<String, dynamic>?> checkForDuplicate() async {
    try {
      if (state.currentVector == null) return null;

      // Filter by Area, Line, and Year
      final String? currentArea = state.area;
      final String? currentLine = state.line;
      final int currentYear = DateTime.now().year;

      // If area or line is missing, we cannot strictly enforce "same area and same line"
      if (currentArea == null || currentArea.isEmpty || currentLine == null || currentLine.isEmpty) {
        return null;
      }

      // 1. Fetch reports by Area (Server side filter)
      final data = await _atrService.getAtrsByArea(currentArea, limit: 100);
      
      if (data.isEmpty) return null;

      double maxSimilarity = 0.0;
      ModelAtr? duplicateCandidate;

      // 2. Iterate and compare vectors with additional filters (Line & Year)
      for (var record in data) {
        // Filter: Same Line
        if (record.line != currentLine) continue;

        // Filter: Same Year
        final recordDate = DateTime.tryParse(record.issueDate);
        if (recordDate == null ) continue; //|| recordDate.year != currentYear

        final List<double>? recordVector = record.vector;
        if (recordVector != null && recordVector.isNotEmpty) {
          // Compare
          double similarity = _ai.duplicateDetector.calculateSimilarity(state.currentVector!, recordVector);
          
          // Threshold: 0.85 (85%) similarity
          if (similarity > 0.85 && similarity > maxSimilarity) {
            maxSimilarity = similarity;
            duplicateCandidate = record;
          }
        }
      }
      logInfo("similarity: ${maxSimilarity}");
      if (duplicateCandidate != null) {
        return {'atr': duplicateCandidate, 'similarity': maxSimilarity};
      }
      return null;

    } catch (e) {
      logError("Duplicate check error: $e");
      return null;
    }
  }

  Future<void> submitReport() async {
    emit(state.copyWith(issueFormState: IssueFormState.isSubmitting));
    final observation = ModelAtr(
        line: state.line,
        area: state.area,
        observation: state.observation??"",
        action: state.action??"",
        status: "awaiting validation",

        issueDate: DateTime.now().toIso8601String(),
        type: state.selectedType ?? "Unsafe_Condition",
        hazardKind: state.selectedHazardKind ?? "General",
        detailedKind: state.selectedDetailedKind ?? "Other",
        level: state.selectedLevel ?? "Low",
        respDepartment: state.selectedRespDept ?? "Safety",
        depPersonExecuter: state.responsiblePerson ?? "Unassigned",
        vector: state.currentVector,
        reporter: FirebaseAuth.instance.currentUser?.email ?? "Anonymous",
        isDuplicateSuspect: state.duplicateWarning != null,
      );
    try {
      var finalObs = observation;
      
      String? uploadedImageUrl;
      final selectedImage = state.selectedImage;
      if (selectedImage != null) {
          uploadedImageUrl = await _storage.uploadAtrImage(
            observation.id!,
            selectedImage, 
          );
      }

      List<double> vector = [];
      try {
        vector = await _ai.duplicateDetector.getEmbedding(
          line: observation.line??"",
          area: observation.area??"",
          text:observation.observation
        );
      } catch (e) { logError("Embedding Error: $e"); }

      // Use predictions (either newly generated or from state if we wanted)
      // Current logic re-predicts for safety, which is fine.
      if (observation.type == "Pending AI" || observation.type == null) {
        final prediction = await _ai.classifier.predict(
          line: observation.line??"",
          area: observation.area??"",
          text:observation.observation);
        
        finalObs = observation.copyWith(
          type: prediction['type'],
          hazardKind: prediction['hazard_kind'],
          level: prediction['level'],
          detailedKind: prediction['detailed_kind'],
          action: (observation.action.isEmpty) ? prediction['action'] : observation.action,
          respDepartment: (observation.respDepartment == null) ? prediction['respDepartment'] : observation.respDepartment,
          vector: vector,
          imageUrl: uploadedImageUrl,
          isDuplicateSuspect: state.isDuplicateSuspect, 
        );
      } else {
        finalObs = observation.copyWith(vector: vector, imageUrl: uploadedImageUrl, isDuplicateSuspect: state.isDuplicateSuspect);
      }

      await _atrService.addAtr(finalObs);
      
      emit(ReportState(issueFormState: IssueFormState.success)); 
      
    } catch (e) {
      emit(state.copyWith(issueFormState: IssueFormState.failure, error: e.toString()));
    }
  }

  void resetState() {
    emit(ReportState()); 
  }
}
