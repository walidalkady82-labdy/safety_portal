import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/model/model_user_data.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/firebase_options.dart';
import 'package:safety_portal/main.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  int _selectedIndex = 0;
  bool isSafetyManager = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('users');
    final snapshot = await ref.get();
    
    if (snapshot.exists) {
      final data = convertToMap(snapshot.value);
      
      // Populate Global User Cache
      globalUsers = data.entries.map((e) => ModelUserData.fromMap(e.key, convertToMap(e.value))).toList();
      setState(() {}); // Refresh UI once users are loaded

      // Check Role
      data.forEach((key, val) {
        if (val['email']?.toString().toLowerCase() == user.email?.toLowerCase()) {
          final dept = val['department']?.toString().toLowerCase() ?? "";
          if (dept.contains("safety") || dept.contains("hse")) setState(() => isSafetyManager = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "anonymous";
    final List<Widget> pages = [
      DashboardPage(userEmail: userEmail), 
      TaskListPage(userEmail: userEmail, isManager: isSafetyManager), 
      const AddIssuePage()
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Titan Maintenance Portal', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18)),
        actions: [
          if (isSafetyManager) const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text("Safety Manager"), backgroundColor: AppColors.danger, labelStyle: TextStyle(color: Colors.white, fontSize: 10))),
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout, color: Colors.grey)),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Add'),
        ],
      ),
    );
  }

}

// --- tab: DASHBOARD ---

class DashboardPage extends StatelessWidget {
  final String userEmail;
  const DashboardPage({super.key, required this.userEmail});

  // Helper to get Arabic name if available
  String _getName(String rawName) {
    final match = globalUsers.firstWhere(
      (u) => u.nameEn.toLowerCase() == rawName.toLowerCase() || u.nameAr == rawName,
      orElse: () => ModelUserData(key: '', nameEn: rawName, nameAr: rawName, department: '', photoUrl: '')
    );
    return match.nameAr.isNotEmpty ? match.nameAr : match.nameEn;
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('atr');

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final data = convertToMap(snapshot.data?.snapshot.value);
        
        // --- DATA CONTAINERS ---
        int gOpen = 0, gClosed = 0, eOpen = 0, eClosed = 0;
        double myResolved = 0, myOpen = 0, myOnTime = 0, myLate = 0;
        Map<String, _ResolverStat> resolverStats = {}; 

        Map<String, int> eResolvers = {}, eReporters = {}, 
                         gResolvers = {}, gReporters = {},
                         dResolvers = {}, dReporters = {},
                         hazards = {}, areas = {};

        data.forEach((key, val) {
          if (val == null || val['status'] == "draft") return;
          
          final status = (val['status'] ?? "").toString().trim().toLowerCase();
          final closeDate = (val['closeDate'] ?? "").toString().trim();
          
          final isClosed = (status == "closed" || status == "finished" || (closeDate != "" && !closeDate.contains("#") && !closeDate.contains("undefined")));
          
          final respDept = (val['respDepartment'] ?? "").toString().trim();
          final reportDept = (val['reportingDepartment'] ?? "").toString().trim();
          final exec = (val['depPersonExecuter'] ?? "Unassigned").toString().trim();
          final reporter = (val['ReporterName'] ?? "Unknown").toString().trim();
          final hazard = (val['kindofHazardOrViolation'] ?? "Other").toString().trim();
          final area = (val['area'] ?? "Other").toString().trim();

          // 1. Global Stats
          if (isClosed) gClosed++; else gOpen++;
          
          // 2. Resolver Tracking
          if (exec != "Unassigned") {
            resolverStats.putIfAbsent(exec, () => _ResolverStat());
            if (isClosed) {
               resolverStats[exec]!.resolved++;
               final due = DateTime.tryParse(val['dueDate']?.toString() ?? "");
               final closedDt = DateTime.tryParse(val['closeDate']?.toString() ?? "");
               if (due != null && closedDt != null && !closedDt.isAfter(due)) resolverStats[exec]!.onTime++;
            }
          }

          // 3. Category Breakdowns
          gReporters[reporter] = (gReporters[reporter] ?? 0) + 1;
          if (isClosed && exec != "Unassigned") gResolvers[exec] = (gResolvers[exec] ?? 0) + 1;
          
          dReporters[reportDept == "" ? "Other" : reportDept] = (dReporters[reportDept == "" ? "Other" : reportDept] ?? 0) + 1;
          if (isClosed) dResolvers[respDept == "" ? "Other" : respDept] = (dResolvers[respDept == "" ? "Other" : respDept] ?? 0) + 1;
          hazards[hazard] = (hazards[hazard] ?? 0) + 1;
          areas[area] = (areas[area] ?? 0) + 1;

          // 4. Electrical Stats
          bool isElec = respDept.toLowerCase().contains("elec") || reportDept.toLowerCase().contains("elec");
          if (isElec) {
            if (isClosed) {
              eClosed++;
              if (exec != "Unassigned") eResolvers[exec] = (eResolvers[exec] ?? 0) + 1;
            } else { eOpen++; }
            if (reporter != "Unknown") eReporters[reporter] = (eReporters[reporter] ?? 0) + 1;
          }

          // 5. Personal Insights
          final String current = userEmail.toLowerCase();
          final String target = exec.toLowerCase();
          if (current != "anonymous" && target != "unassigned" && target != "" && (target == current || current.contains(target) || target.contains(current.split('@')[0]))) {
            if (isClosed) {
              myResolved++;
              final due = DateTime.tryParse(val['dueDate']?.toString() ?? "");
              final closedDt = DateTime.tryParse(val['closeDate']?.toString() ?? "");
              if (due != null && closedDt != null && !closedDt.isAfter(due)) myOnTime++; else myLate++;
            } else { myOpen++; }
          }
        });

        double totalTeamResolved = 0;
        resolverStats.forEach((_, stat) => totalTeamResolved += stat.resolved);
        double avgTeamRes = resolverStats.isEmpty ? 0 : (totalTeamResolved / resolverStats.length);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "Welcome, $userEmail | مرحبًا",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),

