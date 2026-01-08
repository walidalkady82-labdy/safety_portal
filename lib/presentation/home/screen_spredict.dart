import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_portal/core/themes.dart';

// --- ARCHITECTURE IMPORTS ---
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/presentation/home/cubit_home.dart';

// --- TRANSLATIONS DATA ---
class AppLocale {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'S-PREDICT',
      'command_center': 'COMMAND CENTER',
      'collab_intel': 'COLLABORATIVE INTEL',
      'tab_manager': 'Manager',
      'tab_profile': 'Profile',
      'tab_analytics': 'Analytics',
      'tab_forecast': 'Forecast',
      'tab_report': 'Report',
      'kpi_plant_safety': 'PLANT SAFETY',
      'kpi_risks': 'RISKS MITIGATED',
      'kpi_streak': 'ACTIVE STREAK',
      'kpi_ai': 'AI PREDICTION',
      'chart_strategic': 'Recent Risk Volume',
      'chart_trajectory': 'Daily Observation Volume',
      'champions_title': 'Top Safety Champions',
      'rank': 'Rank',
      'points': 'Points',
      'fixes': 'FIXES',
      'hazards': 'HAZARDS',
      'smart_entry': 'Smart Hazard Entry',
      'describe_hint': 'Describe the issue...',
      'field_dept': 'Department',
      'field_line': 'Plant Line',
      'field_area': 'Area',
      'quality_meter': 'AI QUALITY METER',
      'interventions': 'AI Interventions',
      'rising_fast': 'Rising Fast',
      'precision_gap': 'Precision Gap vs Team',
      'strength': 'PRIMARY STRENGTH',
      'opportunity': 'OPPORTUNITY',
      'dna_title': 'Expertise DNA',
      'dna_sub': 'Your proactivity fingerprint by Category',
      'forecast_title': 'Area Risk Forecast',
      'forecast_sub': 'Predictive analysis for your zone',
      'login_title': 'S-Predict Login',
      'login_btn': 'Sign In',
      'logout': 'Logout',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'help_support': 'Help & Support',
      'edit_profile': 'Edit Profile',
    },
    'ar': {
      'app_title': 'إس-بريديكت',
      'command_center': 'مركز القيادة',
      'collab_intel': 'الذكاء التعاوني',
      'tab_manager': 'المدير',
      'tab_profile': 'الملف',
      'tab_analytics': 'التحليلات',
      'tab_forecast': 'التوقعات',
      'tab_report': 'تقرير',
      'kpi_plant_safety': 'سلامة المنشأة',
      'kpi_risks': 'المخاطر التي تم تقليلها',
      'kpi_streak': 'سلسلة النشاط',
      'kpi_ai': 'توقعات الذكاء الاصطناعي',
      'chart_strategic': 'حجم المخاطر الحديثة',
      'chart_trajectory': 'حجم الملاحظات اليومية',
      'champions_title': 'أبطال السلامة',
      'rank': 'الرتبة',
      'points': 'النقاط',
      'fixes': 'الإصلاحات',
      'hazards': 'المخاطر',
      'smart_entry': 'إدخال المخاطر الذكي',
      'describe_hint': 'صف المشكلة أو الملاحظة...',
      'field_dept': 'القسم',
      'field_line': 'خط الإنتاج',
      'field_area': 'المنطقة',
      'quality_meter': 'مقياس جودة الذكاء الاصطناعي',
      'interventions': 'تدخلات الذكاء الاصطناعي',
      'rising_fast': 'صاعد بسرعة',
      'precision_gap': 'فجوة الدقة مقابل الفريق',
      'strength': 'نقطة القوة الرئيسية',
      'opportunity': 'فرصة التطوير',
      'dna_title': 'بصمة الخبرة',
      'dna_sub': 'بصمة استباقيتك حسب الفئة',
      'forecast_title': 'توقعات مخاطر المنطقة',
      'forecast_sub': 'التحليل التنبؤي لمنطقتك',
      'login_title': 'تسجيل دخول إس-بريديكت',
      'login_btn': 'دخول',
      'logout': 'خروج',
      'settings': 'الإعدادات',
      'notifications': 'الإشعارات',
      'help_support': 'المساعدة والدعم',
      'edit_profile': 'تعديل الملف الشخصي',
    }
  };

  static String t(String key, String lang) => _strings[lang]?[key] ?? key;
}

