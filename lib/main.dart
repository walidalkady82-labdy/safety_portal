import 'package:flutter/material.dart';

void main() {
  runApp(const MaintenancePortalApp());
}

class MaintenancePortalApp extends StatelessWidget {
  const MaintenancePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATR Maintenance Portal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          primary: const Color(0xFF6750A4),
          secondary: const Color(0xFF00796B),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- DATA MODELS ---

class MaintenanceTask {
  final String id;
  final String date;
  final String area;
  final String observation;
  final String executor;
  final String status; // 'Pending', 'Closed'
  final String dueDate;
  final String? closeDate;

  MaintenanceTask({
    required this.id,
    required this.date,
    required this.area,
    required this.observation,
    required this.executor,
    required this.status,
    required this.dueDate,
    this.closeDate,
  });
}

class UserProfile {
  final String name;
  final String email;
  final String department;
  final bool isSafetyManager;

  UserProfile({
    required this.name,
    required this.email,
    required this.department,
    this.isSafetyManager = false,
  });
}

// --- MOCK DATA ---
final currentUser = UserProfile(
  name: "Ahmed Ali",
  email: "ahmed.ali@company.com",
  department: "Electrical",
  isSafetyManager: false, // Set to true to test Safety Manager view
);

// --- NAVIGATION ---

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const TaskListScreen(),
    const AddIssueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ATR Maintenance Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (currentUser.isSafetyManager)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Chip(label: Text("Safety Manager"), backgroundColor: Colors.redAccent, labelStyle: TextStyle(color: Colors.white)),
            ),
          Center(child: Text(currentUser.name, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('Tasks')),
                NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('Add New')),
              ],
            ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
                NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Add'),
              ],
            )
          : null,
    );
  }
}

// --- SCREEN: DASHBOARD ---

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: "Personal Insights", subtitle: "Your Performance vs Team", color: Color(0xFF00796B)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                const KpiCard(title: "My Resolved", value: "24", subValue: "Total Tasks", color: Colors.green),
                const StatCard(title: "Me vs Team Avg", labels: ["Me", "Team"], values: [24, 18], unit: "Tasks"),
                const StatCard(title: "Reliability (SLA)", labels: ["Me", "Team"], values: [92, 85], unit: "%"),
                const KpiCard(title: "Pending My Action", value: "05", subValue: "High Priority", color: Colors.orange),
              ],
            );
          }),
          const SizedBox(height: 32),
          const SectionHeader(title: "Global Statistics", subtitle: "Overall Plant Status", color: Color(0xFF6750A4)),
          const SizedBox(height: 16),
          const GlobalKpiRow(),
        ],
      ),
    );
  }
}

// --- SCREEN: TASK LIST ---

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data List
    final tasks = [
      MaintenanceTask(id: "15664", date: "2025-12-20", area: "CMC Station", observation: "Blade support broken", executor: "Ahmed Ali", status: "Pending", dueDate: "2025-12-25"),
      MaintenanceTask(id: "15665", date: "2025-12-21", area: "Line 1", observation: "Cable tray loose", executor: "Walid Mansour", status: "Pending", dueDate: "2025-12-28"),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: const Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text("Filters:", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final task = tasks[idx];
                  bool canEdit = task.executor == currentUser.name || currentUser.isSafetyManager;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    title: Text("#${task.id} - ${task.area}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(task.observation),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: task.status == 'Pending' ? Colors.blue[50] : Colors.green[50], borderRadius: BorderRadius.circular(20)),
                          child: Text(task.status, style: TextStyle(color: task.status == 'Pending' ? Colors.blue : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: canEdit ? () => _showUpdateDialog(context, task) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canEdit ? Colors.deepPurple : Colors.grey[300],
                            foregroundColor: canEdit ? Colors.white : Colors.grey,
                          ),
                          child: Text(canEdit ? "Update" : "View Only"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, MaintenanceTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Update Task #${task.id}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Status"),
              value: task.status,
              items: const [
                DropdownMenuItem(value: "Pending", child: Text("Pending")),
                DropdownMenuItem(value: "Closed", child: Text("Closed")),
              ],
              onChanged: (v) {},
            ),
            const TextField(decoration: InputDecoration(labelText: "Technician Feedback"), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Save Update")),
        ],
      ),
    );
  }
}

// --- SCREEN: ADD ISSUE ---

class AddIssueScreen extends StatelessWidget {
  const AddIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Register New Issue", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6750A4))),
                    const Text("Fill in details to alert the maintenance team", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    const Row(
                      children: [
                        Expanded(child: TextField(decoration: InputDecoration(labelText: "Line *", border: OutlineInputBorder()))),
                        SizedBox(width: 16),
                        Expanded(child: TextField(decoration: InputDecoration(labelText: "Area *", border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TextField(decoration: InputDecoration(labelText: "Observation *", border: OutlineInputBorder()), maxLines: 3),
                    const SizedBox(height: 16),
                    const TextField(decoration: InputDecoration(labelText: "Action Required *", border: OutlineInputBorder()), maxLines: 2),
                    const SizedBox(height: 32),
                    const Text("Attachment", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.grey[50]),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          Text("Click to upload photo", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6750A4), foregroundColor: Colors.white),
                        child: const Text("Submit Issue"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM WIDGETS ---

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  const SectionHeader({super.key, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 40, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final Color color;
  const KpiCard({super.key, required this.title, required this.value, required this.subValue, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            Text(subValue, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> values;
  final String unit;
  const StatCard({super.key, required this.title, required this.labels, required this.values, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(labels.length, (index) {
                return Column(
                  children: [
                    Text("${values[index]}$unit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: index == 0 ? const Color(0xFF00796B) : Colors.grey)),
                    Text(labels[index], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                );
              }),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class GlobalKpiRow extends StatelessWidget {
  const GlobalKpiRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: KpiCard(title: "GLOBAL PENDING", value: "142", subValue: "Issues Open", color: Colors.red)),
        const SizedBox(width: 16),
        const Expanded(child: KpiCard(title: "GLOBAL CLOSED", value: "894", subValue: "Completed", color: Colors.green)),
        const SizedBox(width: 16),
        const Expanded(child: KpiCard(title: "ELECTRICAL DEPT", value: "42", subValue: "Active Jobs", color: Colors.blue)),
      ],
    );
  }
}