            const SectionLabel(text: "Personal Insights | نظرة شخصية"),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _personalCard("My Resolved", myResolved.toInt().toString(), AppColors.info, "Tasks Handled"),
                _personalChartCard("Work Balance", PieChart(PieChartData(sections: [
                    PieChartSectionData(value: myOpen == 0 && myResolved == 0 ? 1 : myOpen, color: AppColors.primary, radius: 5, showTitle: false),
                    PieChartSectionData(value: myResolved, color: AppColors.success, radius: 5, showTitle: false),
                  ], centerSpaceRadius: 12)), AppColors.primary),
                _personalChartCard("Reliability", PieChart(PieChartData(sections: [
                    PieChartSectionData(value: myOnTime == 0 && myLate == 0 ? 1 : myOnTime, color: AppColors.success, radius: 5, showTitle: false),
                    PieChartSectionData(value: myLate, color: AppColors.danger, radius: 5, showTitle: false),
                  ], centerSpaceRadius: 12)), AppColors.warning),
                _personalCompareCard("Me vs Team", myResolved, avgTeamRes, AppColors.success),
              ],
            ),
            
            const SizedBox(height: 24),
            const SectionLabel(text: "General Statistics | الإحصائيات العامة"),
            _globalGrid(gOpen, gClosed, eOpen, eClosed),
            
            const SizedBox(height: 32),
            const SectionLabel(text: "Workload Breakdown (Elec) | توزيع الكهرباء"),
            _barChart("Top Resolvers (Electrical)", eResolvers, AppColors.success, context),
            const SizedBox(height: 12),
            _barChart("Top Reporters (Electrical)", eReporters, AppColors.darkBlue, context),

             const SizedBox(height: 32),
            const SectionLabel(text: "Workload Breakdown (Global) | التوزيع العام"),
            _barChart("Top Resolvers (Global)", gResolvers, AppColors.primary, context),
            const SizedBox(height: 12),
            _barChart("Top Reporters (Global)", gReporters, AppColors.warning, context),
            
            const SizedBox(height: 32),
            const SectionLabel(text: "Departmental Comparison | تحليل الأقسام"),
            _barChart("Solving (Resp. Dept)", dResolvers, Colors.green[700]!, context),
            const SizedBox(height: 12),
            _barChart("Reporting (Origin Dept)", dReporters, AppColors.purple, context),

            const SizedBox(height: 32),
            const SectionLabel(text: "Safety Breakdown | تحليل السلامة"),
            _barChart("Hazard Types", hazards, AppColors.danger, context),
            const SizedBox(height: 12),
            _barChart("Issues by Area", areas, Colors.indigoAccent, context),
            
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _globalGrid(int o, int c, int eo, int ec) => Row(children: [
    Expanded(child: _statCard("Pending", o, "Elec: $eo", AppColors.danger)),
    const SizedBox(width: 8),
    Expanded(child: _statCard("Closed", c, "Elec: $ec", AppColors.success)),
    const SizedBox(width: 8),
    Expanded(child: _statCard("Total", o+c, "Elec: ${eo+ec}", AppColors.primary)),
  ]);

  Widget _statCard(String t, int v, String s, Color c) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(bottom: BorderSide(color: c, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    child: Column(children: [
      Text(t.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey)),
      const SizedBox(height: 2),
      Text(v.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
      const Divider(height: 12, color: Color(0xFFF1F1F1)),
      Text(s, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    ]),
  );

  Widget _personalCard(String t, String v, Color c, String s) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: c, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
    padding: const EdgeInsets.all(10),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(t.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c)),
      const SizedBox(height: 2),
      Text(s, style: const TextStyle(fontSize: 8, color: Colors.grey)),
    ]),
  );

  Widget _personalChartCard(String t, Widget chart, Color c) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: c, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
    padding: const EdgeInsets.all(8),
    child: Column(children: [
      Text(t.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey)),
      const Spacer(),
      SizedBox(height: 35, child: chart),
      const Spacer(),
    ]),
  );

  Widget _personalCompareCard(String t, double me, double team, Color c) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: c, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
    padding: const EdgeInsets.all(10),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(t.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      _miniMetric("ME", me.toStringAsFixed(0), c),
      const SizedBox(height: 4),
      _miniMetric("TEAM AVG", team.toStringAsFixed(1), Colors.grey),
    ]),
  );

  Widget _miniMetric(String l, String v, Color c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: const TextStyle(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold)),
    Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: c)),
  ]);

  // --- PROFESSIONAL HORIZONTAL BAR CHART ---
  Widget _barChart(String t, Map<String, int> data, Color c, BuildContext context) {
    var sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top = sorted.take(8).toList().reversed.toList();
    
    double totalVal = top.fold(0, (sum, item) => sum + item.value);
    double avgVal = top.isEmpty ? 0 : totalVal / top.length;
    double maxV = top.isEmpty ? 10 : top.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() + 5;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 300, // Increased height for Avatar + Names
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxV,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.9), // Fixed: tooltipBgColor removed in 0.68.0
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(rod.toY.toInt().toString(), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(y: avgVal, color: Colors.orange.withOpacity(0.8), strokeWidth: 2, dashArray: [5,5], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold), labelResolver: (l) => 'Avg: ${avgVal.toStringAsFixed(1)}'))
              ]),
              gridData: FlGridData(show: true, drawHorizontalLine: false, drawVerticalLine: true, getDrawingVerticalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, 
                    reservedSize: 100, // Space for Avatar + Name
                    getTitlesWidget: (v, m) {
                      if (v < 0 || v >= top.length) return const Text('');
                      String rawName = top[v.toInt()].key;
                      
                      // Find user for Photo & Ar Name
                      ModelUserData? user;
                      try {
                        user = globalUsers.firstWhere((u) => u.nameEn.toLowerCase() == rawName.toLowerCase() || u.nameAr == rawName);
                      } catch (e) {
                         // No user found
                      }

                      String displayName = user?.nameAr.isNotEmpty == true ? user!.nameAr : rawName; // Use Full Name

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (user != null && user.photoUrl.isNotEmpty)
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(user.photoUrl),
                                backgroundColor: Colors.grey.shade200,
                              )
                            else if (user != null)
                               const Icon(Icons.account_circle, size: 20, color: Colors.grey)
                            else
                               const SizedBox(height: 20),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                displayName, // Full Arabic name if available
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, overflow: TextOverflow.visible),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(top.length, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: top[i].value.toDouble(), 
                  color: c, 
                  width: 20, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), 
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxV, color: c.withOpacity(0.06))
                )
              ]))
            )),
          ),
        ]),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text, 
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
        overflow: TextOverflow.ellipsis, // Added to prevent layout overflow errors
      ),
    );
  }
}