//TODO  remove --- LOGIN SCREEN ---
class LoginScreen1 extends StatelessWidget {
  const LoginScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocale.t('app_title', lang), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 40),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(hintText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(hintText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                  obscureText: true
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                     context.read<AuthCubit>().login(emailCtrl.text, passCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: Text(AppLocale.t('login_btn', lang)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> pages = [
    const ManagerDashboard(),
    const PersonalProfileView(),
    const AnalyticsView(),
    const ForecastView(),
    const SmartReportView(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocale.t('app_title', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              _currentIndex == 0 ? AppLocale.t('command_center', lang) : AppLocale.t('collab_intel', lang),
              style: const TextStyle(fontSize: 10, color: Colors.grey)
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<LocaleCubit>().toggleLanguage(),
            icon: Text(lang == 'en' ? "AR" : "EN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
              child: const CircleAvatar(
                backgroundColor: Color(0xFF2563EB),
                child: Text('AH', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: AppLocale.t('tab_manager', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: AppLocale.t('tab_profile', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: AppLocale.t('tab_analytics', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.waves_rounded), label: AppLocale.t('tab_forecast', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.bolt_rounded), label: AppLocale.t('tab_report', lang)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 1. MANAGER DASHBOARD ---
class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<DataCubit, List<ModelAtr>>(
      builder: (context, observations) {
        // Calculate KPIs
        final totalRisks = observations.length;
        final criticals = observations.where((o) => (o.level == 'High' || o.type == 'FA')).length;
        final mitigated = observations.where((o) => o.status == 'Closed').length;
        final safetyScore = totalRisks == 0 ? 100 : (100 - (criticals / totalRisks * 100)).clamp(0, 100).toInt();
        
        // Chart Data
        final Map<String, int> dateCounts = {};
        for (var o in observations) {
           dateCounts[o.issueDate] = (dateCounts[o.issueDate] ?? 0) + 1;
        }
        final chartData = dateCounts.entries.toList()..sort((a,b) => a.key.compareTo(b.key));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: width > 600 ? 4 : 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                KpiCard(title: AppLocale.t('kpi_plant_safety', lang), value: '$safetyScore%', icon: Icons.shield_outlined, color: AppColors.emeraldColor),
                KpiCard(title: AppLocale.t('kpi_risks', lang), value: '$mitigated / $totalRisks', icon: Icons.bolt_outlined, color: Colors.blue),
                KpiCard(title: AppLocale.t('kpi_streak', lang), value: 'Active', icon: Icons.local_fire_department_outlined, color: Colors.orange),
                KpiCard(title: AppLocale.t('kpi_ai', lang), value: criticals > 0 ? 'CRITICAL' : 'STABLE', icon: Icons.warning_amber_outlined, color: criticals > 0 ? Colors.red : Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            NativeChartCard(
              title: AppLocale.t('chart_strategic', lang),
              subtitle: AppLocale.t('chart_trajectory', lang),
              data: chartData.map((e) => MapEntry(e.key.length > 5 ? e.key.substring(5) : e.key, e.value.toDouble())).toList(),
            ),
             const SizedBox(height: 20),
            ...observations.take(5).map((o) => _ObservationTile(o)),
          ],
        );
      },
    );
  }

  Widget _ObservationTile(ModelAtr obs) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: obs.level == 'High' ? Colors.red.shade50 : Colors.blue.shade50,
          backgroundImage: obs.imageUrl != null ? NetworkImage(obs.imageUrl!) : null, // Display Photo
          child: obs.imageUrl == null ? Icon(Icons.description, size: 16, color: obs.level == 'High' ? Colors.red : Colors.blue) : null,
        ),
        title: Text(obs.observation, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text("${obs.area ?? 'Gen'} • ${obs.issueDate}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: obs.status == 'Closed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(obs.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: obs.status == 'Closed' ? Colors.green : Colors.orange)),
        ),
      ),
    );
  }
}

// --- 2. FORECAST VIEW ---
class ForecastView extends StatelessWidget {
  const ForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);

    return BlocBuilder<ForecastCubit, ForecastState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = state.risks.entries.map((e) => MapEntry(e.key, e.value * 10)).toList();

        return RefreshIndicator(
          onRefresh: () => context.read<ForecastCubit>().loadForecast(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
               NativeBarChartCard(
                 title: AppLocale.t('forecast_title', lang),
                 subtitle: AppLocale.t('forecast_sub', lang),
                 data: data,
               ),
               const SizedBox(height: 20),
               if (data.isEmpty) 
                 const Center(child: Text("Not enough data history to forecast.", style: TextStyle(color: Colors.grey))),
            ],
          ),
        );
      },
    );
  }
}

// --- 3. SMART REPORT VIEW (UPDATED) ---
class SmartReportView extends StatefulWidget {
  const SmartReportView({super.key});
  @override
  State<SmartReportView> createState() => _SmartReportViewState();
}

class _SmartReportViewState extends State<SmartReportView> {
  final _textCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  String? _dept = "Mechanical";
  
  final List<String> _departments = [
    "Plant_Manag", "Safety", "Environment", "Production", "Mechanical", "Electrical",
    "PM", "Quality", "Stores", "HR", "Dispatch", "Purchasing", "Security", "Finance",
    "Legal", "Contractor"
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);
    final user = context.select((AuthCubit c) => c.currentUserName);

    return BlocConsumer<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${state.error}")));
        }
        if (state.isSuccess) {
           _textCtrl.clear();
           context.read<ReportCubit>().clearImage(); // Clear image on success
           context.read<ReportCubit>().resetSuccess(); // Explicitly reset success state
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Submitted Successfully")));
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocale.t('smart_entry', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // --- DEPARTMENTS & LOCATIONS ---
              DropdownButtonFormField<String>(
                value: _dept,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => _dept = val),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _input(_lineCtrl, AppLocale.t('field_line', lang))),
                  const SizedBox(width: 10),
                  Expanded(child: _input(_areaCtrl, AppLocale.t('field_area', lang))),
                ],
              ),
              const SizedBox(height: 12),
              
              // --- OBSERVATION TEXT ---
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                onChanged: (val) => context.read<ReportCubit>().analyzeText(_lineCtrl.text, _areaCtrl.text, val),
                decoration: InputDecoration(
                  hintText: AppLocale.t('describe_hint', lang),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              
              // --- PHOTO PICKER UI ---
              const SizedBox(height: 16),
              if (state.selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb 
                        ? Image.network(state.selectedImage!.path, height: 200, width: double.infinity, fit: BoxFit.cover) 
                        : Image.file(File(state.selectedImage!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => context.read<ReportCubit>().clearImage(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                )
              else 
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<ReportCubit>().pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(AppLocale.t('pick_camera', lang)),
                        style: OutlinedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<ReportCubit>().pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: Text(AppLocale.t('pick_gallery', lang)),
                         style: OutlinedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                    ),
                  ],
                ),


              // --- QUALITY METER ---
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocale.t('quality_meter', lang), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text("${(state.quality * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: state.quality, 
                backgroundColor: Colors.grey.shade200,
                color: state.quality > 0.7 ? AppColors.emeraldColor : Colors.amber, 
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
              ),
              
              // --- AI SUGGESTIONS ---
              if (state.interventions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(AppLocale.t('interventions', lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ...state.interventions.take(3).map((i) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12))),
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 14)
                    ],
                  ),
                )),
              ],
              
              if (state.smartSolution != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.smartSolution!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)))
                    ],
                  ),
                )
              ],

              // --- SUBMIT ---
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ? null : () {
                     final report = ModelAtr(
                       observation: _textCtrl.text,
                       line: _lineCtrl.text,
                       area: _areaCtrl.text,
                       respDepartment: _dept,
                       reporter: user,
                       status: "Pending",
                       issueDate: DateTime.now().toIso8601String().split('T')[0],
                       type: "Pending AI"
                     );
                     context.read<ReportCubit>().submitReport(report);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: state.isSubmitting 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                     : const Text("SUBMIT"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _input(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
// --- 4. ANALYTICS VIEW ---
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);
    
    return BlocBuilder<DataCubit, List<ModelAtr>>(
      builder: (context, observations) {
        final Map<String, double> typeCounts = {};
        for(var o in observations) {
          final t = o.type ?? 'Unknown';
          typeCounts[t] = (typeCounts[t] ?? 0) + 1;
        }
        final dnaData = typeCounts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
        final strength = dnaData.isNotEmpty ? dnaData.first.key : "N/A";
        final opportunity = dnaData.length > 1 ? dnaData.last.key : strength;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NativeBarChartCard(
              title: AppLocale.t('dna_title', lang),
              subtitle: AppLocale.t('dna_sub', lang),
              data: dnaData.take(5).map((e) => MapEntry(e.key.length > 8 ? e.key.substring(0,8) : e.key, e.value)).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _InsightCard(title: AppLocale.t('strength', lang), value: strength, color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _InsightCard(title: AppLocale.t('opportunity', lang), value: opportunity, color: Colors.amber)),
              ],
            )
          ],
        );
      },
    );
  }
}

