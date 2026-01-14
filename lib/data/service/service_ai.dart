import 'dart:async';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:safety_portal/core/logger.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/data/repository/i_repo_duplicate_detector.dart';
import 'package:safety_portal/data/repository/i_repo_hazard_classifier.dart';
import 'package:safety_portal/data/service/service_atr.dart';
import 'package:safety_portal/locator.dart';

import '../repository/i_repo_forecaster.dart';


class ServiceAI with LogMixin{

  static final ServiceAI _instance = ServiceAI._internal();
  factory ServiceAI() => _instance;
  ServiceAI._internal();

  // Use the Switcher classes (which handle the conditional imports)
  final classifier = sl<IRepoHazardClassifier>();
  final duplicateDetector = sl<IRepoDuplicateDetector>();
  final repoForecaster = sl<IRepoForecaster>();
  // final atrService = sl<AtrService>();

  bool _isInitialized = false;

   // --- 1. AI GAIN CONFIGURATION (Gamification Weights) ---
  // A "High Risk" report is worth 5x more than a "Low Risk" one.
  final Map<String, int> levelWeights = {
    'low': 1, 
    'medium': 3, 
    'high': 5
  };

  // A "First Aid" (FA) or "Near Miss" (NM) is worth significantly more 
  // than a standard "Unsafe Condition" because they prevent immediate recurrence.
  final Map<String, int> typeWeights = {
    'unsafe_condition': 1,
    'unsafe_behavior': 2,
    'nm': 5, // Near Miss
    'fa': 10 // First Aid
  };

  Future<void> initAllModels() async {
    if (_isInitialized) return;
    await Future.wait([
      classifier.loadModel(),
      duplicateDetector.loadModel(),
      repoForecaster.loadModel(),
    ]);
    _isInitialized = true;
    logInfo("AI Models Initialized");
  }

  /// Analyzes an image for hazards using the Object Detection model.
  /// Returns a formatted string if a hazard is found, or null otherwise.
  Future<String?> analyzeImage(XFile image) async {
    // if (!objectDetector.isLoaded) {
    //   await objectDetector.loadModel();
    // }

    // try {
    //   final detections = await objectDetector.detect(image);

    //   if (detections.isNotEmpty) {
    //     // Sort by confidence (highest first)
    //     detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
        
    //     final best = detections.first;
    //     final label = best['label'];
    //     final conf = ((best['confidence'] as double) * 100).toInt();

    //     // Only return if confidence is reasonably high (e.g., > 50%)
    //     if (conf > 50) {
    //        return "$label ($conf%)";
    //     }
    //   }
    // } catch (e) {
    //   logError("Image Analysis Error: $e");
    // }
    return null;
  }
  
  Future<Map<String, dynamic>> analyzeFull(String text, {required line,required String area}) async {
    if (!_isInitialized) await initAllModels();

    // Ensure area is never null to prevent tensor creation errors
    final results = await Future.wait([
      classifier.predict(line:line,area: area,text:  text),
      duplicateDetector.getEmbedding(line:line,area: area,text:  text),
    ]);

    return {
      'classification': results[0] as Map<String, String>,
      'embedding': results[1] as List<double>,
    };
  }
  /// --- SMART SEARCH & SMART ACTION CORE ---
  /// Finds reports in [sourceData] that are semantically similar to [query].
  /// Returns a sorted list of matches with a 'similarity' score.
  Future<List<Map<String, dynamic>>> searchSimilarReports(
    String query, 
    List<ModelAtr> sourceData, 
    {double threshold = 0.5, int limit = 10}
  ) async {
    if (!_isInitialized) await initAllModels();
    if (query.isEmpty) return [];

    // 1. Get embedding for the query
    List<double> queryVector = await duplicateDetector.getEmbedding(line:"",area:"",text:query);
    if (queryVector.isEmpty || (queryVector.length == 1 && queryVector[0] == 0)) {
      return [];
    }

    // 2. Compare with all source reports
    List<Map<String, dynamic>> matches = [];

    for (var report in sourceData) {
      if (report.vector == null || report.vector!.isEmpty) continue;

      double score = duplicateDetector.calculateSimilarity(queryVector, report.vector!);
      
      if (score >= threshold) {
        matches.add({
          'report': report,
          'score': score,
        });
      }
    }

    // 3. Sort by similarity (Highest first)
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return matches.take(limit).toList();
  }

