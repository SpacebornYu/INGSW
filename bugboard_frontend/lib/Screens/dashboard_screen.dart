import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import 'login_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final IssueService _issueService = IssueService();
  late Future<List<Issue>> _issuesFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  void _loadIssues() {
    setState(() {
      _issuesFuture = _issueService.getIssues();
    });
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'BUG': return const Icon(Icons.bug_report_outlined, color: Colors.redAccent);
      case 'FEATURE': return const Icon(Icons.check_box_outlined, color: Colors.blueAccent);
      case 'QUESTION': return const Icon(Icons.help_outline, color: Colors.orangeAccent);
      case 'DOCUMENTATION': return const Icon(Icons.description_outlined, color: Colors.white70);
      default: return const Icon(Icons.circle, color: Colors.grey);
    }
  }

  Widget _getPriorityIcon(String? priority) {
    switch (priority) {
      case 'HIGH':
      case 'URGENT': return const Icon(Icons.keyboard_double_arrow_up, color: Colors.red, size: 16);
      case 'LOW': return const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16);
      default: return const Icon(Icons.drag_handle, color: Colors.orange, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Barra di ricerca
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Lista Issue
              Expanded(
                child: FutureBuilder<List<Issue>>(
                  future: _issuesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text("Errore: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade800),
                            const SizedBox(height: 16),
                            const Text("Nessuna issue trovata", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final issues = snapshot.data!;
                    return Container(
                      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
                      child: ListView.separated(
                        itemCount: issues.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1, indent: 60),
                        itemBuilder: (context, index) {
                          final issue = issues[index];
                          return ListTile(
                            leading: _getIconForType(issue.type),
                            title: Text(issue.title, style: const TextStyle(color: Colors.white)),
                            subtitle: Row(
                              children: [
                                _getPriorityIcon(issue.priority),
                                const SizedBox(width: 8),
                                Text(issue.status, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'All issues'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'New Issue'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}