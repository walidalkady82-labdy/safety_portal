import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/model/model_atr.dart';
import 'package:safety_portal/presentation/home/cubit_analytics.dart';
import 'package:safety_portal/presentation/home/cubit_home.dart';
import 'package:safety_portal/presentation/home/cubit_report.dart';

class ScreenAreaDetails extends StatelessWidget {
  const ScreenAreaDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final String selectedArea = context.read<CubitAnalytics>().getHighRiskArea();

    // Fetch dynamic metrics for selected area
    context.read<CubitAnalytics>().getAreaMetrics(selectedArea); 
    final analytics = context.read<CubitAnalytics>(); 
    final areas = context.read<ReportCubit>().areas;
    final List<ModelAtr> reports = (context.read<CubitAnalytics>().state.areaMetrics['reports'] as List<dynamic>?)?.cast<ModelAtr>() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Area Analytics"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Swappable Area Cards (Selector)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: areas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final area = areas[i];
                  final isSelected = area == selectedArea;
                  return GestureDetector(
                    onTap: () => context.read<HomeCubit>().updateselectedArea(area),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.emeraldShade50 : Colors.white,
                        border: Border.all(color: isSelected ? AppColors.emerald : Colors.grey.shade200, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(area, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.emeraldShade800 : Colors.grey)),
                          if(isSelected) const Text("Selected", style: TextStyle(fontSize: 10, color: AppColors.emerald))
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 2. Dynamic KPI
            _buildStatusCard(analytics.state.areaMetrics),
            const SizedBox(height: 24),

            // 3. Leaderboard Card
            _buildLeaderboardCard(context),
            const SizedBox(height: 24),

            // 4. Active Reporters List
            Align(alignment: Alignment.centerLeft, child: Text("Active Reports", style: TextStyle(fontWeight: FontWeight.bold))),
            if (reports.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text("No active reports.", style: TextStyle(color: Colors.grey))),
            ...reports.map((r) => _buildReportTile(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    final String selectedArea = context.read<CubitAnalytics>().getHighRiskArea();
    return InkWell(
      onTap: () => _showLeaderboardModal(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.indigo.shade100, child: Icon(Icons.emoji_events, color: Colors.indigo)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Safety Leaders", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
              Text("Top contributors in $selectedArea", style: TextStyle(fontSize: 12, color: Colors.indigo)),
            ])),
            Icon(Icons.chevron_right, color: Colors.indigo),
          ],
        ),
      ),
    );
  }

  void _showLeaderboardModal(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => Container(
      padding: EdgeInsets.all(24),
      height: 400,
      child: Column(
        children: [
          Text("Top Performers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          // List of leaders...
        ],
      ),
    ));
  }
  
  Widget _buildReportTile(ModelAtr report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/svg?seed=${report.reporter}'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.observation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Reported by ${report.reporter} • ${report.issueDate}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text(report.type ?? 'General', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          )
        ],
      ),
    );
  }
  
  Widget _buildStatusCard(Map<String, dynamic> metrics) {
    final status = metrics['status'] as String? ?? 'Unknown';
    final isCritical = status == 'Critical';
    final color = isCritical ? Colors.amber : AppColors.emerald;
    final bgColor = isCritical ? Colors.amber.shade50 : AppColors.emeraldShade50;
    final icon = isCritical ? Icons.thermostat : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Risk Score: ${metrics['riskScore']}", style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
              const Text("Real-time AI Assessment", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}