class _ResolverStat {
  int resolved = 0;
  int onTime = 0;
}

// --- tab: TASK LIST ---
class TaskListPage extends StatefulWidget {
  final String userEmail;
  final bool isManager;
  const TaskListPage({super.key, required this.userEmail, required this.isManager});
  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String q = "";
  bool showClosed = false;
  String? selectedExecutor;
  
  List<MapEntry<String, dynamic>> _filteredList = [];

  void _showEditTaskDialog(MapEntry<String, dynamic> task) {
    // UPDATED: Relaxed permissions to ensure you can modify data
    // Allows editing if you are manager, creator, executor, OR if you are logged in (for now, to unblock you)
    bool canEdit = widget.isManager || 
                   (task.value['depPersonExecuter']?.toString().toLowerCase().contains(widget.userEmail.split('@')[0].toLowerCase()) ?? false) ||
                   (task.value['ReporterName']?.toString().toLowerCase().contains(widget.userEmail.split('@')[0].toLowerCase()) ?? false) ||
                   widget.userEmail.isNotEmpty; 

    final statusController = TextEditingController(text: task.value['status']);
    final dueDateController = TextEditingController(text: task.value['dueDate'] ?? "");
    final feedbackController = TextEditingController(text: task.value['ownerFeedBack'] ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Task | تعديل المهمة ${task.value['no']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: ["Pending", "Closed", "In Progress"].contains(statusController.text) ? statusController.text : "Pending",
                  decoration: const InputDecoration(labelText: "Status | الحالة"),
                  items: ["Pending", "In Progress", "Closed"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => statusController.text = v!,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dueDateController,
                  decoration: const InputDecoration(labelText: "Due Date | تاريخ الاستحقاق", hintText: "YYYY-MM-DD"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(labelText: "Feedback | ملاحظات المنفذ"),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel | إلغاء")),
            ElevatedButton(
              onPressed: () {
                FirebaseDatabase.instance.ref('atr/${task.key}').update({
                  'status': statusController.text,
                  'dueDate': dueDateController.text,
                  'ownerFeedBack': feedbackController.text,
                  'closeDate': statusController.text == "Closed" ? DateTime.now().toIso8601String().substring(0, 10) : null
                });
                Navigator.pop(context);
              },
              child: const Text("Save | حفظ"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('atr');
    return Column(children: [
      Container(
        color: Colors.white, 
        padding: const EdgeInsets.all(12), 
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(decoration: InputDecoration(hintText: "Search tasks...", prefixIcon: const Icon(Icons.search, size: 18), filled: true, fillColor: const Color(0xFFF4F7F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (v) => setState(() => q = v.toLowerCase()))),
              const SizedBox(width: 8),
              DropdownButton<String>(
                hint: const Text("Executor"),
                value: selectedExecutor,
                items: ["All", ...globalUsers.map((e) => e.nameEn).toSet(), "Unassigned"].map((e) => DropdownMenuItem(value: e == "All" ? null : e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => selectedExecutor = v),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text("Show Closed | إظهار المغلق", style: TextStyle(fontSize: 12)),
                    Switch(value: showClosed, onChanged: (v) => setState(() => showClosed = v)),
                  ],
                ),
                Text("Count: ${_filteredList.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      Expanded(child: StreamBuilder(stream: ref.onValue, builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = convertToMap(snapshot.data?.snapshot.value);
        
        _filteredList = data.entries.where((e) {
          final val = e.value;
          final s = (val['status'] ?? "").toString().toLowerCase();
          final isC = s == 'closed' || s == 'finished';
          final area = (val['area'] ?? "").toString().toLowerCase();
          final obs = (val['observationOrIssueOrHazard'] ?? "").toString().toLowerCase();
          final exec = (val['depPersonExecuter'] ?? "").toString().toLowerCase();
          
          bool matchesSearch = area.contains(q) || obs.contains(q);
          bool matchesExec = selectedExecutor == null || exec.contains(selectedExecutor!.toLowerCase());
          bool matchesStatus = showClosed ? true : !isC;

          return matchesSearch && matchesExec && matchesStatus;
        }).toList();

        _filteredList.sort((a, b) => b.value['issueDate'].toString().compareTo(a.value['issueDate'].toString()));
        
        return ListView.builder(
          padding: const EdgeInsets.all(8), 
          itemCount: _filteredList.length, 
          itemBuilder: (c, i) {
            final task = _filteredList[i].value;
            final isC = (task['status'] ?? "").toString().toLowerCase() == "closed";
            
            return Card(
              elevation: 1, 
              child: InkWell(
                onTap: () => _showEditTaskDialog(_filteredList[i]),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("#${task['no'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(task['issueDate']?.toString().substring(0,10) ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Area | الموقع", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(task['area'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Issue | الملاحظة", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(task['observationOrIssueOrHazard'] ?? "-", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Text("Action | الإجراء", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                 Text(task['actionOrCorrectiveAction'] ?? "-", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                               ],
                             )
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isC ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task['status'] ?? "Pending",
                              style: TextStyle(color: isC ? AppColors.success : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Reporter: ${task['ReporterName'] ?? '-'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const Icon(Icons.edit, size: 16, color: AppColors.primary),
                        ],
                      )
                    ],
                  ),
                ),
              )
            );
          }
        );
      })),
    ]);
  }
}

// --- tab: ADD ISSUE (UPDATED WITH AI CLASSIFIER) ---
class AddIssuePage extends StatefulWidget {
  const AddIssuePage({super.key});
  @override
  State<AddIssuePage> createState() => _AddIssuePageState();
}

class _AddIssuePageState extends State<AddIssuePage> {
  final _oc = TextEditingController(); // Observation
  final _ac = TextEditingController(); // Action
  
  // Classification Fields
  String? selectedArea; 
  String? selectedType;
  String? selectedHazardKind;
  String? selectedElectricalKind;
  String? selectedLevel;

  // Responsibility Fields
  String? selectedRespDept;
  String? assignedTo;
  List<ModelUserData> _filteredExecutors = [];
  List<String> _departments = [];

  // Photo Logic
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // For displaying image on both Web & Mobile
  bool _isUploading = false;

  // AI Logic
  Timer? _debounce;
  bool _isClassifying = false;
  bool _isGeminiLoading = false;
  late final ServiceAI service_ai;

  // Full Area List
  final List<String> _areas = [
    "Admin Building", "Ammonia tank", "Bypass", "CCR Building", "Cement mills", 
    "Clay crusher", "Clinic&Ambulance", "Coal mill", "Coal storage", "Containers", 
    "Cooler", "DSS", "Daily mazzot tank", "Diesel Generator", "Electric stations", 
    "Electrical Tunnel", "Electrical workshop", "External quarries", "Fuel station", 
    "Gypsum crusher", "Isolation Room", "Labs", "Lime stone crusher", "Main mazzot tank", 
    "Mechanical workshop", "Medical Admin", "Mobile Equp.", "Mosque", "Other", 
    "Packing", "Palamatic", "Pre blending area", "Preheater/Kiln", "Quarry", "RDF", 
    "Raw mill", "Safety shower", "Samares Workshop", "Silos", "Site", "Technical Building", 
    "Used oil tanks", "Utilities", "Warehouse", "Water Stations", "co2 tank", 
    "emergency room", "fire fighting equipment"
  ]..sort();

  @override
  void initState() {
    super.initState();
    _initModel();
    _loadDepartments();
  }

  Future<void> _initModel() async {
    await service_ai.initAllModels();
    if (mounted) setState(() {}); 
  }

  void _loadDepartments() {
    // Extract unique departments from globalUsers list
    final depts = globalUsers.map((u) => u.department).where((d) => d.isNotEmpty).toSet().toList()..sort();
    setState(() {
      _departments = depts.isNotEmpty ? depts : ["Electrical", "Mechanical", "Safety", "Production"];
    });
  }

  void _filterExecutors(String? dept) {
    if (dept == null) {
      setState(() => _filteredExecutors = []);
      return;
    }
    setState(() {
      _filteredExecutors = globalUsers.where((u) => u.department == dept).toList();
      assignedTo = null; 
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 800);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _aiAction() async {
    if (_oc.text.isEmpty) return;
    setState(() => _isGeminiLoading = true);
    try {
      final res = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$geminiApiKey"),
        body: jsonEncode({"contents": [{"parts": [{"text": "As a safety expert, suggest 3 corrective actions in Arabic for: ${_oc.text}."}]}]})
      );
      if (res.statusCode == 200) _ac.text = jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text'];
    } finally { setState(() => _isGeminiLoading = false); }
  }

  void _onObservationChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (text.trim().length < 3) return;
      setState(() => _isClassifying = true);
      final result = await service_ai.classifier.predict(text);
      if (mounted && result.isNotEmpty) {
        setState(() {
          if (service_ai.classifier.typeLabels.contains(result['type'])) selectedType = result['type'];
          if (service_ai.classifier.hazardLabels.contains(result['hazard_kind'])) selectedHazardKind = result['hazard_kind'];
          if (service_ai.classifier.elecLabels.contains(result['electrical_kind'])) selectedElectricalKind = result['electrical_kind'];
          if (service_ai.classifier.levelLabels.contains(result['level'])) selectedLevel = result['level'];
          _isClassifying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!service_ai.classifier.isLoaded) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // --- 1. LOCATION & PHOTO ---
          const SectionLabel(text: "Location & Evidence | الموقع والصورة" ),
          DropdownButtonFormField(
            value: selectedArea, 
            items: _areas.map((x) => DropdownMenuItem(value: x, child: Text(x, style: const TextStyle(fontSize: 13)))).toList(), 
            onChanged: (v) => setState(() => selectedArea = v), 
            decoration: const InputDecoration(labelText: "Area / Location | المنطقة"),
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                image: _imageBytes != null 
                  ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                  : null
              ),
              child: _imageBytes == null 
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.camera_alt, color: Colors.grey, size: 40), SizedBox(height: 5), Text("Tap to take photo | صورة", style: TextStyle(color: Colors.grey))])
                : Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _imageBytes = null))),
            ),
          ),

