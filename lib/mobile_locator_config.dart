import 'package:get_it/get_it.dart';
import '../data/repository/i_repo_hazard_classifier.dart';
import '../data/repository/i_repo_duplicate_detector.dart';
import '../data/repository/repo_hazard_classifier_mobile.dart';
import '../data/repository/repo_duplicate_detector_mobile.dart';

/// This file is ONLY compiled on Mobile/Desktop (dart:io)
void registerPlatformRepositories(GetIt sl) {
    sl.registerSingletonAsync<IRepoHazardClassifier>(
      () async
      {
        final xx =  RepoHazardClassifierMobile();
        await xx.loadModel();
        return xx;
      },
    );
    sl.registerSingletonAsync<IRepoDuplicateDetector>(
      () async
      {
        final xx =  RepoDuplicateDetectorMobile();
        await xx.loadModel();
        return xx;
      },
    );
}