  /// --- Returns a score from 0.0 (Bad) to 1.0 (Perfect) ---
  /// 
  // 1. Hardcode a few "Perfect" descriptions to act as the Gold Standard
  final List<String> _goldStandardExamples = [
    "Oil leakage detected in the main pump seal causing slip hazard",
    "Emergency stop button broken on conveyor belt 5",
    "High voltage cable insulation damaged near the walkway",
    "Workers not wearing safety helmet in the construction zone",
    "Fire extinguisher pressure gauge is reading zero/empty"
  ];
  
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'S-PREDICT',
      // Categories & Observations
      'cat_abs': 'Absence(Improper) of safety device.',
      'desc_001': 'Grinding machine missing the transparent eye shield.',
      'desc_002': 'Emergency stop button missing from the auxiliary conveyor.',
      'desc_003': 'Safety sensor on the hydraulic press is disconnected.',
      'desc_004': 'No anti-kickback device installed on the circular saw.',
      
      'cat_conf': 'Confined space',
      'desc_005': 'Worker entered the storage tank without a gas clearance certificate.',
      'desc_006': 'Ventilation fan not operating during manhole maintenance.',
      'desc_007': 'Hole watch person left his post while worker was inside.',
      'desc_008': 'Oxygen levels not monitored during underground pipe repair.',

      'cat_drive': 'Driving',
      'desc_009': 'Forklift driver traveling with an elevated load blocking vision.',
      'desc_010': 'Site vehicle exceeded speed limit near the pedestrian crossing.',
      'desc_011': 'Operator using mobile phone while driving the heavy truck.',
      'desc_012': 'Reversing without a banksman in a high-traffic zone.',

      'cat_fire': 'Fire hazard',
      'desc_013': 'Aerosol cans stored near the heat treatment furnace.',
      'desc_014': 'Blocked fire hydrant behind stacked wooden pallets.',
      'desc_015': 'Electrical daisy-chaining causing overheating of power strips.',
      'desc_016': 'Accumulated lint and dust behind the drying unit.',

      'cat_lototo': 'LOTOTO',
      'desc_017': 'Isolation valve not locked during pipeline maintenance.',
      'desc_018': 'Personal lock applied but safety tag is missing information.',
      'desc_019': 'System not tested for Zero Energy before starting repair.',
      'desc_020': 'Lock removed by supervisor while worker was at lunch.',

      'cat_ppe': 'Not wearing PPE.',
      'desc_021': 'Technician grinding metal without eye protection.',
      'desc_022': 'Handling acidic chemicals without wearing rubber gloves.',
      'desc_023': 'Working on a 3-meter scaffold without a safety harness.',
      'desc_024': 'Visitor entered the workshop without high-visibility vest.',

      'cat_oil': 'Oil Leakage',
      'desc_025': 'Hydraulic fluid pooling under the forklift mast.',
      'desc_026': 'Transformer leaking oil onto the gravel base.',
      'desc_027': 'Grease dripping from the overhead conveyor onto the floor.',
      'desc_028': 'Slow leak from the air compressor lubricator.',

      'cat_house': 'Poor housekeeping.',
      'desc_029': 'Empty cardboard boxes blocking the emergency exit.',
      'desc_030': 'Metal shavings left on the floor around the lathe machine.',
      'desc_031': 'Extension cords tangled across the main walkway.',
      'desc_032': 'Spilled water on the canteen floor not cleaned for hours.',

      'cat_fall': 'Falling objects',
      'desc_033': 'Hand tools left on the edge of a scaffold platform.',
      'desc_034': 'Loose bolts sitting on top of the overhead crane rail.',
      'desc_035': 'Hammer dropped from height due to lack of tool tether.',
      'desc_036': 'Loose tiles on the roof edge about to fall.',

