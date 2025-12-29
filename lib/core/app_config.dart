/// A centralized place for application-wide constants and configurations.
class AppConfig {
// Prevent instantiation
  AppConfig._();
//--------------------------Constants------------------------------------------------

///Defaul timeout for futures.
static const  kDefaultTimeout = Duration(seconds: 15);
///Defaul timeout for longer futures.
static const kLongTimeout = Duration(minutes: 1);
///Fail fast so user can retry credentials.
static const kLoginAuthTimeout = Duration(seconds: 10);  
///If it takes longer, the user assumes it's broken. Cancel previous requests if the user keeps typing.
static const kSearchQueriesTimeout = Duration(seconds: 5);
/// Use Future.wait to fetch unrelated data parallelly.
static const kDashboardDataTimeout = Duration(seconds: 15); 
///60+ seconds to upload a file.
static const kFileUploadTimeout = Duration(minutes: 1); 
/// A shorter timeout for operations that should be very fast.
static const Duration shortNetworkTimeout = Duration(seconds: 8);
/// AI chat response timeout.
static const kAiResponseTimeout = Duration(seconds: 15); 

}
