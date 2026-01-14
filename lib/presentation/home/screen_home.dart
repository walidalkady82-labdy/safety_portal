import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safety_portal/core/themes.dart';

// --- ARCHITECTURE IMPORTS ---
import 'package:safety_portal/presentation/auth/auth_cubit.dart';
import 'package:safety_portal/presentation/home/cubit_home.dart'; // Point to unified file
import 'package:safety_portal/core/local_manager.dart';
import 'package:safety_portal/presentation/home/cubit_report.dart';
import 'package:safety_portal/presentation/home/screen_risk_dashboard.dart';


// --- WIDGET IMPORTS ---
// Assuming these widgets exist as per your upload or inline them
import 'package:safety_portal/presentation/home/widgets/section_header.dart';
import 'package:safety_portal/presentation/home/widgets/chart/trend_forecast_view.dart';

import 'widgets/safety_quality_meter.dart';

// --- MAIN SCREEN ---

class ScreenHome extends StatelessWidget {
  const ScreenHome({super.key});

  void _showReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const _ScreenReport(),
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isWeb) {
    return CustomScrollView(
      controller: ScrollController(),
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: isWeb,
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.emerald),
              const SizedBox(width: 8),
              Text(
                "risk_guard".t(),
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 32.0 : 0.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                const ScreenRiskDashboard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final auth = context.watch<AuthCubit>().state;
    final _currentIndex = context.watch<HomeCubit>().state.currentIndex;
    // Define pages for navigation
    final List<Widget> pages = [
      if (auth.canViewAnalytics || kDebugMode) _buildDashboard(isWeb),
      const _ScreenProfile(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocListener<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state.issueFormState == IssueFormState.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Report Submitted Successfully")),
            );
            context.read<HomeCubit>().init();
          }
        },
        child: Row(
          children: [
            if (isWeb) _buildWebSideNav(context),
            Expanded(
              child: pages[_currentIndex], // Dynamic Switching
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWeb
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: context.read<HomeCubit>().updateIndex,
              selectedItemColor: AppColors.emerald,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
            ),
      floatingActionButton: isWeb
          ? FloatingActionButton.extended(
              onPressed: () => _showReportModal(context),
              label: const Text("New Risk"),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.redAccent,
            )
          : FloatingActionButton(
              onPressed: () => _showReportModal(context),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: isWeb
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildWebSideNav(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final homeLogic = context.read<HomeCubit>();
    return NavigationRail(
      selectedIndex: homeLogic.state.currentIndex,
      onDestinationSelected: homeLogic.updateIndex,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text("Home"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics),
          label: Text("Analytics"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications),
          label: Text("Alerts"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person),
          label: Text("Profile"),
        ),
      ],
    );
  }
}

class _ScreenProfile extends StatelessWidget {
  const _ScreenProfile();

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    if (isWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeader(context, isWeb: true)),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: _buildContent('impact_text'.t(), isWeb: true),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, isWeb: false),
          _buildContent('impact_text'.t(), isWeb: false),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isWeb}) {
    final _usr = context.read<AuthCubit>().state.user;
    int userReportsCount = 0;
    String aiGain = "+0%";
    String siteRank = "--";
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: isWeb
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundImage: NetworkImage(
              'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
            ),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            _usr?.displayName ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _usr?.email ?? "",
            style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
          ),
          const SizedBox(height: 32),
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              // Assumes ModelAtr has a `userId` field.
              final userReportsCount = homeState.recentReports
                  .where((report) => report.userId == _usr?.uid)
                  .length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(userReportsCount.toString(), 'sensors_fed'.t()),
                  _buildMetric( "+14%",'ai_gain'.t(),color: Colors.greenAccent),
                  _buildMetric("#3", 'site_rank'.t()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String val, String label, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(String sImpact, {required bool isWeb}) {
    return Padding(
      padding: EdgeInsets.all(isWeb ? 0 : 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Impact Analysis",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sImpact,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildBadgesGrid(),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildBadge(
          "Safety Leader",
          "Top 5%",
          Icons.emoji_events,
          Colors.amber,
        ),
        _buildBadge("Guardian", "10 Saves", Icons.shield, Colors.purple),
        _buildBadge(
          "Predictor",
          "High Accuracy",
          Icons.analytics,
          Colors.indigo,
        ),
        _buildBadge("Reporter", "50+ Reports", Icons.article, Colors.teal),
      ],
    );
  }

  Widget _buildBadge(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ScreenReport extends StatelessWidget {
  const _ScreenReport();

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return BlocConsumer<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state.issueFormState == IssueFormState.success) {
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (isWeb) return _buildWebLayout(context);
        return _buildMobileLayout(context);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final reportLogic = context.read<ReportCubit>();
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePicker(context),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Observation",
                hintText: 'describe_hint'
                    .t(), //"Describe the hazard (e.g. 'Oil leak on Line 4')",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: reportLogic.updateObservation,
            ),
            if (reportLogic.state.smartSolution != null) ...[
              const SizedBox(height: 16),
              _buildAIResult(context),
            ],
            const SizedBox(height: 32),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final reportLogic = context.read<ReportCubit>();
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "New Hazard Report",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                _buildImagePicker(context),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: "Observation",
                    hintText: 'describe_hint'
                        .t(), //"Describe the hazard (e.g. 'Oil leak on Line 4')",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: reportLogic.updateObservation,
                ),
                const SizedBox(height: 32),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: reportLogic.state.smartSolution != null
                  ? _buildAIResult(context)
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "AI Analysis will appear here...",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final _local = context.read<LocaleCubit>();
    final _reportLogic = context.read<ReportCubit>();
    return GestureDetector(
      onTap: () => _reportLogic.pickImage(ImageSource.camera),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _reportLogic.state.selectedImage == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "Tap to capture evidence",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: kIsWeb
                    ? Image.network(
                        _reportLogic.state.selectedImage!.path,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_reportLogic.state.selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
              ),
      ),
    );
  }

  Widget _buildAIResult(BuildContext context) {
    final reportLogic = context.read<ReportCubit>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "AI Analysis",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reportLogic.state.smartSolution ?? "Analyzing...",
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final reportLogic = context.read<ReportCubit>();
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => context.read<ReportCubit>().submitReport,
        child: reportLogic.state.issueFormState == IssueFormState.isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Submit Report",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}



// --- SUB-WIDGETS ---

// class _VelocityChart extends StatelessWidget {
//   const _VelocityChart();
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<CubitAnalytics, StateAnalytics>(
//       builder: (context, state) {
//         if (state.isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
//         final history = state.history;
//         if (history.isEmpty || history.every((e) => e == 0)) {
//           return const Center(child: Text("No Trend Data Available", style: TextStyle(fontSize: 12, color: Colors.grey)));
//         }
//         List<FlSpot> spots = [];
//         for (int i = 0; i < history.length; i++) spots.add(FlSpot(i.toDouble(), history[i]));
//         return LineChart(LineChartData(
//             gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
//             titlesData: FlTitlesData(show: false),
//             borderData: FlBorderData(show: false),
//             lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.redAccent, barWidth: 3, isStrokeCapRound: true, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.1)))]
//         ));
//       },
//     );
//   }
// }


// --- 1. MANAGER DASHBOARD ---
// class _ManagerDashboard extends StatelessWidget {
//   const _ManagerDashboard();

//   @override
//   Widget build(BuildContext context) {
//     final lang = context.select((LocaleCubit c) => c.state);
//     final width = MediaQuery.of(context).size.width;
//     final auth = context.watch<AuthCubit>().state;
//       // --- LOCALIZATION DICTIONARY ---
//     return BlocBuilder<HomeCubit, HomeState>(
//       builder: (context, state) {
//         if (state.isLoading && state.analytics == null) {
//           return const Center(child: CircularProgressIndicator());
//         }
        
//         // Handle null/empty gracefully
//         final summary = state.analytics ?? ModelAnalyticsSummary.empty();

//         return RefreshIndicator(
//           onRefresh: () async => context.read<HomeCubit>().init(),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//           children: [
//             // KPI Grid
//             LayoutBuilder(builder: (context, constraints) {
//               int cols = width > 600 ? 4 : 2;
//               return GridView.count(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisCount: cols,
//                 childAspectRatio: 1.5,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 children: [
//                   KPICard(
//                       title: 'kpi_plant_safety'.t(), 
//                       subtext: '',
//                       value: '${summary.plantSafetyScore.toInt()}%', 
//                       icon: Icons.shield_outlined, 
//                       color: AppColors.emerald, 
//                   ),
//                   KpiCard(
//                       title: LocaleCubit.t('kpi_risks', lang), 
//                       value: '${summary.mitigatedRisks} / ${summary.totalOpenRisks + summary.mitigatedRisks}', 
//                       icon: Icons.bolt_outlined, 
//                       color: Colors.blue
//                   ),
//                   KpiCard(
//                       title: LocaleCubit.t('kpi_streak', lang), 
//                       value: 'Active', 
//                       icon: Icons.local_fire_department_outlined, 
//                       color: Colors.orange
//                   ),
//                   KpiCard(
//                       title: LocaleCubit.t('kpi_ai', lang), 
//                       value: summary.criticalCount > 0 ? 'CRITICAL' : 'STABLE', 
//                       icon: Icons.warning_amber_outlined, 
//                       color: summary.criticalCount > 0 ? Colors.red : Colors.green
//                   ),
//                 ],
//               );
//             }),
        
//             const SizedBox(height: 20),
//             _AnalyticsView(),
//             const SizedBox(height: 20),
//             // Charts
//             _RiskVolumeChart(summary: summary),
             
//             const SizedBox(height: 20),
            
//             // Recent Reports
//             SectionHeader(title: LocaleCubit.t('recent_activity', lang), subTitle: LocaleCubit.t('latest_obs', lang)),
//             const SizedBox(height: 10),
//             ...state.recentReports.take(5).map((o) => _ObservationTile(o, lang)),
//           ],
//         ),
//           ),
//         ));
//       },
//     );
//   }

//   Widget _ObservationTile(ModelAtr obs, String lang) {
//     return Card(
//       elevation: 0,
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: obs.level == 'High' ? Colors.red.shade50 : Colors.blue.shade50,
//           backgroundImage: (obs.imageUrl != null && obs.imageUrl!.trim().isNotEmpty) ? NetworkImage(obs.imageUrl!) : null,
//           child: (obs.imageUrl == null || obs.imageUrl!.trim().isEmpty) ? Icon(Icons.description, size: 16, color: obs.level == 'High' ? Colors.red : Colors.blue) : null,
//         ),
//         title: Text(obs.observation, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//         subtitle: Text("${obs.area ?? LocaleCubit.t('gen', lang)} • ${obs.issueDate}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
//         trailing: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//           decoration: BoxDecoration(color: obs.status == 'Closed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
//           child: Text(obs.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: obs.status == 'Closed' ? Colors.green : Colors.orange)),
//         ),
//       ),
//     );
//   }
// }

// class _RiskVolumeChart extends StatelessWidget {
//   final ModelAnalyticsSummary summary;
//   const _RiskVolumeChart({required this.summary});

//   @override
//   Widget build(BuildContext context) {
//     // Transform summary.dailyVolume (Map<String, int>) to List<MapEntry>
//     final data = summary.dailyVolume.entries
//         .map((e) => MapEntry(e.key, e.value.toDouble()))
//         .toList();
    
//     // Sort by Date String
//     data.sort((a, b) => a.key.compareTo(b.key));

//     // Show last 7 days
//     final recentData = data.length > 7 ? data.sublist(data.length - 7) : data;
//     return NativeChartCard(
//       title: 'chart_risk_vol'.t(),
//       subtitle: 'chart_risk_vol_sub'.t(),
//       emptyMessage: 'no_data'.t(),
//       barColor: Colors.indigo,
//       data: recentData,  // Assuming state has a Map
//     );   
//   }
// }

// // --- 3. ANALYTICS VIEW ---
// class _AnalyticsView extends StatelessWidget {
//   const _AnalyticsView();

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<HomeCubit, HomeState>(
//       builder: (context, state) {
//         final summary = state.analytics ?? ModelAnalyticsSummary.empty();
        
//         // Convert Top Risks to List
//         final dnaData = summary.topRisks.entries
//             .map((e) => MapEntry(e.key, e.value.toDouble()))
//             .toList()
//           ..sort((a,b) => b.value.compareTo(a.value)); // Sort Highest First

//         final strength = dnaData.isNotEmpty ? dnaData.first.key : 'na'.t();
//         final opportunity = dnaData.length > 1 ? dnaData.last.key : strength;

//         return ListView(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           children: [
//             NativeHorizontalBarChart(
//               title: 'risk_cat'.t(),
//               subtitle: 'risk_cat_sub'.t(),
//               data: dnaData.take(5).toList(),
//               emptyMessage: "No data found".t(),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(child: InsightCard(title: 'strength'.t(), value: strength, color: Colors.blue)),
//                 const SizedBox(width: 12),
//                 Expanded(child: InsightCard(title: 'opportunity'.t(), value: opportunity, color: Colors.amber)),
//               ],
//             )
//           ],
//         );
//       },
//     );
//   }
// }

// // --- 4. SMART REPORT VIEW ---
// class _SmartReportView extends StatelessWidget{

//   const _SmartReportView();

//   @override
//   Widget build(BuildContext context) {
//     final user = context.select((AuthCubit c) => c.currentUserName);

//     return BlocConsumer<ReportCubit, ReportState>(
//       listener: (context, state) {
//         if (state.error != null) {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${'error_prefix'.t()}${state.error}")));
//         }
//         // CHECK FOR EXPLICIT SUCCESS FLAG 
//         if (state.issueFormState == IssueFormState.success) {
//           context.read<ReportCubit>().clearImage(); 
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('report_success'.t())));
//           // Reset cubit to clean state so the success flag doesn't persist
//           context.read<ReportCubit>().resetState(); 
//         }
//       },
//       builder: (context, state) {
//         final reportCubit = context.read<ReportCubit>();
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(LocaleCubit.t('smart_entry', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               // Line Dropdown
//               DropdownButtonFormField<String>(
//                 hint: Text(LocaleCubit.t('line_hint', lang)),
//                 decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
//                 items: reportCubit.lines.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
//                 onChanged: (val) => reportCubit.updateLine(val??""),
//               ),
//               const SizedBox(height: 12),
//               // area Dropdown
//               DropdownButtonFormField<String>(
//                 hint: Text(LocaleCubit.t('area_hint', lang)),
//                 decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
//                 items: reportCubit.areas.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
//                 onChanged: (val) => reportCubit.updateArea(val??""),
//               ),
//               // Observation Input
//               const SizedBox(height: 12),
//               TextField(
//                 maxLines: 4,
//                 onChanged: (val) => reportCubit.updateObservation(val),
//                 decoration: InputDecoration(hintText: 'describe_hint'.t(), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
//               ),
//               const SizedBox(height: 16),
//               // PHOTO PICKER UI
//               if (state.selectedImage != null && state.selectedImage!.path.isNotEmpty)
//                 Stack(
//                   children: [
//                     ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(state.selectedImage!.path, height: 200, width: double.infinity, fit: BoxFit.cover) : Image.file(File(state.selectedImage!.path), height: 200, width: double.infinity, fit: BoxFit.cover)),
//                     if (state.isImageAnalyzing) Positioned.fill(child: Container(color: Colors.black45, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.white), const SizedBox(height: 8), Text('ai_scanning'.t(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))),
//                     Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => context.read<ReportCubit>().clearImage(), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20))))
//                   ],
//                 )
//               else 
//                 Row(
//                   children: [
//                     Expanded(child: OutlinedButton.icon(onPressed: () => context.read<ReportCubit>().pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text('pick_camera'.t()), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
//                     const SizedBox(width: 12),
//                     Expanded(child: OutlinedButton.icon(onPressed: () => context.read<ReportCubit>().pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: Text('pick_gallery'.t()), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
//                   ],
//                 ),
//               const SizedBox(height: 20),
//               // Quality Meter
//               SafetyQualityMeter(
//                 observation: state.observation??"",
//               ),
//               // duplicate reports
//               if (state.isDuplicateSuspect) ...[
//                 const SizedBox(height: 10),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(borderRadius: BorderRadius.circular(8) , border: Border.all(color: Colors.grey.shade200)),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.warning_amber, color: Colors.red),
//                       const SizedBox(width: 8),
//                       Expanded(child: Text(state.duplicateWarning!, style: TextStyle(color: Colors.deepOrange.shade900))),
//                     ],
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 12),  
//               // Department Dropdown
//               DropdownButtonFormField<String>(
//                 decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
//                 items: reportCubit.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
//                 onChanged: (val) => reportCubit.updateResponsibleDepartment(val??""),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: state.issueFormState == IssueFormState.isSubmitting ? null : () async {
//                     final confirmationDialogue = _ConfirmationDialog(
//                         title: 'dup_title'.t(),
//                         content:Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             _buildConfirmRow('lbl_line'.t(), state.line),
//                             _buildConfirmRow('lbl_area'.t(), state.area),
//                             const Divider(),
//                             _buildConfirmRow('lbl_issue'.t(), state.observation, isLong: true),
//                             const Divider(),
//                             _buildConfirmRow('lbl_type'.t(), state.selectedType ?? "Unsafe_Condition"),
//                             _buildConfirmRow('lbl_hazard'.t(), state.selectedHazardKind ?? "General"),
//                             _buildConfirmRow('lbl_level'.t(), state.selectedLevel ?? "Low", isHighlight: true),
//                             const Divider(),
//                             _buildConfirmRow('lbl_dept'.t(), state.selectedRespDept), 
//                             _buildConfirmRow('lbl_deptPerson'.t(), state.responsiblePerson),
//                           ],
//                         ),
//                         confirmText: 'confirmText'.t(),
//                         onConfirm: reportCubit.submitReport
//                     );
//                     await showDialog<bool>(
//                       context: context,
//                       builder: (BuildContext context) => confirmationDialogue,
//                     );
                    
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//                   child: state.issueFormState == IssueFormState.isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('review_submit'.t()),
//                 ),
//               )
//             ],
//           ),
//         );
//       },
//     );
//   }
  
//   Widget _buildConfirmRow(String label, String? value, {bool isLong = false, bool isHighlight = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         crossAxisAlignment: isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: 80, 
//             child: Text(
//               "$label:", 
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//             )
//           ),
//           Expanded(
//             child: Text(
//               value ?? "-",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: isHighlight ? _getLevelColor(value) : Colors.black87,
//                 fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Color _getLevelColor(String? level) {
//     switch (level?.toLowerCase()) {
//       case 'high':
//         return Colors.red.shade200;
//       case 'medium':
//         return Colors.orange.shade200;
//       default:
//         return Colors.green.shade200;
//     }
//   }

// }

// // --- 5. PERSONAL PROFILE VIEW ---

// class _PersonalProfileView extends StatelessWidget {
//   const _PersonalProfileView();

//   @override
//   Widget build(BuildContext context) {
//     final lang = context.select((LocaleCubit c) => c.state);
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SectionHeader(title: LocaleCubit.t('contrib_analysis', lang), subTitle: LocaleCubit.t('contrib_analysis_sub', lang)),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.blue.shade700]),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _Metric(val: "28", label: LocaleCubit.t('sensors_fed', lang)),
//                     _Metric(val: "+14%", label: LocaleCubit.t('ai_gain', lang)),
//                     _Metric(val: "Top 5%", label: LocaleCubit.t('site_rank', lang)),
//                   ],
//                 ),
//                 const Divider(color: Colors.white24, height: 32),
//                 Text(
//                   LocaleCubit.t('impact_text', lang),
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           _ImpactTile(title: LocaleCubit.t('badge_leader', lang), desc: LocaleCubit.t('badge_leader_desc', lang), icon: Icons.auto_awesome, col: Colors.orange),
//           const SizedBox(height: 12),
//           _ImpactTile(title: LocaleCubit.t('badge_guard', lang), desc: LocaleCubit.t('badge_guard_desc', lang), icon: Icons.shield, col: Colors.teal),
//         ],
//       ),
//     );
//   }
// }

