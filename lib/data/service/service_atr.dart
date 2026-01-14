import 'dart:async';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/repository/i_repo_realtime.dart';

class AtrService {
  final IRepoRealtime _repo;
  static const String _path = 'atr';

  AtrService(this._repo);

  /// Creates a new Action Tracking Report in the database
  Future<void> addAtr(ModelAtr model) async {
    final String id = model.id ?? await _repo.generateId(_path);
    final modelToSave = model.copyWith(id: id);
    await _repo.set(_path, id, modelToSave.toRealtimeDatabase());
  }

  /// Updates an existing report
  Future<void> updateAtr(ModelAtr model) async {
    if (model.id == null) throw Exception("Cannot update ATR without an ID");
    await _repo.update(_path, model.id!, model.toRealtimeDatabase());
  }

  /// Removes a report from the database
  Future<void> removeAtr(String id) async {
    await _repo.remove(_path, id);
  }

  /// Streams reports with an optional limit (e.g. last 50)
  Stream<List<ModelAtr>> getAtrStream({int? limit}) {
    return _repo.getStream(_path, limit: limit).map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> data = _parseData(snapshot.value);
      final List<ModelAtr> reports = [];

      data.forEach((key, value) {
        if (value is Map) {
          reports.add(ModelAtr.fromMap(key.toString(), value));
        }
      });

      // Newest first sorting
      reports.sort((a, b) {
        return _compareDates(a.issueDate, b.issueDate);
      });
      return reports;
    });
  }
    /// Fetches reports filtered by area with an optional limit
  Future<List<ModelAtr>> getAtrs({int? limit}) async {
    final snapshot = await _repo.getData(_path, limit: limit);

    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data = _parseData(snapshot.value);
    final List<ModelAtr> list = data.entries
        .map((e) => ModelAtr.fromMap(e.key.toString(), e.value as Map))
        .toList();
    
    list.sort((a, b) {
      return _compareDates(a.issueDate, b.issueDate);
    });
    return list;
  }
  /// Fetches reports filtered by area with an optional limit
  Future<List<ModelAtr>> getAtrsByArea(String area, {int? limit}) async {
    final condition = QueryCondition('area', QueryType.isEqualTo, area);
    final snapshot = await _repo.getData(_path, where: [condition], limit: limit);

    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data = _parseData(snapshot.value);
    final List<ModelAtr> list = data.entries
        .map((e) => ModelAtr.fromMap(e.key.toString(), e.value as Map))
        .toList();
    
    list.sort((a, b) {
      return _compareDates(a.issueDate, b.issueDate);
    });
    return list;
  }

  /// Validates the report and sends a notification to the executor
  Future<void> validateAtr(ModelAtr model) async {
    final updated = model.copyWith(status: 'validated');
    await updateAtr(updated);
    await _sendNotification(updated);
  }

  Future<void> _sendNotification(ModelAtr model) async {
    final notifId = await _repo.generateId('notifications');
    await _repo.set('notifications', notifId, {
      'userId': model.depPersonExecuter,
      'title': 'Safety Action Assigned',
      'body': 'A new safety issue has been validated and assigned to you.',
      'atrId': model.id,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  Map<dynamic, dynamic> _parseData(dynamic value) {
    if (value == null) return {};
    if (value is Map) return value;
    if (value is List) {
      return {for (int i = 0; i < value.length; i++) if (value[i] != null) i.toString(): value[i]};
    }
    return {};
  }

  int _compareDates(String? dateA, String? dateB) {
    final dtA = (dateA != null && dateA.isNotEmpty) ? (DateTime.tryParse(dateA) ?? DateTime(0)) : DateTime(0);
    final dtB = (dateB != null && dateB.isNotEmpty) ? (DateTime.tryParse(dateB) ?? DateTime(0)) : DateTime(0);
    return dtB.compareTo(dtA);
  }
}