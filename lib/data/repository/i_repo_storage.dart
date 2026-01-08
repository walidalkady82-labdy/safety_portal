import 'dart:io' show File;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

abstract class IRepoStorage {
  Future<String> uploadFile({required String path,required File file,SettableMetadata? metadata,}) ;
  Future<String> uploadData({required String path,required Uint8List data, SettableMetadata? metadata,});
  Future<void> deleteFile(String path);
}