// // --- HELPERS (Re-inserted for self-containment) ---


// class _RiskAnalysisTab extends StatelessWidget {
//   const _RiskAnalysisTab();

//   @override
//   Widget build(BuildContext context) {
//     final lang = context.select((LocaleCubit c) => c.state);
//     return BlocBuilder<CubitAnalytics, StateAnalytics>(
//       builder: (context, state) {
//         if (state.isLoading) return const Center(child: CircularProgressIndicator());
//         if (state.risksCombined.isEmpty) return _buildEmptyState(state, lang);

//         final sorted = state.risksCombined.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        
//         // Prepare combined trend data: History + Forecast Prediction
//         final forecastPoint = sorted.take(3).fold(0.0, (sum, entry) => sum + entry.value) / 3;
//         final chartPoints = [...state.history, forecastPoint];

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SectionHeader(
//                 title: "${state.windowLabel.toUpperCase()} ${'analysis_suffix'.t()}", 
//                 subTitle: "${'trajectory_prefix'.t()} ${state.signalCount} ${'signals'.t()}",
//               ),
//               const SizedBox(height: 16),
//               _buildTrendGraph(chartPoints),
//               const SizedBox(height: 24),
//               SectionHeader(title: 'area_risk_dist'.t(), subTitle: 'area_risk_dist_sub'.t()),
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
//                 ),
//                 itemCount: sorted.length,
//                 itemBuilder: (c, i) => RiskCard(area: sorted[i].key, score: sorted[i].value),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   Widget _buildTrendGraph(List<double> points) {
//     return Container(
//       height: 220,
//       padding: const EdgeInsets.fromLTRB(20, 24, 24, 12),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
//       child: LineChart(
//         LineChartData(
//           gridData: const FlGridData(show: false),
//           titlesData: FlTitlesData(
//             leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (v, m) {
//                   final labels = ["T-4", "T-3", "T-2", "T-1", "PREDICT"];
//                   if (v.toInt() < 0 || v.toInt() >= labels.length) return const SizedBox();
//                   return Text(labels[v.toInt()], style: const TextStyle(fontSize: 9, color: Colors.grey));
//                 },
//               ),
//             ),
//           ),
//           lineBarsData: [
//             LineChartBarData(
//               spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i])),
//               isCurved: true,
//               color: Colors.indigo,
//               barWidth: 3,
//               belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.05)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(StateAnalytics state, String lang) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.radar_rounded, size: 60, color: Colors.grey),
//           const SizedBox(height: 16),
//           Text("${'signals'.t()}: ${state.signalCount} | ${'window'.t()}: ${state.windowLabel}"),
//           Text('scanning_history'.t(), style: const TextStyle(color: Colors.grey)),
//         ],
//       ),
//     );
//   }
// }



// class _Metric extends StatelessWidget {
//   final String val, label;
//   const _Metric({required this.val, required this.label});
//   @override
//   Widget build(BuildContext context) {
//     return Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
//   }
// }

// class _ImpactTile extends StatelessWidget {
//   final String title, desc; final IconData icon; final Color col;
//   const _ImpactTile({required this.title, required this.desc, required this.icon, required this.col});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: col.withOpacity(0.1))),
//       child: Row(
//         children: [
//           Icon(icon, color: col),
//           const SizedBox(width: 16),
//           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
//         ],
//       ),
//     );
//   }
// }
