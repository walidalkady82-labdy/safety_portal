// lib/data/repo/repo_storage.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:safety_portal/data/repository/i_repo_storage.dart';

class RepoStorage implements IRepoStorage{
  final String path = 'gs://database-a1f2a.firebasestorage.app';
  
  final FirebaseStorage _storage;
  
  RepoStorage._({required FirebaseStorage storage}) : _storage = storage;

  factory RepoStorage.create({bool useEmulator = false}) {
    final instance = FirebaseStorage.instance;
    
    // Connect to local emulator if in debug mode
    if (kDebugMode && useEmulator) {
      String host = 'localhost';
      // Android emulator requires 10.0.2.2 to connect to host machine
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        host = '10.0.2.2';
      }
      instance.useStorageEmulator(host, 9199);
    }

    return RepoStorage._(storage: instance);
  }
  /// Uploads a file (Mobile/Desktop)
  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    SettableMetadata? metadata,
  }) async {
    try {
      final ref = _storage.ref().child("$path/$path");
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  /// Uploads raw data (Web)
  @override
  Future<String> uploadData({
    required String path,
    required Uint8List data,
    SettableMetadata? metadata,
  }) async {
    try {
      final ref = _storage.ref().child("$path/$path");
      final uploadTask = ref.putData(data, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Data upload failed: $e');
    }
  }

  /// Deletes a file at the specified path
  @override
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child("$path/$path").delete();
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
}
