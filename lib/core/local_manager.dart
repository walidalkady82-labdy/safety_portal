import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocaleManager extends ValueNotifier<String> {
  LocaleManager._internal() : super('en');
  static final LocaleManager instance = LocaleManager._internal();

  // Our dynamic map that replaces the hardcoded one
  static Map<String, Map<String, String>> _strings = {};

  // Load and Parse CSV
  Future<void> loadTranslations() async {
    try {
      final rawData = await rootBundle.loadString('assets/lang.csv');
      
      // Split by lines and remove empty rows
      List<String> lines = rawData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      // Initialize language maps (assuming headers are key, en, ar)
      _strings = {'en': {}, 'ar': {}};

      // Skip header (i=0) and parse rows
      for (int i = 1; i < lines.length; i++) {
        List<String> values = lines[i].split(',');
        if (values.length >= 3) {
          String key = values[0].trim();
          _strings['en']![key] = values[1].trim();
          _strings['ar']![key] = values[2].trim();
        }
      }
    } catch (e) {
      debugPrint("Error loading CSV: $e");
    }
  }

  void toggleLanguage() => value = (value == 'en' ? 'ar' : 'en');

  static String translate(String key) => _strings[instance.value]?[key] ?? key;
  
}
class Loc {
  static const String appTitle = 'app_title';
  static const String loginBtn = 'login_btn';
  // ... rest of your keys
}