      'cat_sign': 'Safety Signs',
      'desc_037': 'Mandatory PPE sign is faded and unreadable.',
      'desc_038': 'Danger: High Voltage sign missing from the transformer.',
      'desc_039': 'Wet floor sign not placed after mopping.',
      'desc_040': 'Exit sign pointing in the wrong direction.',

      'cat_proc': 'breaching procedures.',
      'desc_041': 'Walking under a suspended load to take a shortcut.',
      'desc_042': 'Using a ladder that has not been inspected this month.',
      'desc_043': 'Standing on the top rung of a step ladder.',
      'desc_044': 'Jumping off the back of a stationary truck.',

      'cat_hot': 'Hot work',
      'desc_045': 'Welding started without a fire blanket to catch sparks.',
      'desc_046': 'Grinding performed within 10 meters of flammable liquids.',
      'desc_047': 'No fire extinguisher present at the site of gas cutting.',

      'cat_ergo': 'Improper Ergonomics.',
      'desc_048': 'Manual lifting of 40kg motor without mechanical aid.',
      'desc_049': 'Computer workstation set up without lumbar support.',
      'desc_050': 'Technician working with arms extended overhead for long periods.',

      'cat_maint': 'Lack of maintenance.',
      'desc_051': 'Emergency lights in the stairwell do not illuminate.',
      'desc_052': 'Rusty safety valve on the air receiver tank.',
      'desc_053': 'Conveyor belt is frayed and slipping.',
      'desc_054': 'The brake on the hoist is slipping under load.',

