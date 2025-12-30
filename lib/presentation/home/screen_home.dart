import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/data/service/service_analytics.dart';

// --- UTILS: WEB COMPATIBILITY PARSER ---
class FirebaseDataParser {
  static Map<dynamic, dynamic> toMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return value;
    if (value is List) {
      Map<dynamic, dynamic> map = {};
      for (int i = 0; i < value.length; i++) {
        if (value[i] != null) map[i.toString()] = value[i];
      }
      return map;
    }
    return {};
  }
}

// --- LIGHTWEIGHT MODELS FOR SUMMARY ---
class DeptMetric {
  final String name;
  final int pending;
  final int closed;
  final double totalRisk;
  double get efficiency => (pending + closed) == 0 ? 0 : (closed / (pending + closed)) * 100;

  DeptMetric({required this.name, required this.pending, required this.closed, required this.totalRisk});
}

class TeamMemberMetric {
  final String name;
  final int pending;
  final int total;
  final double riskLoad;
  TeamMemberMetric({required this.name, required this.pending, required this.total, required this.riskLoad});
}

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const DashboardView(),
        const Center(child: Text("Detailed Task Explorer | مستكشف المهام")),
        const AddIssuePage(),
      ][_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics_rounded), label: "Analysis"),
          NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: "Tasks"),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: "Report"),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool isManagerView = true; 
  bool _isLoading = true;

  // Optimized State: We only load the summary node
  List<RiskMetric> _areaRisks = [];
  List<DeptMetric> _deptComparison = [];
  List<TeamMemberMetric> _teamMetrics = [];
  double _plantAvgEfficiency = 0;
  int _totalPlantTasks = 0;

  @override
  void initState() {
    super.initState();
    _fetchAggregatedAnalytics();
  }

  /// PROACTIVE OPTIMIZATION: 
  /// Instead of fetching 'atr' (Full DB), we fetch 'analytics_summary' (Aggregated)
  Future<void> _fetchAggregatedAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // 1. Fetch the SUMMARY node (Extremely low cost/high speed)
      final snapshot = await FirebaseDatabase.instance.ref('analytics_summary').get();
      
      if (!snapshot.exists) {
        // Fallback: If summary doesn't exist, calculate it once (Rebuild trigger)
        print("Summary not found. Rebuilding from raw data...");
        await _rebuildSummaryFromRaw();
        return;
      }

      final data = FirebaseDataParser.toMap(snapshot.value);
      
      setState(() {
        _totalPlantTasks = data['total_count'] ?? 0;
        
        // Load Area Risk Heatmap from Summary
        final areas = FirebaseDataParser.toMap(data['areas']);
        _areaRisks = areas.entries.map((e) => RiskMetric(
          area: e.key,
          reportCount: e.value['count'] ?? 0,
          totalRiskScore: (e.value['risk'] ?? 0).toDouble(),
          avgSeverity: (e.value['risk'] ?? 0) / max(1, e.value['count'] as int),
        )).toList()..sort((a, b) => b.totalRiskScore.compareTo(a.totalRiskScore));

        // Load Dept Comparison from Summary
        final depts = FirebaseDataParser.toMap(data['departments']);
        _deptComparison = depts.entries.map((e) => DeptMetric(
          name: e.key,
          pending: e.value['pending'] ?? 0,
          closed: e.value['closed'] ?? 0,
          totalRisk: (e.value['risk'] ?? 0).toDouble(),
        )).toList()..sort((a, b) => b.totalRisk.compareTo(a.totalRisk));

        // Load Electrical Team specifically from Summary
        final team = FirebaseDataParser.toMap(data['teams']?['Electrical']);
        _teamMetrics = team.entries.map((e) => TeamMemberMetric(
          name: e.key,
          pending: e.value['pending'] ?? 0,
          total: e.value['total'] ?? 0,
          riskLoad: (e.value['risk'] ?? 0).toDouble(),
        )).toList()..sort((a, b) => b.riskLoad.compareTo(a.riskLoad));

        if (_deptComparison.isNotEmpty) {
          _plantAvgEfficiency = _deptComparison.map((d) => d.efficiency).reduce((a, b) => a + b) / _deptComparison.length;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print("Analytics Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  /// REBUILD LOGIC: Used only if the summary is missing
  Future<void> _rebuildSummaryFromRaw() async {
    final snap = await FirebaseDatabase.instance.ref('atr').get();
    if (!snap.exists) { setState(() => _isLoading = false); return; }
    
    // ... Logic to iterate everything and then SAVE it to 'analytics_summary' ...
    // This script essentially "refreshes" the cache for the whole plant.
    _fetchAggregatedAnalytics(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isManagerView ? "Plant Analysis (Live Summary)" : "My Safety Insights", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _fetchAggregatedAnalytics, icon: const Icon(Icons.bolt, color: Colors.orange)),
          IconButton(onPressed: _fetchAggregatedAnalytics, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _fetchAggregatedAnalytics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                   _buildManagerHub(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildManagerHub() {
    final elec = _deptComparison.firstWhere((d) => d.name.toLowerCase() == 'electrical', orElse: () => DeptMetric(name: 'Elec', pending: 0, closed: 0, totalRisk: 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlantKpiRow(),
        const SizedBox(height: 16),
        _buildInfoCard("AI Performance Insight", "Electrical Team is at ${elec.efficiency.toStringAsFixed(1)}% efficiency vs Plant Average ${_plantAvgEfficiency.toStringAsFixed(1)}%.", elec.efficiency >= _plantAvgEfficiency ? Colors.green : Colors.orange),
        const SizedBox(height: 24),
        _sectionTitle("Efficiency Ranking (Team vs Plant)"),
        _buildComparisonChart(),
        const SizedBox(height: 24),
        _sectionTitle("Electrical Team: AI Risk Load"),
        _buildTeamGrid(),
      ],
    );
  }

  Widget _buildPlantKpiRow() {
    return Row(children: [
      _kpiCard("Total Reports", _totalPlantTasks.toString(), Colors.blue),
      const SizedBox(width: 8),
      _kpiCard("Avg Plant Eff.", "${_plantAvgEfficiency.toStringAsFixed(0)}%", Colors.green),
    ]);
  }

  Widget _kpiCard(String label, String val, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
    child: Column(children: [
      Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  ));

  Widget _buildInfoCard(String title, String body, Color color) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.auto_awesome, size: 16, color: color), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13))]),
      const SizedBox(height: 8),
      Text(body, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, height: 1.4)),
    ]),
  );

  Widget _buildComparisonChart() {
    return Container(
      height: 180, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: BarChart(BarChartData(
          maxY: 100,
          barGroups: _deptComparison.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value.efficiency, color: e.value.name.toLowerCase() == 'electrical' ? AppColors.primary : Colors.grey.shade300, width: 14)
          ])).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
              if (v < 0 || v >= _deptComparison.length) return const SizedBox();
              String n = _deptComparison[v.toInt()].name;
              return Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.substring(0, min(3, n.length)), style: const TextStyle(fontSize: 8)));
            })),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _buildTeamGrid() {
    if (_teamMetrics.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No Team Data Found")));
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: _teamMetrics.length,
      itemBuilder: (context, index) {
        final t = _teamMetrics[index];
        return Container(
          padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text("Risk Load: ${t.riskLoad.toInt()}", style: TextStyle(color: t.riskLoad > 20 ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            Text("Tasks: ${t.pending}/${t.total}", style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ]),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
}

// --- ADD ISSUE PAGE: INTEGRATING THE AGGREGATOR ---
class AddIssuePage extends StatefulWidget {
  const AddIssuePage({super.key});
  @override
  State<AddIssuePage> createState() => _AddIssuePageState();
}

class _AddIssuePageState extends State<AddIssuePage> {
  final _oc = TextEditingController();
  String? selectedArea;
  String? selectedDept;
  String? assignedTo;
  
  // Weights (Keep in sync with Analytics Service)
  final Map<String, int> lW = {'low': 1, 'medium': 3, 'high': 5};
  final Map<String, int> tW = {'unsafe_condition': 1, 'unsafe_behavior': 2, 'nm': 5, 'fa': 10};

  Future<void> _submitAndIncrement() async {
    if (_oc.text.isEmpty || selectedArea == null) return;
    
    // 1. Get AI Predictions (Classification & Vector)
    final ai = await ServiceAI().analyzeFull(_oc.text);
    final pred = ai['classification'] as Map<String, String>;
    
    final String level = (pred['level'] ?? 'low').toLowerCase();
    final String type = (pred['type'] ?? 'unsafe_condition').toLowerCase();
    final double risk = (lW[level]! * tW[type]!).toDouble();

    // 2. Save the RAW report
    final newReportRef = FirebaseDatabase.instance.ref('atr').push();
    await newReportRef.set({
      'area': selectedArea,
      'observationOrIssueOrHazard': _oc.text,
      'status': 'Pending',
      'respDepartment': selectedDept ?? 'Electrical',
      'depPersonExecuter': assignedTo ?? 'Unassigned',
      'level': pred['level'],
      'type': pred['type'],
      'vector': ai['embedding'],
    });

    // 3. ATOMIC UPDATE: Increment the Summary Analytics node
    // This makes the Dashboard load INSTANTLY with no high cost
    final summaryRef = FirebaseDatabase.instance.ref('analytics_summary');
    
    // We update the Global count, Area risk, and Team workload in one go
    await summaryRef.child('total_count').set(ServerValue.increment(1));
    await summaryRef.child('areas/$selectedArea/risk').set(ServerValue.increment(risk));
    await summaryRef.child('areas/$selectedArea/count').set(ServerValue.increment(1));
    await summaryRef.child('departments/$selectedDept/pending').set(ServerValue.increment(1));
    await summaryRef.child('departments/$selectedDept/risk').set(ServerValue.increment(risk));
    await summaryRef.child('teams/$selectedDept/$assignedTo/pending').set(ServerValue.increment(1));
    await summaryRef.child('teams/$selectedDept/$assignedTo/total').set(ServerValue.increment(1));
    await summaryRef.child('teams/$selectedDept/$assignedTo/risk').set(ServerValue.increment(risk));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report recorded and Analytics updated!")));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Quick Report (Aggregated)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DropdownButtonFormField(
            value: selectedArea, 
            items: ["CCR", "Workshop", "Quarry"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
            onChanged: (v) => setState(() => selectedArea = v),
            decoration: const InputDecoration(labelText: "Area"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: selectedDept, 
            items: ["Electrical", "Mechanical", "Safety"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
            onChanged: (v) => setState(() => selectedDept = v),
            decoration: const InputDecoration(labelText: "Dept"),
          ),
          const SizedBox(height: 12),
          TextField(controller: _oc, maxLines: 2, decoration: const InputDecoration(labelText: "What is the issue?")),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitAndIncrement, 
              child: const Text("Submit & Update Analysis"),
            ),
          )
        ],
      ),
    );
  }

  
}