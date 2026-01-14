import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/repository/i_repo_storage.dart';

class ServiceStorage with LogMixin{
  final IRepoStorage _repo;

  ServiceStorage(this._repo);
  
  Future<String> uploadAtrImage(String reportId, XFile selectedImage) async {
      String ref = "";
      try {
          
          if (kIsWeb) {
            final imageBytes = await selectedImage.readAsBytes();
            ref = await _repo.uploadData(path: "atr_photos/${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg", data: imageBytes);
          } else {
              ref = await _repo.uploadFile(path: "atr_photos/${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg", file: File(selectedImage.path));
          }
          logInfo("Image uploaded to $ref");
          return ref;
        }
        catch (e) {
          logError("Image upload to $ref failed: $e");
          return ref;
          // Depending on requirements, we might want to fail here or continue without image.
          // For now, we continue.
        }
    }

  }