      // ... logic continues for IDs 055 to 150 with similar variation
      'desc_150': 'The Assembly Point sign has fallen down.'
    },
    'ar': {
      'app_title': 'إس-بريديكت',
      'cat_abs': 'غياب (عدم ملائمة) جهاز السلامة.',
      'desc_001': 'ماكينة الجلخ تفتقر إلى واقي العين الشفاف.',
      'desc_002': 'زر توقف الطوارئ مفقود من سير النقل المساعد.',
      'desc_003': 'حساس السلامة في المكبس الهيدروليكي مفصول.',
      'desc_004': 'لا يوجد جهاز مضاد للارتداد مثبت على المنشار الدائري.',
      
      'cat_conf': 'الأماكن المغلقة',
      'desc_005': 'دخل العامل خزان التخزين بدون شهادة خلو من الغازات.',
      'desc_006': 'مروحة التهوية لا تعمل أثناء صيانة فتحة الصرف الصحي.',
      'desc_007': 'غادر مراقب الفتحة موقعه بينما كان العامل بالداخل.',
      'desc_008': 'لم يتم مراقبة مستويات الأكسجين أثناء إصلاح الأنابيب.',

      'cat_drive': 'القيادة',
      'desc_009': 'سائق الرافعة الشوكية يتحرك بحمل مرتفع يحجب الرؤية.',
      'desc_010': 'تجاوزت مركبة الموقع حد السرعة عند ممر المشاة.',
      'desc_011': 'المشغل يستخدم الهاتف المحمول أثناء القيادة.',
      'desc_012': 'الرجوع للخلف بدون موجه في منطقة مزدحمة.',

      'cat_fire': 'خطر حريق',
      'desc_013': 'علب الرش مخزنة بالقرب من فرن المعالجة الحرارية.',
      'desc_014': 'صنبور حريق محجوب خلف طبليات خشبية مكدسة.',
      'desc_015': 'توصيل الوصلات ببعضها مما يسبب سخونة زائدة.',
      'desc_016': 'تراكم الوبر والغبار خلف وحدة التجفيف.',

      'cat_lototo': 'عزل وتأمين الطاقة',
      'desc_017': 'صمام العزل غير مقفل أثناء صيانة خط الأنابيب.',
      'desc_018': 'تم وضع القفل الشخصي ولكن بطاقة السلامة ناقصة.',
      'desc_019': 'لم يتم اختبار النظام للتأكد من طاقة صفر قبل الإصلاح.',
      'desc_020': 'قام المشرف بإزالة القفل بينما كان العامل في الغداء.',

      'cat_ppe': 'عدم ارتداء أدوات الوقاية.',
      'desc_021': 'فني يقوم بجلخ المعادن دون ارتداء واقي العينين.',
      'desc_022': 'مناولة مواد كيميائية حمضية دون قفازات مطاطية.',
      'desc_023': 'العمل على سقالة بارتفاع 3 أمتار دون حزام الأمان.',
      'desc_024': 'دخل زائر الورشة دون ارتداء سترة عاكسة.',

      'cat_oil': 'تسرب زيت',
      'desc_025': 'تجمع سائل هيدروليكي أسفل ساري الرافعة الشوكية.',
      'desc_026': 'تسرب زيت من المحول إلى القاعدة الحصوية.',
      'desc_027': 'تنقيط شحم من الناقل العلوي على الأرض.',
      'desc_028': 'تسرب بطيء من مزيتة ضاغط الهواء.',

      'cat_house': 'سوء التنظيم والنظافة.',
      'desc_029': 'صناديق كرتونية فارغة تسد مخرج الطوارئ.',
      'desc_030': 'رايش معادن متروك على الأرض حول المخرطة.',
      'desc_031': 'أسلاك التوصيل متشابكة عبر الممشى الرئيسي.',
      'desc_032': 'ماء مسكوب على الأرض لم يتم تنظيفه لساعات.',

      'cat_fall': 'الأجسام المتساقطة',
      'desc_033': 'أدوات يدوية متروكة على حافة منصة السقالة.',
      'desc_034': 'مسامير مفكوكة موجودة فوق سكة الرافعة العلوية.',
      'desc_035': 'سقوط مطرقة من ارتفاع بسبب عدم وجود حبل تأمين.',
      'desc_036': 'بلاط مفكك على حافة السقف أوشك على السقوط.',

      'cat_sign': 'لوحات السلامة',
      'desc_037': 'لوحة أدوات الوقاية الإلزامية باهتة وغير مقروءة.',
      'desc_038': 'لوحة خطر: جهد عالي مفقودة من المحول.',
      'desc_039': 'لم يتم وضع لوحة أرضية رطبة بعد المسح.',
      'desc_040': 'لوحة المخرج تشير إلى الاتجاه الخاطئ.',

      'cat_proc': 'مخالفة الإجراءات.',
      'desc_041': 'المشي تحت حمل معلق لاتخاذ طريق مختصر.',
      'desc_042': 'استخدام سلم لم يتم فحصه لهذا الشهر.',
      'desc_043': 'الوقوف على الدرجة العلوية من السلم المتنقل.',
      'desc_044': 'القفز من خلف شاحنة متوقفة.',

      'cat_hot': 'أعمال ساخنة',
      'desc_045': 'البدء في اللحام دون استخدام بطانية حريق.',
      'desc_046': 'الجلخ على بعد أقل من 10 أمتار من سوائل قابلة للاشتعال.',
      'desc_047': 'لا توجد طفاية حريق في موقع القطع بالغاز.',

      'cat_ergo': 'الأرغونوميا (هندسة العوامل البشرية)',
      'desc_048': 'رفع يدوي لمحرك وزن 40 كجم بدون مساعدة ميكانيكية.',
      'desc_049': 'محطة عمل الكمبيوتر مهيأة دون وجود دعم للظهر.',
      'desc_050': 'فني يعمل ويداه ممدودتان فوق رأسه لفترات طويلة.',

      'cat_maint': 'نقص الصيانة.',
      'desc_051': 'أضواء الطوارئ في درج المبنى لا تعمل.',
      'desc_052': 'صمام أمان صدئ على خزان مستقبل الهواء.',
      'desc_053': 'سير النقل مهترئ وينزلق.',
      'desc_054': 'فرامل الرافعة تنزلق تحت الحمل.',
      
      'desc_150': 'لوحة نقطة التجمع سقطت على الأرض.'
    }
  };  
  
  List<String> get goldStandardExamples => _goldStandardExamples;

  // Cache the "Gold Vector" so we don't calculate it every time
  List<double>? _goldVector;

  // Cache individual embeddings for specific recommendations
  List<List<double>>? _goldStandardEmbeddings;

  /// Returns a relevant example based on semantic similarity to the input text.
  Future<String> getRelevantGoldStandard(String input) async {
    if (!_isInitialized) await initAllModels();
    if (_goldStandardExamples.isEmpty) return "";

    // 1. Initialize Gold Embeddings if needed
    if (_goldStandardEmbeddings == null) {
      _goldStandardEmbeddings = [];
      for (var ex in _goldStandardExamples) {
        _goldStandardEmbeddings!.add(await duplicateDetector.getEmbedding(line: '', area: '', text: ex));
      }
    }

    // 2. Get Input Embedding
    List<double> inputVector = await duplicateDetector.getEmbedding(line: '', area: '', text: input);

    // 3. Find Best Match
    int bestIndex = 0;
    double maxScore = -1.0;
    
    for (int i = 0; i < _goldStandardEmbeddings!.length; i++) {
      double score = duplicateDetector.calculateSimilarity(inputVector, _goldStandardEmbeddings![i]);
      if (score > maxScore) {
        maxScore = score;
        bestIndex = i;
      }
    }
    
    return _goldStandardExamples[bestIndex];
  }

  Future<double> getQualityScore(String text) async {
    if (!_isInitialized) await initAllModels();

  // 1. Calculate Gold Vector (Once)
  if (_goldVector == null) {
    var vectors = <List<double>>[];
    for (var ex in _goldStandardExamples) {
      vectors.add(await duplicateDetector.getEmbedding(line: '', area: '', text: ex));
    }
    // Average them to create a "Perfect Safety Concept"
    _goldVector = List.filled(128, 0.0);
    for (var v in vectors) {
      for (int i = 0; i < 128; i++) _goldVector![i] += v[i];
    }
    // Normalize
    for (int i = 0; i < 128; i++) _goldVector![i] /= vectors.length;
    }

    // 2. Get User Vector
    // We only care about the text content for quality
    List<double> userVector = await duplicateDetector.getEmbedding(line: '', area: '', text: text);

    // 3. Compare
    double similarity = duplicateDetector.calculateSimilarity(userVector, _goldVector!);

    // 4. Map Similarity (0.3 to 0.8) to Score (0 to 100)
    // (Embeddings are rarely < 0.3 or > 0.9 for this type of data)
    double score = (similarity - 0.3) / (0.8 - 0.3);
    if (score < 0) score = 0;
    if (score > 1) score = 1;

    return score; 
  }

