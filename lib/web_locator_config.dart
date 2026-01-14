import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

import 'package:safety_portal/data/repository/i_repo_hazard_classifier.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:safety_portal/data/repository/repo_hazard_classifier_web.dart';
import 'package:safety_portal/data/repository/repo_duplicate_detector_web.dart';
import 'package:safety_portal/data/repository/i_repo_forecaster.dart';
import 'package:safety_portal/data/repository/repo_forecaster_web.dart';

void registerPlatformRepositories(GetIt sl) {

    sl.registerSingletonAsync<IRepoHazardClassifier>(() async
      {
        final xx =  RepoHazardClassifierWeb();
        try {
          await xx.loadModel().timeout(Duration(seconds: 10));
        } catch (e) {
          debugPrint("⚠️ WARNING: Classifier failed to load: $e");
        }
        return xx;
      },
    );
    sl.registerSingletonAsync<IRepoDuplicateDetector>(
      () async
      {
        final xx =  RepoDuplicateDetectorWeb();
        try {
          await xx.loadModel().timeout(Duration(seconds: 10));
        } catch (e) {
          debugPrint("⚠️ WARNING: Duplicate Detector failed to load: $e");
        }
        return xx;
      },
    );
    sl.registerSingletonAsync<IRepoForecaster>(
      () async
      {
        final xx =  RepoForecasterWeb();
        try {
          await xx.loadModel().timeout(Duration(seconds: 10));
        } catch (e) {
          debugPrint("⚠️ WARNING: Forecaster failed to load: $e");
        }
        return xx;
      },
    );
}