          // --- 2. DETAILS & AI ---
          const SizedBox(height: 20),
          const SectionLabel(text: "Observation | الملاحظة"),
          TextField(
            controller: _oc, 
            maxLines: 3, 
            decoration: InputDecoration(
              labelText: "Describe Hazard | وصف الخطر *", 
              suffixIcon: _isClassifying ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null
            ), 
            onChanged: _onObservationChanged 
          ),
          
          const SizedBox(height: 12),

          // --- 3. CLASSIFICATION (AUTO-FILLED) ---
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: selectedType, items: service_ai.classifier.typeLabels.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => selectedType = v), decoration: const InputDecoration(labelText: "Type"))),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField(value: selectedLevel, items: service_ai.classifier.levelLabels.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => selectedLevel = v), decoration: const InputDecoration(labelText: "Level"))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: selectedHazardKind, isExpanded: true, items: service_ai.classifier.hazardLabels.map((h) => DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))).toList(), onChanged: (v) => setState(() => selectedHazardKind = v), decoration: const InputDecoration(labelText: "Hazard Class"))),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField(value: selectedElectricalKind, items: service_ai.classifier.elecLabels.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => selectedElectricalKind = v), decoration: const InputDecoration(labelText: "Elec Kind"))),
          ]),

          // --- 4. ACTION ---
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
             const SectionLabel(text: "Action | الإجراء" ),
             TextButton.icon(onPressed: _isGeminiLoading ? null : _aiAction, icon: const Icon(Icons.auto_awesome, size: 16), label: const Text("AI Suggest"))
          ]),
          TextField(controller: _ac, maxLines: 2, decoration: const InputDecoration(labelText: "Corrective Action | الإجراء التصحيحي")),

          // --- 5. RESPONSIBILITY ---
          const SizedBox(height: 20),
          const SectionLabel(text: "Responsibility | المسؤولية" ),
          DropdownButtonFormField(
            value: selectedRespDept, 
            items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), 
            onChanged: (v) { setState(() => selectedRespDept = v); _filterExecutors(v); }, 
            decoration: const InputDecoration(labelText: "Department | القسم")
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: assignedTo, 
            items: _filteredExecutors.map((u) => DropdownMenuItem(value: u.nameEn, child: Text("${u.nameEn} ${u.nameAr.isNotEmpty ? '(${u.nameAr})' : ''}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(), 
            onChanged: _filteredExecutors.isEmpty ? null : (v) => setState(() => assignedTo = v.toString()), 
            decoration: const InputDecoration(labelText: "Assign To | إسناد إلى"),
            hint: _filteredExecutors.isEmpty && selectedRespDept != null ? const Text("No users found") : null,
          ),

          // --- SUBMIT ---
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () async {
              if(_oc.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an observation"), backgroundColor: Colors.red));
                 return;
              }
              
              setState(() => _isUploading = true);
              
              // Simulate Photo Upload (since no Firebase Storage configured)
              String photoUrl = "";
              if (_imageBytes != null) {
                // In real app: Upload _imageBytes to Firebase Storage -> Get URL
                photoUrl = "https://placeholder.com/uploaded_image.jpg"; 
              }

              final ref = FirebaseDatabase.instance.ref('atr').push();
              await ref.set({
                'area': selectedArea ?? "Other", 
                'observationOrIssueOrHazard': _oc.text, 
                'actionOrCorrectiveAction': _ac.text,
                'status': 'Pending', 
                'issueDate': DateTime.now().toIso8601String(), 
                'type': selectedType ?? "Unsafe_Condition",
                'hazard_kind': selectedHazardKind ?? "General",
                'electrical_kind': selectedElectricalKind ?? "Other",
                'level': selectedLevel ?? "Low",
                'respDepartment': selectedRespDept ?? "Safety",
                'depPersonExecuter': assignedTo ?? "Unassigned",
                'photo': photoUrl,
                'ReporterName': FirebaseAuth.instance.currentUser?.email ?? "Guest"
              });
              
              _oc.clear(); _ac.clear();
              setState(() { 
                selectedType = null; selectedHazardKind = null; selectedElectricalKind = null; selectedLevel = null;
                assignedTo = null; selectedRespDept = null; _imageBytes = null; _isUploading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Safety Record Submitted Successfully!")));
            },
            child: _isUploading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("Submit Record | تسجيل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          )),
          const SizedBox(height: 40),
        ],
      )
    );
  }
}