//   AI Gain (calculateScore):

// It doesn't just count reports. It multiplies the Hazard Level (High/Med/Low) by the Hazard Type (Unsafe Condition vs. Near Miss vs. First Aid).

// Example: A "High Risk" (5 points) "Near Miss" (5 points) = 25 Points (AI Gain). A simple "Low Risk" observation might only be 1 point.

// Impact Analysis (TrendAnalysis):

// It compares the Historical Risk Volume (last 4 weeks) against the AI Forecast (next week).

// If the trend is negative (risk going down) in an area where you submitted reports, the system attributes that "Impact" to you.

  /// --- 2. AI GAIN CALCULATION ENGINE ---
  /// Calculates the "Value" of a specific report based on its content.
  double calculateScore(dynamic report) {
    if (report == null) return 0.0;
    
    // Normalize inputs
    String level = (report['level'] ?? 'low').toString().toLowerCase().trim();
    String type = (report['type'] ?? 'unsafe_condition').toString().toLowerCase().trim();
    
    // Fetch weights
    int lWeight = levelWeights[level] ?? 1;
    int tWeight = typeWeights[type] ?? 1;
    
    // Formula: Impact * Severity
    return (lWeight * tWeight).toDouble();
  }


  /// Predicts hazard risk for the next week.
  /// [referenceDate] allows you to set a historical "now" point for testing.
  /// Adaptive Prediction Logic
  /// Attempts a 4-week window. If empty, expands to 2 months, then 3 months.
  /// Recursively expands the window from 4 weeks up to 4 months
  /// until enough "signals" are found to build a reliable trend.
  /// 
  /// Details:
  /// 
  /// **what those lines and points are telling you:**
  /// 1. The X-Axis: The Timeline
  /// T-4 to T-1 (The Past): These four points represent your Historical Signal Volume. They show the density of safety reports submitted in your analysis window (whether that window is Weekly, Bi-Monthly, or Quarterly).
  /// PREDICT (The Future): This is the "Leap of Intelligence." It represents the AI’s calculated risk score for the next period.
  /// 2. The Y-Axis: Signal Density vs. Risk Probability
  /// The graph is effectively tracking Hazard Momentum:
  /// T-Points (Counts): Tell you how active your safety sensors (your people) have been. A high T-point means a lot of observations were recorded.
  /// PREDICT Point (Score): This isn't a count of reports; it’s a Probability Score. It tells you how likely a high-severity incident is to occur based on the patterns found in those T-points.
  /// 3. Reading the "Shape" of the Trend
  // Rising Slope towards PREDICT: This is a Warning. Even if your historical reports (T-4 to T-1) were low, if the line shoots up to the PREDICT point, the AI has detected a "Silent Pattern." It means that although there are few reports, the nature of those reports (location, type of hazard) strongly matches the signature of a major upcoming incident.
  /// Falling Slope towards PREDICT: This is Positive Reinforcement. It suggests that the current hazards being reported are decreasing in risk-potential, or that the "Safety Pulse" of the site is stabilizing.
  /// The "Flat-line" at Zero: If your T-points are zero and the Predict is zero, it tells you the engine is Signal Starved. This is where your PersonalProfileView comes in—it tells the user: "We can't see the future because you haven't given us enough data from the present."
  /// 4. The Adaptive Window Context
  /// Look at the Window Label (Weekly, Bi-Monthly, or Quarterly) displayed in the header:
  /// Weekly Trend: Tells you about immediate volatility. (e.g., "We have a lot of tripping hazards this week because of the rain.")
  /// Quarterly Trend: Tells you about structural safety culture. (e.g., "Every three months during kiln maintenance, our risk of electrical fire spikes.")
  /// Pro-Tip for your Safety Department:
  /// If the Safety Department sees a trend line where T-1 is low but PREDICT is High, they should act immediately. This means the workers might have stopped reporting (low T-1), but the underlying risk is still there and reaching a "boiling point."
  Future<ForecastResult> predictAdaptive(List<ModelAtr> allReports, {DateTime? referenceDate}) async {
    if (!_isInitialized) await initAllModels();

    // Default to end of database test point: 18.12.2025
    final now = referenceDate ?? DateTime(2025, 06, 1);
    
    // 1. Level 1: Weekly Window (28 days)
    var res = await _runPrediction(allReports, now, 7, "Weekly Trend");
    if (res.totalSignals >= 8) return res; 

    // 2. Level 2: Bi-Monthly Fallback (60 days)
    logInfo("🔄 Weekly signals (${res.totalSignals}) below threshold. Expanding to 60-day window...");
    res = await _runPrediction(allReports, now, 15, "Bi-Monthly Trend");
    if (res.totalSignals >= 8) return res;

    // 3. Level 3: Quarterly Fallback (120 days)
    logInfo("🔄 Monthly signals (${res.totalSignals}) below threshold. Expanding to 120-day window...");
    return await _runPrediction(allReports, now, 30, "Quarterly Trend", minThreshold: 1);
  }

  Future<ForecastResult> _runPrediction(
    List<ModelAtr> reports, 
    DateTime now, 
    int daysPerBucket, 
    String label,
    {int minThreshold = 8}
  ) async {
    final areas = repoForecaster.areas;
    if (areas.isEmpty) return ForecastResult(risks: {}, bucketSums: [], windowLabel: label, totalSignals: 0);

    const int historySteps = 8;
    final matrix = List.generate(historySteps, (_) => List.filled(areas.length, 0.0));
    final List<double> bucketSums = List.filled(historySteps, 0.0);
    int total = 0;

    // Generate boundaries: [now-7, now-14, ..., now-56]
    final List<DateTime> boundaries = List.generate(
      historySteps, 
      (i) => now.subtract(Duration(days: daysPerBucket * (i + 1)))
    );

    for (var r in reports) {
      if (r.issueDate.isEmpty) continue;
      final d = _parseDate(r.issueDate);
      if (d == null || d.isAfter(now)) continue;

      int idx = -1;
      // Find which bucket this date falls into
      for (int i = 0; i < historySteps; i++) {
        if (!d.isBefore(boundaries[i])) {
          // i=0 is newest boundary (now-7), maps to last index (7)
          idx = (historySteps - 1) - i;
          break;
        }
      }
      
      // If older than the last boundary, ignore
      if (idx == -1) continue;

      if (idx != -1 && r.area != null) {
        // Robust matching to handle special characters like "/" in your CSV
        String cleanR = r.area!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        int areaIdx = areas.indexWhere((a) {
          String cleanA = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          return cleanA == cleanR || cleanR.contains(cleanA) || cleanA.contains(cleanR);
        });

        if (areaIdx != -1) {
          matrix[idx][areaIdx] += 1.0;
          bucketSums[idx] += 1.0;
          total++;
        }
      }
    }

    if (total < minThreshold) return ForecastResult(risks: {}, bucketSums: bucketSums, windowLabel: label, totalSignals: total);

    final risks = await repoForecaster.predict(matrix);
    return ForecastResult(risks: risks, bucketSums: bucketSums, windowLabel: label, totalSignals: total);
  }

  

  /// Robust Date Parser for multiple formats
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // 1. Try ISO Format (2025-01-05)
      final iso = DateTime.tryParse(dateStr);
      if (iso != null) return iso;

      // 2. Try Dot Format (05.01.2025)
      final parts = dateStr.split('.');
      if (parts.length >= 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2].split(' ')[0]);
        return DateTime(year, month, day);
      }
      
      // 3. Try Slash Format (05/01/2025)
      final slashParts = dateStr.split('/');
      if (slashParts.length >= 3) {
        int day = int.parse(slashParts[0]);
        int month = int.parse(slashParts[1]);
        int year = int.parse(slashParts[2].split(' ')[0]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      logError("Failed to parse date string: '$dateStr'");
    }
    return null;
  }


}

