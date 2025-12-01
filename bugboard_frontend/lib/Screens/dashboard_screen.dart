import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import 'create_issue_screen.dart';
import 'account_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final IssueService _issueService = IssueService();
  
  List<Issue> _allIssues = [];      
  List<Issue> _filteredIssues = []; 
  bool _isLoading = true;
  String _errorMessage = "";

  String _searchQuery = "";
  String? _filterType;     
  String? _filterStatus;   
  String? _filterPriority; 
  String? _filterLabel;    

  int _selectedIndex = 0;
  final GlobalKey<CreateIssueScreenState> _createIssueKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  void _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final issues = await _issueService.getIssues();
      setState(() {
        _allIssues = issues;
        _applyFilters(); 
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredIssues = _allIssues.where((issue) {
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          if (!issue.title.toLowerCase().contains(q) && 
              !issue.description.toLowerCase().contains(q)) return false;
        }
        if (_filterType != null && issue.type != _filterType) return false;
        if (_filterStatus != null && issue.status != _filterStatus) return false;
        if (_filterPriority != null && issue.priority != _filterPriority) return false;
        if (_filterLabel != null && !issue.tags.contains(_filterLabel)) return false;
        return true;
      }).toList();
    });
  }

  Widget _buildFilterChip(String label, String? selectedValue, VoidCallback onTap) {
    bool isActive = selectedValue != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.blueAccent : Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Text(
              isActive ? _formatLabel(selectedValue!) : label, 
              style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
            const SizedBox(width: 4),
            Icon(isActive ? Icons.close : Icons.keyboard_arrow_down, color: isActive ? Colors.white : Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String txt) {
    return txt.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  void _showFilterSheet(String title, List<String> options, String? currentValue, Function(String?) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Filtra per $title", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Tutti", style: TextStyle(color: Colors.grey)),
                trailing: currentValue == null ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { onSelected(null); Navigator.pop(context); },
              ),
              const Divider(color: Colors.grey),
              ...options.map((opt) => ListTile(
                title: Text(_formatLabel(opt), style: const TextStyle(color: Colors.white)),
                trailing: currentValue == opt ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                onTap: () { onSelected(opt); Navigator.pop(context); },
              )),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) async {
    if (_selectedIndex == 1 && index != 1) {
      bool hasUnsavedData = _createIssueKey.currentState?.hasChanges ?? false;
      if (hasUnsavedData) {
        bool shouldLeave = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text("Attenzione", style: TextStyle(color: Colors.white)),
            content: const Text("Se cambi pagina perderai i dati inseriti. Continuare?", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(child: const Text("Rimani qui"), onPressed: () => Navigator.pop(ctx, false)),
              TextButton(child: const Text("Esci comunque", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ) ?? false;
        if (!shouldLeave) return;
        _createIssueKey.currentState?.clearAll();
      }
    }
    setState(() => _selectedIndex = index);
    if (index == 0) _loadIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardContent(),
            CreateIssueScreen(key: _createIssueKey, onSuccess: () { _onItemTapped(0); _loadIssues(); }),
            const AccountScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'All issues'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'New Issue'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final Set<String> existingTags = _allIssues.expand((i) => i.tags).toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (val) { _searchQuery = val; _applyFilters(); },
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true, fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("Tipo", _filterType, () {
                  if (_filterType != null) { setState(() { _filterType = null; _applyFilters(); }); }
                  else { _showFilterSheet("Tipo", ['BUG', 'FEATURE', 'QUESTION', 'DOCUMENTATION'], _filterType, (v) => setState((){ _filterType = v; _applyFilters(); })); }
                }),
                _buildFilterChip("Stato", _filterStatus, () {
                  if (_filterStatus != null) { setState(() { _filterStatus = null; _applyFilters(); }); }
                  else { _showFilterSheet("Stato", ['TODO', 'IN_PROGRESS', 'DONE'], _filterStatus, (v) => setState((){ _filterStatus = v; _applyFilters(); })); }
                }),
                _buildFilterChip("Priorità", _filterPriority, () {
                  if (_filterPriority != null) { setState(() { _filterPriority = null; _applyFilters(); }); }
                  else { _showFilterSheet("Priorità", ['VERY_HIGH', 'HIGH', 'MEDIUM', 'LOW', 'VERY_LOW'], _filterPriority, (v) => setState((){ _filterPriority = v; _applyFilters(); })); }
                }),
                if (existingTags.isNotEmpty)
                  _buildFilterChip("Etichetta", _filterLabel, () {
                    if (_filterLabel != null) { setState(() { _filterLabel = null; _applyFilters(); }); }
                    else { _showFilterSheet("Etichetta", existingTags.toList(), _filterLabel, (v) => setState((){ _filterLabel = v; _applyFilters(); })); }
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          else if (_filteredIssues.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey.shade800),
                    const SizedBox(height: 16),
                    const Text("Al momento non ci sono\nissue con i parametri specificati", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredIssues.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1, indent: 60),
                itemBuilder: (context, index) {
                  final issue = _filteredIssues[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: _getIconForType(issue.type),
                    title: Text(issue.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (issue.tags.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("#${issue.tags.join(', ')}", style: TextStyle(color: Colors.blue.shade200, fontSize: 11))),
                        Row(children: [
                          _getPriorityIcon(issue.priority),
                          const SizedBox(width: 8),
                          _buildStatusBadge(issue.status),
                        ]),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // FUNZIONE AGGIORNATA CON .withValues() PER EVITARE L'AVVISO DEPRECATED
  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status.replaceAll('_', ' ');
    if (status == 'TODO') { color = Colors.orange; text = "To do"; }
    if (status == 'IN_PROGRESS') { color = Colors.blue; text = "In corso"; }
    if (status == 'DONE') { color = Colors.green; text = "Completata"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // Uso withValues(alpha: ...) invece di withOpacity(...)
        color: color.withValues(alpha: 0.2), 
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'BUG': return const Icon(Icons.bug_report_outlined, color: Colors.redAccent);
      case 'FEATURE': return const Icon(Icons.check_box_outlined, color: Colors.blueAccent);
      case 'QUESTION': return const Icon(Icons.help_outline, color: Colors.orangeAccent);
      default: return const Icon(Icons.description_outlined, color: Colors.white70);
    }
  }

  Widget _getPriorityIcon(String? priority) {
    if (priority == null) return const SizedBox();
    if (priority.contains('VERY_HIGH')) return const Icon(Icons.keyboard_double_arrow_up, color: Colors.red, size: 18);
    if (priority.contains('HIGH')) return const Icon(Icons.keyboard_arrow_up, color: Colors.redAccent, size: 18);
    if (priority.contains('MEDIUM')) return const Icon(Icons.drag_handle, color: Colors.orange, size: 18);
    if (priority.contains('VERY_LOW')) return const Icon(Icons.keyboard_double_arrow_down, color: Colors.blue, size: 18);
    return const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 18);
  }
}