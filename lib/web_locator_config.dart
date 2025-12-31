import 'package:get_it/get_it.dart';
import '../data/repository/i_repo_hazard_classifier.dart';
import '../data/repository/i_repo_duplicate_detector.dart';
import '../data/repository/repo_hazard_classifier_web.dart';
import '../data/repository/repo_duplicate_detector_web.dart';

/// This file is ONLY compiled on Web (dart:library.html)
void registerPlatformRepositories(GetIt sl) {

    sl.registerSingletonAsync<IRepoHazardClassifier>(() async
      {
        final xx =  RepoHazardClassifierWeb();
        await xx.loadModel();
        return xx;
      },
    );
    // sl.registerSingletonAsync<IRepoDuplicateDetector>(
    //   () async
    //   {
    //     final xx =  RepoDuplicateDetectorWeb();
    //     await xx.loadModel();
    //     return xx;
    //   },
    // );
}