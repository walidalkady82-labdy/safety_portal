import 'package:get_it/get_it.dart';
import 'package:safety_portal/data/repository/i_repo_realtime.dart';
import 'package:safety_portal/data/repository/i_repo_storage.dart';
import 'package:safety_portal/data/repository/repo_realtime.dart';
import 'package:safety_portal/data/repository/repo_storage.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/data/service/service_storage.dart';
import '../data/service/service_ai.dart';
import '../data/service/service_analytics.dart';

// THE MAGIC: This line selects the correct registration file at compile-time.
// This prevents the Web compiler from ever looking at the Mobile code (and vice versa).
import 'locator_stub.dart'
    if (dart.library.js_interop) 'web_locator_config.dart'
    if (dart.library.html) 'web_locator_config.dart'
    if (dart.library.io) 'mobile_locator_config.dart';

final sl = GetIt.instance;

/// Initialize all services and repositories.
/// Call this in main.dart before runApp().
Future<void> setupLocator() async {
  
  // 1. Register Platform-Specific Repositories
  // This function is defined in both repo_config_web and repo_config_mobile
  registerPlatformRepositories(sl);

  // The database Service 
  sl.registerLazySingleton<IRepoRealtime>(() => RepoRealtime.create(useEmulator: true));

  // The storage Service 
  sl.registerLazySingleton<IRepoStorage>(() => RepoStorage.create(useEmulator: true));

  // 2. Register Shared Services
  // We use LazySingletons so they only initialize when first used.
  sl.registerLazySingleton<ServiceAnalytics>(() => ServiceAnalytics());
  
  // The AI Service is now a simple aggregator
  sl.registerLazySingleton<ServiceAI>(() => ServiceAI());

  // ATR service
  sl.registerLazySingleton<AtrService>(() => AtrService(sl<IRepoRealtime>()));

  sl.registerLazySingleton<ServiceStorage>(() => ServiceStorage(sl<IRepoStorage>()));
}