// const Map<String, Map<String, String>> _strings = {
//     'en': {
//       'app_title': 'HSE-PORTAL',
//       'command_center': 'COMMAND CENTER',
//       'collab_intel': 'COLLABORATIVE INTEL',
//       'tab_manager': 'Manager',
//       'tab_profile': 'Profile',
//       'tab_analytics': 'Analytics',
//       'tab_forecast': 'Forecast',
//       'tab_report': 'Report',
//       'kpi_plant_safety': 'PLANT SAFETY',
//       'kpi_risks': 'RISKS MITIGATED',
//       'kpi_streak': 'ACTIVE STREAK',
//       'kpi_ai': 'AI PREDICTION',
//       'chart_strategic': 'Recent Risk Volume',
//       'chart_trajectory': 'Daily Observation Volume',
//       'smart_entry': 'Smart Hazard Entry',
//       'describe_hint': 'Describe the issue...',
//       'field_dept': 'Department',
//       'field_person' : 'Responsible Person',
//       'field_line': 'Plant Line',
//       'field_area': 'Area',
//       'quality_meter': 'AI QUALITY METER',
//       'interventions': 'AI Interventions',
//       'login_btn': 'Sign In',
//       'pick_camera': 'Camera',
//       'pick_gallery': 'Gallery',
//       'strength': 'PRIMARY STRENGTH',
//       'opportunity': 'OPPORTUNITY',
//       'dna_title': 'Expertise DNA',
//       'dna_sub': 'Your proactivity fingerprint by Category',
//       'forecast_title': 'Area Risk Forecast',
//       'forecast_sub': 'Predictive analysis for your zone',
//       'confirmText' : 'Confirm',
//       'cancel' : 'Cancel',
//       'recent_activity': 'Recent Activity',
//       'latest_obs': 'Latest observations',
//       'chart_risk_vol': 'Risk Volume',
//       'chart_risk_vol_sub': 'Daily observations over the last 7 days',
//       'gen': 'Gen',
//       'risk_cat': 'Risk Categories',
//       'risk_cat_sub': 'Distribution by Hazard Type',
//       'na': 'N/A',
//       'ai_scanning': 'AI Scanning...',
//       'report_success': 'Report Submitted Successfully',
//       'error_prefix': 'Error: ',
//       'review_submit': 'REVIEW AND SUBMIT',
//       'contrib_analysis': 'CONTRIBUTION ANALYSIS',
//       'contrib_analysis_sub': 'Tracking your reporting impact on site intelligence',
//       'sensors_fed': 'Sensors Fed',
//       'ai_gain': 'AI Gain',
//       'site_rank': 'Site Rank',
//       'impact_text': 'Your data points directly improved the hazard detection accuracy for the Limestone Crusher area by 14% this month.',
//       'badge_leader': 'Safety Intelligence Leader',
//       'badge_leader_desc': 'Your reports are considered high-trust sensors by the engine.',
//       'badge_guard': 'Predictive Guard',
//       'badge_guard_desc': 'You\'ve reported 4 hazards that the AI later flagged as risk areas.',
//       'no_data': 'No Data Available',
//       'back': 'Back',
//       'analysis_suffix': 'ANALYSIS',
//       'trajectory_prefix': 'Trajectory based on',
//       'signals': 'signals',
//       'area_risk_dist': 'AREA RISK DISTRIBUTION',
//       'area_risk_dist_sub': 'Projected probability scores',
//       'scanning_history': 'Scanning history for trend patterns...',
//       'window': 'Window',
//       'line_hint': 'Select Line',
//       'area_hint': 'Select Area',
//       'dup_title': 'Confirm Submission',
//       'lbl_line': 'Line',
//       'lbl_area': 'Area',
//       'lbl_issue': 'Issue',
//       'lbl_type': 'Type',
//       'lbl_hazard': 'Hazard',
//       'lbl_level': 'Level',
//       'lbl_dept': 'Department',
//       'lbl_deptPerson': 'Responsible',
//       'dashboard_title': 'Executive Risk Overview',
//       'kpi_active_reports': 'Active Reports',
//       'kpi_risk_velocity': 'Risk Velocity',
//       'kpi_high_risk_area': 'High Risk Area',
//       'sub_pending_action': 'Pending Action',
//       'sub_ai_history': 'Based on AI History',
//       'sub_ai_identified': 'AI Identified',
//       'chart_velocity': 'Velocity of Risk',
//       'chart_velocity_sub': 'Historical volume trends (AI Analysis)',
//       'chart_attention': 'Attention Map',
//       'chart_attention_sub': 'Risk concentration by Area',
//       'watchlist_title': 'Priority Watchlist',
//       'watchlist_empty': 'No high-priority threats detected.',
//       'lbl_rising': 'Rising',
//       'lbl_falling': 'Falling',
//       'lbl_stable': 'Stable',
//       'lbl_scanning': 'Scanning...',
//       'lbl_none': 'None',
//       'log_new_risk': 'Log New Risk',
//     },
//     'ar': {
//       'app_title': 'منصة السلامة',
//       'command_center': 'مركز القيادة',
//       'collab_intel': 'الذكاء التعاوني',
//       'tab_manager': 'المدير',
//       'tab_profile': 'الملف',
//       'tab_analytics': 'التحليلات',
//       'tab_forecast': 'التوقعات',
//       'tab_report': 'تقرير',
//       'kpi_plant_safety': 'سلامة المنشأة',
//       'kpi_risks': 'المخاطر التي تم تقليلها',
//       'kpi_streak': 'سلسلة النشاط',
//       'kpi_ai': 'توقعات الذكاء الاصطناعي',
//       'chart_strategic': 'حجم المخاطر الحديثة',
//       'chart_trajectory': 'حجم الملاحظات اليومية',
//       'smart_entry': 'إدخال المخاطر الذكي',
//       'describe_hint': 'صف المشكلة أو الملاحظة...',
//       'field_dept': 'القسم',
//       'field_person' :'المسؤل عن التنفيذ',
//       'field_line': 'خط الإنتاج',
//       'field_area': 'المنطقة',
//       'quality_meter': 'مقياس جودة الذكاء الاصطناعي',
//       'interventions': 'تدخلات الذكاء الاصطناعي',
//       'login_btn': 'دخول',
//       'pick_camera': 'كاميرا',
//       'pick_gallery': 'معرض',
//       'strength': 'نقطة القوة الرئيسية',
//       'opportunity': 'فرصة التطوير',
//       'dna_title': 'بصمة الخبرة',
//       'dna_sub': 'بصمة استباقيتك حسب الفئة',
//       'forecast_title': 'توقعات مخاطر المنطقة',
//       'forecast_sub': 'التحليل التنبؤي لمنطقتك',
//       'confirmText' : 'تأكيد',
//       'cancel' : 'الغاء',
//       'recent_activity': 'النشاط الأخير',
//       'latest_obs': 'أحدث الملاحظات',
//       'chart_risk_vol': 'حجم المخاطر',
//       'chart_risk_vol_sub': 'الملاحظات اليومية خلال آخر 7 أيام',
//       'gen': 'عام',
//       'risk_cat': 'فئات المخاطر',
//       'risk_cat_sub': 'التوزيع حسب نوع الخطر',
//       'na': 'غير متاح',
//       'ai_scanning': 'جاري المسح بالذكاء الاصطناعي...',
//       'report_success': 'تم إرسال التقرير بنجاح',
//       'error_prefix': 'خطأ: ',
//       'review_submit': 'مراجعة وإرسال',
//       'contrib_analysis': 'تحليل المساهمة',
//       'contrib_analysis_sub': 'تتبع تأثير تقاريرك على ذكاء الموقع',
//       'sensors_fed': 'المستشعرات المغذاة',
//       'ai_gain': 'مكسب الذكاء',
//       'site_rank': 'تصنيف الموقع',
//       'impact_text': 'حسنت نقاط بياناتك دقة اكتشاف المخاطر لمنطقة كسارة الحجر الجيري بنسبة 14٪ هذا الشهر.',
//       'badge_leader': 'قائد ذكاء السلامة',
//       'badge_leader_desc': 'تعتبر تقاريرك مستشعرات عالية الثقة بواسطة المحرك.',
//       'badge_guard': 'الحارس التنبؤي',
//       'badge_guard_desc': 'لقد أبلغت عن 4 مخاطر حددها الذكاء الاصطناعي لاحقًا كمناطق خطر.',
//       'no_data': 'لا توجد بيانات متاحة',
//       'back': 'رجوع',
//       'analysis_suffix': 'تحليل',
//       'trajectory_prefix': 'المسار بناءً على',
//       'signals': 'إشارات',
//       'area_risk_dist': 'توزيع مخاطر المنطقة',
//       'area_risk_dist_sub': 'درجات الاحتمال المتوقعة',
//       'scanning_history': 'مسح التاريخ بحثًا عن أنماط الاتجاه...',
//       'window': 'نافذة',
//       'line_hint': 'اختر الخط',
//       'area_hint': 'اختر المنطقة',
//       'dup_title': 'تأكيد الإرسال',
//       'lbl_line': 'الخط',
//       'lbl_area': 'المنطقة',
//       'lbl_issue': 'المشكلة',
//       'lbl_type': 'النوع',
//       'lbl_hazard': 'الخطر',
//       'lbl_level': 'المستوى',
//       'lbl_dept': 'القسم',
//       'lbl_deptPerson': 'المسؤول',
//       'dashboard_title': 'نظرة عامة على المخاطر التنفيذية',
//       'kpi_active_reports': 'التقارير النشطة',
//       'kpi_risk_velocity': 'سرعة المخاطر',
//       'kpi_high_risk_area': 'منطقة عالية المخاطر',
//       'sub_pending_action': 'بانتظار الإجراء',
//       'sub_ai_history': 'بناءً على تاريخ الذكاء الاصطناعي',
//       'sub_ai_identified': 'تم تحديده بواسطة AI',
//       'chart_velocity': 'سرعة المخاطر',
//       'chart_velocity_sub': 'اتجاهات الحجم التاريخية (تحليل AI)',
//       'chart_attention': 'خريطة الاهتمام',
//       'chart_attention_sub': 'تركز المخاطر حسب المنطقة',
//       'watchlist_title': 'قائمة المراقبة ذات الأولوية',
//       'watchlist_empty': 'لم يتم اكتشاف تهديدات ذات أولوية عالية.',
//       'lbl_rising': 'صاعد',
//       'lbl_falling': 'هابط',
//       'lbl_stable': 'مستقر',
//       'lbl_scanning': 'جاري المسح...',
//       'lbl_none': 'لا يوجد',
//       'log_new_risk': 'تسجيل خطر جديد',
//     }
//   };

extension TranslationExtension on String {
  // Now you can use 'key'.t() anywhere
  String t() => LocaleManager.translate(this);
}

extension LocaleContext on BuildContext {
  // Now you can use context.toggleLang()
  void toggleLang() => LocaleManager.instance.toggleLanguage();
}