// --- 5. PROFILE VIEW ---
class PersonalProfileView extends StatelessWidget {
  const PersonalProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select((LocaleCubit c) => c.state);
    final user = context.select((AuthCubit c) => c.currentUserName);

    return BlocBuilder<DataCubit, List<ModelAtr>>(
      builder: (context, observations) {
        final myReports = observations.where((o) => o.reporter == user).toList();
        final points = myReports.length * 10;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
             Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(30)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Proactive Level', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  Text(user, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text('$points Pts', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(AppLocale.t('kpi_streak', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...myReports.take(5).map((o) => ListTile(
              title: Text(o.observation),
              subtitle: Text(o.issueDate),
              trailing: Icon(Icons.check_circle, color: o.status == 'Closed' ? Colors.green : Colors.grey),
            ))
          ],
        );
      },
    );
  }
}

// --- USER PROFILE SCREEN (Detail) ---
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.currentUserName);
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Settings")),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(radius: 50, child: Text("AH")),
            const SizedBox(height: 10),
            Text(user, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<AuthCubit>().logout();
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class KpiCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const KpiCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade100)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class NativeChartCard extends StatelessWidget {
  final String title, subtitle;
  final List<MapEntry<String, double>> data;
  const NativeChartCard({super.key, required this.title, required this.subtitle, required this.data});

  @override
  Widget build(BuildContext context) {
    double maxVal = data.isEmpty ? 1.0 : data.map((e) => e.value).reduce(math.max);
    if (maxVal <= 0) maxVal = 1.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.isEmpty 
              ? [const Center(child: Text("No Data"))]
              : data.map((e) {
                final double h = (e.value / maxVal) * 120;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(e.value.toInt().toString(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: h < 5 ? 5 : h,
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 8),
                    Text(e.key, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

class NativeBarChartCard extends StatelessWidget {
  final String title, subtitle;
  final List<MapEntry<String, double>> data;
  const NativeBarChartCard({super.key, required this.title, required this.subtitle, required this.data});

  @override
  Widget build(BuildContext context) {
    double maxVal = data.isEmpty ? 1.0 : data.map((e) => e.value).reduce(math.max);
    if (maxVal <= 0) maxVal = 1.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          ...data.map((e) {
            final double wFactor = (e.value / maxVal).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(widthFactor: wFactor, child: Container(height: 8, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value.toInt().toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title, value;
  final Color color;
  const _InsightCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}