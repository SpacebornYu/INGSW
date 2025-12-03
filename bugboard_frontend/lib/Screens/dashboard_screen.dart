import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import 'create_issue_screen.dart';
import 'account_screen.dart';
import 'issue_detail_screen.dart'; // <--- Importante per navigare ai dettagli

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final IssueService _issueService = IssueService();
  
  // Dati
  List<Issue> _allIssues = [];      
  List<Issue> _filteredIssues = []; 
  bool _isLoading = true;
  String _errorMessage = "";

  // Stato Filtri
  String _searchQuery = "";
  Set<String> _selectedTypes = {};     
  Set<String> _selectedStatuses = {};   
  Set<String> _selectedPriorities = {}; 
  Set<String> _selectedLabels = {};    

  // Navigazione
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

  // MOTORE DI FILTRAGGIO
  void _applyFilters() {
    setState(() {
      _filteredIssues = _allIssues.where((issue) {
        // 1. Ricerca
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          if (!issue.title.toLowerCase().contains(q) && 
              !issue.description.toLowerCase().contains(q)) return false;
        }
        // 2. Filtri Multipli
        if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(issue.type)) return false;
        if (_selectedStatuses.isNotEmpty && !_selectedStatuses.contains(issue.status)) return false;
        if (_selectedPriorities.isNotEmpty && !_selectedPriorities.contains(issue.priority)) return false;
        
        // 3. Filtro Etichetta (Se issue non ha NESSUNA delle etichette selezionate)
        if (_selectedLabels.isNotEmpty) {
          bool hasMatch = issue.tags.any((tag) => _selectedLabels.contains(tag));
          if (!hasMatch) return false;
        }

        return true;
      }).toList();
    });
  }

  // --- UI HELPER: Bottoni Filtro ---
  Widget _buildFilterChip(String label, Set<String> selectedValues, Function(Set<String>) onUpdate) {
    bool isActive = selectedValues.isNotEmpty;
    String buttonText = label;
    if (isActive) {
      if (selectedValues.length == 1) {
        buttonText = _formatLabel(selectedValues.first);
      } else {
        buttonText = "$label (+${selectedValues.length})";
      }
    }

    return GestureDetector(
      onTap: () {
        if (isActive) {
          onUpdate({}); // Reset rapido al click se attivo
        }
      },
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
              buttonText, 
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.close : Icons.keyboard_arrow_down, 
              color: isActive ? Colors.white : Colors.grey, 
              size: 16
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String txt) {
    return txt.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  void _showMultiSelectSheet(String title, List<String> options, Set<String> currentSelection, Function(Set<String>) onApply) {
    Set<String> tempSelection = Set.from(currentSelection);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla", style: TextStyle(color: Colors.grey))),
                      Text("Filtra per $title", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () { onApply(tempSelection); Navigator.pop(context); }, child: const Text("Fatto", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (ctx, i) {
                        final opt = options[i];
                        final isSelected = tempSelection.contains(opt);
                        return CheckboxListTile(
                          title: Text(_formatLabel(opt), style: const TextStyle(color: Colors.white)),
                          value: isSelected,
                          activeColor: Colors.blueAccent,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Colors.grey),
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) tempSelection.add(opt);
                              else tempSelection.remove(opt);
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
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
                GestureDetector(
                  onTap: () => _showMultiSelectSheet("il Tipo", ['BUG', 'FEATURE', 'QUESTION', 'DOCUMENTATION'], _selectedTypes, (val) { setState(() { _selectedTypes = val; _applyFilters(); }); }),
                  child: AbsorbPointer(child: _buildFilterChip("Tipo", _selectedTypes, (_) {})),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showMultiSelectSheet("lo Stato", ['TODO', 'IN_PROGRESS', 'DONE'], _selectedStatuses, (val) { setState(() { _selectedStatuses = val; _applyFilters(); }); }),
                  child: AbsorbPointer(child: _buildFilterChip("Stato", _selectedStatuses, (_) {})),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showMultiSelectSheet("la Priorità", ['VERY_HIGH', 'HIGH', 'MEDIUM', 'LOW', 'VERY_LOW'], _selectedPriorities, (val) { setState(() { _selectedPriorities = val; _applyFilters(); }); }),
                  child: AbsorbPointer(child: _buildFilterChip("Priorità", _selectedPriorities, (_) {})),
                ),
                const SizedBox(width: 8),
                if (existingTags.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showMultiSelectSheet("l'Etichetta", existingTags.toList(), _selectedLabels, (val) { setState(() { _selectedLabels = val; _applyFilters(); }); }),
                    child: AbsorbPointer(child: _buildFilterChip("Etichetta", _selectedLabels, (_) {})),
                  ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: _getIconForType(issue.type),
                    title: Text(issue.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          _getPriorityIcon(issue.priority),
                          const SizedBox(width: 8),
                          _buildStatusBadge(issue.status),
                        ],
                      ),
                    ),
                    onTap: () async {
                      // NAVIGAZIONE AL DETTAGLIO
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IssueDetailScreen(issueId: issue.id),
                        ),
                      );
                      // Al ritorno aggiorniamo la lista (magari sono cambiati commenti o stato)
                      _loadIssues();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status.replaceAll('_', ' ');
    if (status == 'TODO') { color = Colors.orange; text = "To do"; }
    if (status == 'IN_PROGRESS') { color = Colors.blue; text = "In corso"; }
    if (status == 'DONE') { color = Colors.green; text = "Completata"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _getIconForType(String type) {
    double iconSize = 32.0; 
    switch (type) {
      case 'BUG': return Icon(Icons.bug_report_outlined, color: Colors.redAccent, size: iconSize);
      case 'FEATURE': return Icon(Icons.check_box_outlined, color: Colors.blueAccent, size: iconSize);
      case 'QUESTION': return Icon(Icons.help_outline, color: Colors.orangeAccent, size: iconSize);
      default: return Icon(Icons.description_outlined, color: Colors.white70, size: iconSize);
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