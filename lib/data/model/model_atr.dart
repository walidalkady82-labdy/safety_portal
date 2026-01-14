class ModelAtr {
  final String? id;
  final String? line;
  final String? area;
  final String observation;
  final String action;
  final String status;
  final String issueDate;
  final String? type;
  final String? hazardKind;
  final String? detailedKind;
  final String? level;
  final String? respDepartment;
  final String? depPersonExecuter;
  final List<double>? vector;
  final String? reporter;
  final bool isDuplicateSuspect;
  final String? imageUrl; 

  ModelAtr({
    this.id,
    this.line,
    this.area,
    required this.observation,
    this.action = "",
    this.status = "awaitingValidation",
    required this.issueDate,
    this.type,
    this.hazardKind,
    this.detailedKind,
    this.level,
    this.respDepartment,
    this.depPersonExecuter,
    this.vector,
    this.reporter,
    this.isDuplicateSuspect = false,
    this.imageUrl   
  });

  /// Creates a copy of the model with updated fields. 
  /// Useful for Cubit state mutations.
  ModelAtr copyWith({
    String? id,
    String? line,
    String? area,
    String? observation,
    String? action,
    String? status,
    String? issueDate,
    String? type,
    String? hazardKind,
    String? detailedKind,
    String? level,
    String? respDepartment,
    String? depPersonExecuter,
    List<double>? vector,
    String? reporter,
    bool? isDuplicateSuspect,
    String? imageUrl
  }) {
    return ModelAtr(
      id: id ?? this.id,
      line: line ?? this.line,
      area: area ?? this.area,
      observation: observation ?? this.observation,
      action: action ?? this.action,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      type: type ?? this.type,
      hazardKind: hazardKind ?? this.hazardKind,
      detailedKind: detailedKind ?? this.detailedKind,
      level: level ?? this.level,
      respDepartment: respDepartment ?? this.respDepartment,
      depPersonExecuter: depPersonExecuter ?? this.depPersonExecuter,
      vector: vector ?? this.vector,
      reporter: reporter ?? this.reporter,
      isDuplicateSuspect: isDuplicateSuspect ?? this.isDuplicateSuspect,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Converts the object to a Map for storage in Firebase Realtime Database.
  Map<String, dynamic> toMap() {
    return {
      'line': line,
      'area': area,
      'observationOrIssueOrHazard': observation,
      'actionOrCorrectiveAction': action,
      'status': status,
      'issueDate': issueDate,
      'type': type,
      'hazard_kind': hazardKind,
      'detailed_kind': detailedKind,
      'level': level,
      'respDepartment': respDepartment,
      'depPersonExecuter': depPersonExecuter,
      'vector': vector,
      'reporter': reporter,
      'isDuplicateSuspect': isDuplicateSuspect,
      'imageUrl' : imageUrl
    };
  }

  /// Alias for toMap specifically for Realtime Database naming conventions.
  Map<String, dynamic> toRealtimeDatabase() => toMap();

  /// Creates an AtrModel instance from a Firebase Realtime Database Map.
  factory ModelAtr.fromMap(String id, dynamic map) {
    if (map == null || map is! Map) {
      return ModelAtr(
        id: id,
        observation: "Invalid Data",
        issueDate: DateTime.now().toIso8601String(),
      );
    }
    return ModelAtr(
      id: id,
      line: map['line']?.toString(),
      area: map['area'] as String?,
      observation: map['observationOrIssueOrHazard'] ?? '',
      action: map['actionOrCorrectiveAction'] ?? '',
      status: map['status'] ?? 'Pending',
      issueDate: map['issueDate'] ?? '',
      type: map['type'] as String?,
      hazardKind: map['hazard_kind'] as String?,
      detailedKind: map['detailed_kind'] as String?,
      level: map['level'] as String?,
      respDepartment: map['respDepartment'] as String?,
      depPersonExecuter: map['depPersonExecuter'] as String?,
      vector: map['vector'] != null 
          ? List<double>.from((map['vector'] as List).map((e) => (e as num).toDouble())) 
          : null,
      reporter: map['reporter'] as String?,
      isDuplicateSuspect: map['isDuplicateSuspect'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}