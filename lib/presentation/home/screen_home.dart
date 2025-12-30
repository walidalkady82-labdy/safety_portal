import 'dart:async'; // Required for Timer
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/data/service/service_analytics.dart';
import 'package:safety_portal/presentation/auth/auth_wrapper.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  int _selectedIndex = 0;

  // --- REPORT FORM CONTROLLERS ---
  final TextEditingController _observationController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  
  // --- AI & STATE VARIABLES ---
  Timer? _debounce; // To handle silent updates
  List<double>? _currentVector; // Store the embedding for submission
  String? _duplicateWarning; // Message to show if duplicate found
  
  String? selectedArea;
  String? selectedDept;
  String? selectedType;
  String? selectedHazardKind;
  String? selectedElectricalKind;
  String? selectedLevel;
  
  bool isAiLoading = false;
  bool isSubmitting = false;

  final List<String> _areas = ["CCR", "Workshop", "Quarry", "Packer", "Mill", "Silo", "Preheater", "Cooler", "General"];
  final List<String> _departments = ["Electrical", "Mechanical", "Safety", "Production", "Civil"];
  final List<String> _types = ["Unsafe_Condition", "Unsafe_Behavior", "NM", "FA"];
  final List<String> _levels = ["Low", "Medium", "High"];

  @override
  void dispose() {
    _debounce?.cancel();
    _observationController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Portal | بوابة السلامة"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                );
              }
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildLiveDashboard(), // Tab 0: Analytics
          _buildReportForm(),    // Tab 1: Submission
          _buildProfile(),       // Tab 2: User Info
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 0: LIVE STREAM DASHBOARD
  // ===========================================================================
  Widget _buildLiveDashboard() {
    return StreamBuilder<List<RiskMetric>>(
      stream: DashboardService().analyticsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("No data yet. Submit a report!"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text("Go to Report"),
                )
              ],
            ),
          );
        }

        final metrics = snapshot.data!;
        final totalReports = metrics.fold<int>(0, (sum, item) => sum + item.reportCount);
        final highestRiskArea = metrics.first.area;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryCard("Total Reports", "$totalReports", Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard("Top Risk Area", highestRiskArea, Colors.red)),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text("Risk Score by Area", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: metrics.first.totalRiskScore * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                metrics[value.toInt()].area.substring(0, min(3, metrics[value.toInt()].area.length)),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: metrics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final metric = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: metric.totalRiskScore,
                          color: metric.totalRiskScore > 10 ? Colors.red : Colors.amber,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("Detailed Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            ...metrics.map((m) => Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.avgSeverity > 3 ? Colors.red[100] : Colors.green[100],
                  child: Text("${m.reportCount}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(m.area),
                subtitle: Text("Risk Score: ${m.totalRiskScore.toStringAsFixed(1)}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: REPORT SUBMISSION FORM (Silent AI + Duplicate Check)
  // ===========================================================================
  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("New Observation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            value: selectedArea,
            items: _areas.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => selectedArea = v),
            decoration: const InputDecoration(labelText: "Area", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // --- OBSERATION INPUT WITH SILENT AI ---
          TextField(
            controller: _observationController,
            onChanged: _onObservationChanged, // Triggers silent AI
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Describe the Issue",
              border: const OutlineInputBorder(),
              suffixIcon: isAiLoading 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_note, color: Colors.grey),
            ),
          ),
          
          // --- DUPLICATE WARNING BANNER ---
          if (_duplicateWarning != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_duplicateWarning!, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
          const SizedBox(height: 16),

          TextField(
            controller: _actionController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: "Action Taken / Required", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField(
            value: selectedDept,
            items: _departments.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => selectedDept = v),
            decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 20),
          const Divider(),
          Row(
            children: [
              const Text("Classification (Auto-Updated)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const Spacer(),
              if (isAiLoading) const Text("Analyzing...", style: TextStyle(fontSize: 12, color: AppColors.primary))
            ],
          ),
          const SizedBox(height: 10),

          // Auto-filled fields
          Row(
            children: [
              Expanded(child: _buildCompactDropdown("Type", _types, selectedType, (v) => setState(() => selectedType = v))),
              const SizedBox(width: 10),
              Expanded(child: _buildCompactDropdown("Level", _levels, selectedLevel, (v) => setState(() => selectedLevel = v))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildCompactDropdown("Hazard Kind", ServiceAI().classifier.hazardLabels.isNotEmpty ? ServiceAI().classifier.hazardLabels : ["General"], selectedHazardKind, (v) => setState(() => selectedHazardKind = v))),
            ],
          ),

          const SizedBox(height: 30),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Submit Report"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    final validValue = items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), border: const OutlineInputBorder()),
    );
  }

  // --- LOGIC: SILENT AI ANALYSIS & DEBOUNCING ---
  void _onObservationChanged(String text) {
    // Clear warning if user clears text
    if (text.isEmpty && _duplicateWarning != null) {
      setState(() => _duplicateWarning = null);
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Wait for 1.5 seconds of silence before triggering AI
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (text.trim().length > 5) {
        _runSilentAnalysis(text);
      }
    });
  }

  Future<void> _runSilentAnalysis(String text) async {
    setState(() => isAiLoading = true);
    try {
      final result = await ServiceAI().analyzeFull(text);
      final classification = result['classification'] as Map<String, String>;
      final embedding = result['embedding'] as List<double>;

      if (mounted) {
        setState(() {
          // Auto-Update Fields
          selectedType = classification['type'];
          selectedHazardKind = classification['hazard_kind'];
          selectedElectricalKind = classification['electrical_kind'];
          selectedLevel = classification['level'];
          
          // Store Vector for Submission
          _currentVector = embedding;
        });
        
        // Trigger Duplicate Check
        await _checkForDuplicates(embedding);
      }
    } catch (e) {
      print("Silent AI Error: $e");
    } finally {
      if (mounted) setState(() => isAiLoading = false);
    }
  }

  // --- LOGIC: DUPLICATE DETECTION ---
  Future<void> _checkForDuplicates(List<double> newVector) async {
    final snapshot = await FirebaseDatabase.instance.ref('atr').get();
    if (!snapshot.exists || snapshot.value == null) return;

    // Helper to parse data safely (handles Lists and Maps)
    Map<dynamic, dynamic> data = {};
    if (snapshot.value is Map) {
      data = snapshot.value as Map;
    } else if (snapshot.value is List) {
      final list = snapshot.value as List;
      for (int i = 0; i < list.length; i++) {
        if (list[i] != null) data[i.toString()] = list[i];
      }
    }

    double maxSimilarity = 0.0;
    String? similarId;

    // Iterate through existing reports to compare vectors
    data.forEach((key, value) {
      if (value is Map && value['vector'] != null) {
        // Convert dynamic list to List<double>
        List<dynamic> rawVec = value['vector'];
        // Basic check to ensure vector length matches (e.g. 64)
        if (rawVec.length == newVector.length) {
          List<double> existingVec = rawVec.map((e) => (e as num).toDouble()).toList();
          double sim = ServiceAI().duplicateDetector.calculateSimilarity(newVector, existingVec);
          
          if (sim > maxSimilarity) {
            maxSimilarity = sim;
            similarId = key;
          }
        }
      }
    });

    // Threshold: 0.85 implies very similar text semantics
    if (mounted) {
      if (maxSimilarity > 0.85) {
        setState(() {
          _duplicateWarning = "Found a similar report (Similarity: ${(maxSimilarity * 100).toStringAsFixed(0)}%). Duplicate?";
        });
      } else {
        setState(() {
          _duplicateWarning = null;
        });
      }
    }
  }

  // --- LOGIC: SUBMIT REPORT ---
  Future<void> _submitReport() async {
    if (_observationController.text.isEmpty || selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in Area and Observation.")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseDatabase.instance.ref('atr').push().set({
        'area': selectedArea,
        'observationOrIssueOrHazard': _observationController.text,
        'actionRequired': _actionController.text,
        'status': 'Pending',
        'issueDate': DateTime.now().toIso8601String(),
        'type': selectedType ?? "Unsafe_Condition",
        'hazard_kind': selectedHazardKind ?? "General",
        'level': selectedLevel ?? "Low",
        'respDepartment': selectedDept ?? "Safety",
        'reporter': user?.email ?? "Anonymous",
        'reporterUid': user?.uid,
        // SAVE VECTOR FOR FUTURE DUPLICATE CHECKS
        'vector': _currentVector ?? [],
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Report Submitted Successfully!")));
      
      _observationController.clear();
      _actionController.clear();
      setState(() {
        selectedType = null;
        selectedHazardKind = null;
        selectedLevel = null;
        _currentVector = null;
        _duplicateWarning = null;
        _selectedIndex = 0; // Go to dashboard
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Submission Failed: $e")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // ===========================================================================
  // TAB 2: PROFILE
  // ===========================================================================
  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          Text(user?.email ?? "Guest User", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Safety Portal User", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}