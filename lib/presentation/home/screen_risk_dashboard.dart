import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safety_portal/core/local_manager.dart';
import 'package:safety_portal/presentation/home/cubit_analytics.dart';
import 'package:safety_portal/presentation/home/cubit_home.dart';
import 'package:safety_portal/presentation/home/screen_area_details.dart';
import 'package:safety_portal/presentation/home/widgets/card/attion_map_chart.dart';
import 'package:safety_portal/presentation/home/widgets/card/kpi_card.dart';
import 'package:safety_portal/presentation/home/widgets/chart/chart_container.dart';
import 'package:safety_portal/presentation/home/widgets/chart/trend_forecast_view.dart';
import 'package:safety_portal/presentation/home/widgets/priority_watch_list.dart';

class ScreenRiskDashboard extends StatelessWidget {
  const ScreenRiskDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Text("dashboard_title".t(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        
        // 1. DYNAMIC KPI CARDS
        BlocBuilder<HomeCubit, HomeState>(
          builder: (context, homeState) {
            return BlocBuilder<CubitAnalytics, StateAnalytics>(
              builder: (context, forecastState) {
                // --- METRIC 1: Active Reports (From HomeCubit) ---
                final reports = homeState.recentReports;
                final activeCount = reports.where((r) => (r.status).toLowerCase() != 'closed').length;
                
                // --- METRIC 2: Trend Direction (From ForecastCubit History) ---
                final history = forecastState.history;
                bool isTrendingUp = false;
                String trendLabel = "lbl_stable".t();
                
                if (history.length >= 2) {
                  final current = history.last;
                  final previous = history[history.length - 2];
                  if (current > previous) {
                    isTrendingUp = true;
                    trendLabel = 'lbl_rising'.t();
                  } else if (current < previous) {
                    trendLabel = 'lbl_falling'.t();
                  }
                }

                // --- METRIC 3: Highest Risk Area (From ForecastCubit AI Risks) ---
                String topArea = 'lbl_scanning'.t();
                if (!forecastState.isLoading) {
                  if (forecastState.risksCombined.isNotEmpty) {
                    var sortedEntries = forecastState.risksCombined.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    if (sortedEntries.isNotEmpty) {
                      topArea = sortedEntries.first.key;
                    }
                  } else {
                    topArea = 'lbl_none'.t();
                  }
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      KPICard(
                        title: 'kpi_active_reports'.t(),
                        value: "$activeCount",
                        icon: Icons.storage,
                        color: Colors.blue,
                        subtext: 'sub_pending_action'.t(),
                        trendUp: false,
                      ),
                      const SizedBox(width: 12),
                      KPICard(
                        title: 'kpi_risk_velocity'.t(),
                        value: trendLabel,
                        icon: Icons.trending_up,
                        color: isTrendingUp ? Colors.redAccent : Colors.green,
                        subtext: 'sub_ai_history'.t(),
                        trendUp: isTrendingUp,
                        isAlert: isTrendingUp,
                      ),
                      const SizedBox(width: 12),
                      KPICard(
                        title: 'kpi_high_risk_area'.t(),
                        value: topArea.length > 10 ? "${topArea.substring(0,8)}..." : topArea,
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                        subtext: 'sub_ai_identified'.t(),
                        trendUp: true,
                        onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenAreaDetails()));
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        // 2. CHARTS SECTION
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              ChartContainer(
                title: 'chart_velocity'.t(),
                subtitle: 'chart_velocity_sub'.t(),
                child: BlocBuilder<CubitAnalytics, StateAnalytics>(
                          builder: (context, state) {
                            return TrendForecastView(
                              isLoading: state.isLoading,
                              history: state.history,
                              forecast: state.risksTrend[''], // Pass the list directly
                              historyColor: Colors.blue,     // Optional: customize per screen
                            );
                          },
                        ),
              ),
              const SizedBox(height: 16),
              ChartContainer(
                title: 'chart_attention'.t(),
                subtitle: 'chart_attention_sub'.t(),
                child: BlocBuilder<CubitAnalytics, StateAnalytics>(
                          builder: (context, state) {
                            return AttentionMapChart(
                              isLoading: state.isLoading,
                              riskData: state.risksCombined,
                              maxItems: 6, // Optional: customize the count
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 3. PRIORITY WATCHLIST
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('watchlist_title'.t(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 8),
        PriorityWatchlist(
          items: [], 
          emptyMessage: '',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}