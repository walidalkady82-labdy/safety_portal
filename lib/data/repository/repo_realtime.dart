import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'i_repo_realtime.dart';

class RepoRealtime implements IRepoRealtime {
  final FirebaseDatabase _db;
  
  RepoRealtime._({required FirebaseDatabase db}) : _db = db;

  /// Factory to initialize the repository with optional emulator support.
  factory RepoRealtime.create({bool useEmulator = false}) {
    final instance = FirebaseDatabase.instance;
    
    // Enable offline persistence for mobile platforms
    if (!kIsWeb) {
      instance.setPersistenceEnabled(true);
    }

    // Connect to local emulator if in debug mode
    if (kDebugMode && useEmulator) {
      String host = 'localhost';
      // Android emulator requires 10.0.2.2 to connect to host machine
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        host = '10.0.2.2';
      }
      instance.useDatabaseEmulator(host, 9000);
    }

    return RepoRealtime._(db: instance);
  }

  @override
  Future<String> generateId(String path) async {
    // push() generates a unique client-side key
    return _db.ref(path).push().key ?? '';
  }

  @override
  Future<DataSnapshot> getData(String path, {List<QueryCondition>? where, int? limit}) async {
    Query query = _db.ref(path);

    // RTDB allows filtering by one child at a time via the client SDK
    if (where != null && where.isNotEmpty) {
      final condition = where.first; 
      query = query.orderByChild(condition.field);
      
      switch (condition.type) {
        case QueryType.isEqualTo:
          query = query.equalTo(condition.value);
          break;
        case QueryType.isLessThan:
          query = query.endAt(condition.value);
          break;
        case QueryType.isGreaterThan:
          query = query.startAt(condition.value);
          break;
      }
    }

    if (limit != null) {
      query = query.limitToFirst(limit);
    }

    final event = await query.once();
    return event.snapshot;
  }

  @override
  Stream<DatabaseEvent> getStream(String path,{int? limit}) {
    return _db.ref(path).onValue;
  }

  @override
  Future<void> set(String path, String id, Map<String, dynamic> data) async {
    await _db.ref(path).child(id).set(data);
  }

  @override
  Future<void> update(String path, String id, Map<String, dynamic> data) async {
    await _db.ref(path).child(id).update(data);
  }

  @override
  Future<void> remove(String path, String id) async {
    await _db.ref(path).child(id).remove();
  }
}