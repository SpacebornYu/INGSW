import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Per kIsWeb
import '../services/issue_service.dart';

class CreateIssueScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateIssueScreen({super.key, this.onSuccess});

  @override
  State<CreateIssueScreen> createState() => CreateIssueScreenState();
}

class CreateIssueScreenState extends State<CreateIssueScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _labelController = TextEditingController(); // Controller per l'input
  String? _selectedType;
  String? _selectedPriority;
  List<XFile> _selectedImages = [];
  List<String> _tags = []; // LISTA DELLE ETICHETTE
  bool _isLoading = false;
  final IssueService _issueService = IssueService();

  final List<String> _types = ['Bug', 'Question', 'Documentation', 'Feature'];
  final List<String> _priorities = ['Very High', 'High', 'Medium', 'Low', 'Very Low'];

  bool get _isValid =>
      _titleController.text.isNotEmpty &&
      _descController.text.isNotEmpty &&
      _selectedType != null &&
      _selectedPriority != null;

  bool get hasChanges {
    return _titleController.text.isNotEmpty ||
           _descController.text.isNotEmpty ||
           _selectedType != null ||
           _tags.isNotEmpty || // Controlliamo se ci sono tag
           _selectedPriority != null ||
           _selectedImages.isNotEmpty;
  }

  void clearAll() {
    setState(() {
      _titleController.clear();
      _descController.clear();
      _labelController.clear();
      _selectedType = null;
      _selectedPriority = null;
      _selectedImages.clear();
      _tags.clear(); // Puliamo i tag
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

  // LOGICA AGGIUNTA TAG
  void _addTag(String value) {
    if (value.trim().isEmpty) return;
    if (_tags.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Massimo 5 etichette!")));
      return;
    }
    setState(() {
      _tags.add(value.trim());
      _labelController.clear(); // Pulisce l'input per scriverne un'altra
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImages.add(image));
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

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
          TextButton(child: const Text("Sì", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(c, true)),
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
      _tags, // Inviamo la lista di tag
      _selectedImages
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      clearAll();
      if (widget.onSuccess != null) widget.onSuccess!();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Errore creazione issue."),
        backgroundColor: Colors.red,
      ));
    }
  }

  ImageProvider _getImageProvider(XFile file) {
    if (kIsWeb) return NetworkImage(file.path);
    return FileImage(File(file.path));
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _onClean, child: const Text("Pulisci", style: TextStyle(color: Colors.blue, fontSize: 16))),
                const Flexible(
                  child: Text(
                    "Nuova Issue", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                  _input("Titolo", _titleController, maxLength: 100),
                  const SizedBox(height: 16),
                  _input("Descrizione", _descController, lines: 4, maxLength: 2000),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _bigBtn(_selectedType ?? "Tipo", _selectedType != null, () => _showSheet("Tipo", _types, (v) => setState(() => _selectedType = v)))),
                      const SizedBox(width: 16),
                      Expanded(child: _bigBtn("Aggiungi Foto", false, _pickImage, isDisabled: _selectedImages.length >= 3)),
                    ],
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (ctx, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12, top: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade800),
                                  image: DecorationImage(image: _getImageProvider(_selectedImages[index]), fit: BoxFit.cover)
                                ),
                              ),
                              Positioned(
                                right: 5,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showSheet("Priorità", _priorities, (v) => setState(() => _selectedPriority = v)),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
                      child: Text(_selectedPriority ?? "Aggiungi una priorità", style: TextStyle(color: _selectedPriority == null ? Colors.grey : Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ETICHETTE MULTIPLE
                  TextField(
                    controller: _labelController,
                    style: const TextStyle(color: Colors.white),
                    // QUANDO PREMI INVIO:
                    onSubmitted: _addTag,
                    decoration: InputDecoration(
                      hintText: "Aggiungi etichetta (Premi Invio)",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                  // VISUALIZZAZIONE A CHIP DELLE ETICHETTE
                  if (_tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color(0xFF2C2C2C),
                          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onDeleted: () => _removeTag(tag),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade800)),
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String h, TextEditingController c, {int lines=1, int? maxLength}) => TextField(
    controller: c, 
    maxLines: lines, 
    maxLength: maxLength,
    style: const TextStyle(color: Colors.white), 
    onChanged: (_) => setState((){}), 
    decoration: InputDecoration(
      hintText: h, 
      hintStyle: const TextStyle(color: Colors.grey), 
      filled: true, 
      fillColor: const Color(0xFF1C1C1E), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      counterStyle: const TextStyle(color: Colors.grey), // Stile del contatore
    )
  );
  Widget _bigBtn(String l, bool s, VoidCallback t, {bool isDisabled = false}) => GestureDetector(onTap: isDisabled ? null : t, child: Container(height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(25), border: s ? Border.all(color: Colors.blue) : null), child: Text(l, style: TextStyle(color: isDisabled ? Colors.grey.shade700 : (s ? Colors.blue : Colors.grey), fontWeight: FontWeight.bold))));
}