// --- Isolate Helpers ---

/// A wrapper to return both risks and the window used
class ForecastResult {
  final Map<String, List<double>> risks;
  final List<double> bucketSums; // Historical counts for trend graph
  final String windowLabel;
  final int totalSignals;

  ForecastResult({
    required this.risks, 
    required this.bucketSums, 
    required this.windowLabel, 
    required this.totalSignals
  });
}

class _SearchArgs {
  final List<ModelAtr> reports;
  final List<double> queryVector;
  _SearchArgs(this.reports, this.queryVector);
}


/// Helper class to track risk velocity per area
class _AreaAggregator {
  int count = 0;
  double totalRisk = 0.0;

  void add(double risk) {
    count++;
    totalRisk += risk;
  }
}
/// --- 4. PREDICTIVE TREND ANALYSIS ---
/// Used by the Dashboard to determine if risk is "Rising" or "Falling"
class TrendAnalysis {
  final String areaName;
  final List<double> history; // Last 4 weeks of risk volume
  final double prediction;    // Next week's AI prediction

  TrendAnalysis(this.areaName, this.history, this.prediction);

  // Returns the velocity of risk.
  // Positive = Risk is accelerating (Bad)
  // Negative = Risk is decelerating (Good - High Impact)
  double get trendPercentage {
    if (history.isEmpty) return 0.0;
    
    // Simple moving average of history
    double historicalAvg = history.reduce((a, b) => a + b) / history.length;
    
    if (historicalAvg == 0) return 100.0;
    
    // Compare Prediction vs History
    return ((prediction - historicalAvg) / historicalAvg) * 100;
  }
}
