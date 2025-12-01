import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/issue_service.dart';

class CreateIssueScreen extends StatefulWidget {
  // Callback opzionale se vogliamo notificare il successo (anche se ora gestiamo il pop con true)
  final VoidCallback? onSuccess; 

  const CreateIssueScreen({super.key, this.onSuccess});

  @override
  State<CreateIssueScreen> createState() => CreateIssueScreenState();
}

class CreateIssueScreenState extends State<CreateIssueScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _labelController = TextEditingController();
  
  String? _selectedType;
  String? _selectedPriority;
  XFile? _selectedImage;
  bool _isLoading = false;
  final IssueService _issueService = IssueService();

  final List<String> _types = ['Bug', 'Question', 'Documentation', 'Feature'];
  final List<String> _priorities = ['Very High', 'High', 'Medium', 'Low', 'Very Low'];

  // MODIFICA 1: Rimosso _labelController.text.isNotEmpty
  // Ora l'etichetta è opzionale
  bool get _isValid => 
      _titleController.text.isNotEmpty && 
      _descController.text.isNotEmpty && 
      _selectedType != null && 
      _selectedPriority != null;

  // Serve alla Dashboard per l'alert di uscita
  bool get hasChanges {
    return _titleController.text.isNotEmpty || 
           _descController.text.isNotEmpty || 
           _selectedType != null || 
           _labelController.text.isNotEmpty || // Se scrivo l'etichetta e esco, voglio comunque l'alert
           _selectedPriority != null;
  }

  void clearAll() {
    setState(() {
      _titleController.clear(); 
      _descController.clear(); 
      _labelController.clear();
      _selectedType = null; 
      _selectedPriority = null; 
      _selectedImage = null;
    });
  }

  void _onClean() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Pulisci campi", style: TextStyle(color: Colors.white)),
        content: const Text("Cancellare tutto?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text("No"), onPressed: () => Navigator.pop(c)),
          TextButton(child: const Text("Sì", style: TextStyle(color: Colors.red)), onPressed: () {
            Navigator.pop(c);
            clearAll();
          }),
        ],
      )
    );
  }

  void _onSubmit() async {
    if (!_isValid) return;

    bool confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Conferma", style: TextStyle(color: Colors.white)),
        content: const Text("Creare questa issue?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text("No"), onPressed: () => Navigator.pop(c, false)),
          TextButton(child: const Text("Sì"), onPressed: () => Navigator.pop(c, true)),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    
    bool success = await _issueService.createIssue(
      _titleController.text, 
      _descController.text, 
      _selectedType!, 
      _selectedPriority!, 
      _labelController.text // Passiamo il testo anche se è vuoto (opzionale)
    );
    
    setState(() => _isLoading = false);

    if (success && mounted) {
      clearAll();
      if (widget.onSuccess != null) widget.onSuccess!();
      // Chiude la schermata tornando "true" alla Dashboard
      // (Se usata come pagina separata dal +)
      // Se usata dentro IndexedStack, onSuccess gestisce il cambio tab
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore creazione")));
    }
  }

  void _showSheet(String title, List<String> items, Function(String) onSelect) {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Seleziona $title", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...items.map((e) => ListTile(
              title: Center(child: Text(e, style: TextStyle(color: _getPriorityColor(e), fontWeight: FontWeight.bold))),
              onTap: () { onSelect(e); Navigator.pop(context); },
            )),
          ],
        ),
      )
    );
  }

  Color _getPriorityColor(String txt) {
    if (txt.contains('High')) return Colors.red;
    if (txt == 'Medium') return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _onClean, child: const Text("Pulisci", style: TextStyle(color: Colors.blue, fontSize: 16))),
                const Text("Nuova Issue", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _isValid && !_isLoading ? _onSubmit : null, 
                  child: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Crea", style: TextStyle(color: _isValid ? Colors.green : Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.bold))
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _input("Titolo", _titleController),
                  const SizedBox(height: 16),
                  _input("Descrizione", _descController, lines: 4),
                  const SizedBox(height: 24),
                  
                  // Tipo e Foto
                  Row(
                    children: [
                      Expanded(child: _bigBtn(_selectedType ?? "Tipo", _selectedType != null, () => _showSheet("Tipo", _types, (v) => setState(() => _selectedType = v)))),
                      const SizedBox(width: 16),
                      Expanded(child: _bigBtn(_selectedImage != null ? "Foto OK" : "Foto", _selectedImage != null, () async { final img = await ImagePicker().pickImage(source: ImageSource.gallery); if(img!=null) setState(() => _selectedImage = img); })),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // MODIFICA 2: INVERTITO ORDINE
                  // Prima la Priorità
                  GestureDetector(
                    onTap: () => _showSheet("Priorità", _priorities, (v) => setState(() => _selectedPriority = v)),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
                      child: Text(_selectedPriority ?? "Aggiungi una priorità", style: TextStyle(color: _selectedPriority == null ? Colors.grey : Colors.white)),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Poi l'Etichetta (Opzionale)
                  _input("Etichetta (Opzionale)", _labelController),
                  
                  const SizedBox(height: 32), // Spazio extra in fondo
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String h, TextEditingController c, {int lines=1}) => TextField(controller: c, maxLines: lines, style: const TextStyle(color: Colors.white), onChanged: (_) => setState((){}), decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF1C1C1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  Widget _bigBtn(String l, bool s, VoidCallback t) => GestureDetector(onTap: t, child: Container(height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(25), border: s ? Border.all(color: Colors.blue) : null), child: Text(l, style: TextStyle(color: s ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold))));
}