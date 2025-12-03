import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Importante per decodificare la lista
import 'package:flutter/foundation.dart'; // Per kIsWeb
import '../models/issue.dart';
import '../services/issue_service.dart';

class IssueDetailScreen extends StatefulWidget {
  final int issueId;

  const IssueDetailScreen({super.key, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final IssueService _issueService = IssueService();
  final TextEditingController _commentController = TextEditingController();
  
  Issue? _issue;
  bool _isLoading = true;
  int? _currentUserId;
  String? _currentUserEmail;
  bool _isAttachmentsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final userId = await _issueService.getCurrentUserId();
    final userEmail = await _issueService.getCurrentUserEmail();
    final issue = await _issueService.getIssueDetails(widget.issueId);
    
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _currentUserEmail = userEmail;
        _issue = issue;
        _isLoading = false;
      });
    }
  }

  // --- HELPER PER LEGGERE LA LISTA IMMAGINI ---
  List<String> _parseImages(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      // Proviamo a leggerlo come lista JSON ["img1", "img2"]
      List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      // Se fallisce, è un vecchio formato (stringa singola), lo mettiamo in lista
      return [jsonString!];
    }
  }

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Commento non valido", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: const Text("Il contenuto del commento non può essere vuoto.", style: TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Ok", style: TextStyle(color: Colors.blue)))],
        ),
      );
      return;
    }

    bool success = await _issueService.postComment(widget.issueId, _commentController.text);
    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore invio commento")));
    }
  }

  void _deleteComment(int commentId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Elimina", style: TextStyle(color: Colors.white)),
        content: const Text("Vuoi eliminare questo commento?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text("No"), onPressed: () => Navigator.pop(c, false)),
          TextButton(child: const Text("Sì", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(c, true)),
        ],
      )
    ) ?? false;

    if (confirm) {
      await _issueService.deleteComment(commentId);
      _loadData();
    }
  }

  void _changeStatus() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
              const Text("Aggiorna Stato", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildFancyStatusOption("To do", "TODO", Colors.orange, Icons.schedule),
              const SizedBox(height: 12),
              _buildFancyStatusOption("In corso", "IN_PROGRESS", Colors.blue, Icons.autorenew),
              const SizedBox(height: 12),
              _buildFancyStatusOption("Completata", "DONE", Colors.green, Icons.check_circle_outline),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFancyStatusOption(String label, String backendValue, Color color, IconData icon) {
    bool isSelected = _issue!.status == backendValue;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        if (isSelected) return;
        setState(() => _isLoading = true);
        bool success = await _issueService.updateStatus(widget.issueId, backendValue);
        if (success) _loadData();
        else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore aggiornamento stato")));
        }
      },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(icon, color: isSelected ? color : Colors.grey, size: 24), const SizedBox(width: 16), Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold))]),
          if (isSelected) Icon(Icons.check, color: color, size: 24),
        ]),
      ),
    );
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text("Allegato", style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image(
                image: _getImageProvider(imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (kIsWeb) return NetworkImage(path);
    if (path.startsWith('http')) return NetworkImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    if (_issue == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Errore caricamento", style: TextStyle(color: Colors.white))));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(_issue!.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))), const SizedBox(width: 8), _getIconForType(_issue!.type)]),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    GestureDetector(
                      onTap: _changeStatus, 
                      child: _buildStatusPill(_issue!.status)
                    ), 
                    _buildPriorityPill(_issue!.priority)
                  ]
                ),
                
                const SizedBox(height: 24),
                Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)), child: Text(_issue!.description, style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14))),
                const SizedBox(height: 24),
                
                // --- SEZIONE ALLEGATI CORRETTA ---
                _buildAttachmentsSection(),
                
                const SizedBox(height: 24),
                Row(children: [Expanded(child: _buildInfoCard(title: "TIPO", value: _formatType(_issue!.type), icon: _getIconDataForType(_issue!.type), accentColor: _getTypeColor(_issue!.type))), const SizedBox(width: 12), Expanded(child: _buildInfoCard(title: "ETICHETTA", value: _issue!.tags.isNotEmpty ? _issue!.tags.first : "Nessuna", icon: Icons.label_outline, accentColor: _issue!.tags.isNotEmpty ? Colors.white : Colors.grey.shade700, isPlaceholder: _issue!.tags.isEmpty))]),
                const SizedBox(height: 32),
                const Text("Commenti", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_issue!.comments.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 20), child: Text("Nessun commento ancora.", style: TextStyle(color: Colors.grey))),
                ..._issue!.comments.map((c) => _buildCommentItem(c)),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [Expanded(child: TextField(controller: _commentController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Aggiungi un commento...", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none, isDense: true))), IconButton(icon: const Icon(Icons.send, color: Colors.blueAccent), onPressed: _sendComment)]),
          ),
        ],
      ),
    );
  }

  // --- WIDGET ALLEGATI (LISTA MULTIPLA) ---
  Widget _buildAttachmentsSection() {
    // Recuperiamo la lista di stringhe
    List<String> images = _parseImages(_issue!.imageUrl);
    bool hasImages = images.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasImages ? () => setState(() => _isAttachmentsExpanded = !_isAttachmentsExpanded) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Allegati", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(
                  _isAttachmentsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                  color: hasImages ? Colors.white : Colors.grey.shade700
                ),
              ],
            ),
          ),
        ),
        
        // Se espanso e ci sono immagini, mostra la lista orizzontale
        if (_isAttachmentsExpanded && hasImages)
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullScreenImage(images[index]),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                      image: DecorationImage(
                        image: _getImageProvider(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor = Colors.grey.shade800;
    String text = "To do";
    if (status == 'TODO') { bgColor = const Color(0xFF3A3A3C); text = "To do"; }
    else if (status == 'IN_PROGRESS') { bgColor = Colors.blue; text = "In corso"; }
    else if (status == 'DONE') { bgColor = const Color(0xFF4CAF50); text = "Completata"; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPriorityPill(String? priority) {
    if (priority == null) return const SizedBox();
    String pUpper = priority.toUpperCase().replaceAll('_', ' ');
    String displayText = pUpper.split(' ').map((w) => w[0] + w.substring(1).toLowerCase()).join(' ');

    Color color;
    IconData icon;

    if (pUpper.contains('VERY HIGH')) { color = const Color(0xFFE53935); icon = Icons.keyboard_double_arrow_up; } 
    else if (pUpper.contains('HIGH')) { color = const Color(0xFFFF5252); icon = Icons.keyboard_arrow_up; } 
    else if (pUpper.contains('MEDIUM')) { color = const Color(0xFFFF9800); icon = Icons.drag_handle; } 
    else if (pUpper.contains('VERY LOW')) { color = const Color(0xFF64B5F6); icon = Icons.keyboard_double_arrow_down; } 
    else if (pUpper.contains('LOW')) { color = const Color(0xFF2196F3); icon = Icons.keyboard_arrow_down; } 
    else { color = Colors.grey; icon = Icons.help_outline; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.5), width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(displayText, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    bool isMyComment = false;
    if (_currentUserId != null && comment.authorId != 0) isMyComment = (_currentUserId == comment.authorId);
    else if (_currentUserEmail != null && comment.authorEmail != null) isMyComment = _currentUserEmail!.trim().toLowerCase() == comment.authorEmail!.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [CircleAvatar(backgroundColor: Colors.grey.shade700, radius: 14, child: Text(comment.authorEmail.isNotEmpty ? comment.authorEmail[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 12))), const SizedBox(width: 10), Text(comment.authorEmail, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13))]),
          if (isMyComment) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22), onPressed: () => _deleteComment(comment.id), padding: EdgeInsets.zero, constraints: const BoxConstraints())
        ]),
        const SizedBox(height: 8), Padding(padding: const EdgeInsets.only(left: 38.0), child: Text(comment.content, style: const TextStyle(color: Colors.white, fontSize: 15)))
      ]),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon, required Color accentColor, bool isPlaceholder = false}) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: isPlaceholder ? Colors.white10 : accentColor.withValues(alpha: 0.3), width: 1.5)), child: Column(children: [Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isPlaceholder?Icons.label_off_outlined:icon, color: isPlaceholder?Colors.grey.shade600:accentColor, size: isPlaceholder?20:22), const SizedBox(width: 8), Flexible(child: Text(value, style: TextStyle(color: isPlaceholder?Colors.grey.shade600:accentColor, fontWeight: isPlaceholder?FontWeight.w500:FontWeight.w900, fontSize: isPlaceholder?16:18, fontStyle: isPlaceholder?FontStyle.italic:FontStyle.normal), overflow: TextOverflow.ellipsis))])]));
  }
  String _formatType(String type) => type[0] + type.substring(1).toLowerCase();
  Color _getTypeColor(String type) { switch (type) { case 'BUG': return Colors.red; case 'FEATURE': return Colors.blue; case 'QUESTION': return Colors.orange; default: return Colors.white; } }
  IconData _getIconDataForType(String type) { switch (type) { case 'BUG': return Icons.bug_report_outlined; case 'FEATURE': return Icons.check_box_outlined; case 'QUESTION': return Icons.help_outline; default: return Icons.description_outlined; } }
  Widget _getIconForType(String type) => Icon(_getIconDataForType(type), color: _getTypeColor(type), size: 32);
}