import 'package:flutter/material.dart';
import 'dart:io';
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

  // --- FUNZIONE SCHERMO INTERO (REINSERITA) ---
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

  // Helper immagini intelligente
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatusPill(_issue!.status), _buildPriorityPill(_issue!.priority)]),
                const SizedBox(height: 24),
                Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)), child: Text(_issue!.description, style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14))),
                const SizedBox(height: 24),
                
                // SEZIONE ALLEGATI (CON ANTEPRIMA QUADRATA + CLICK)
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

  // --- SEZIONE ALLEGATI AGGIORNATA (MINIATURA + ZOOM) ---
  Widget _buildAttachmentsSection() {
    bool hasImage = _issue!.imageUrl != null && _issue!.imageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasImage ? () => setState(() => _isAttachmentsExpanded = !_isAttachmentsExpanded) : null,
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
                  color: hasImage ? Colors.white : Colors.grey.shade700
                ),
              ],
            ),
          ),
        ),
        
        // MOSTRA MINIATURA SOLO SE ESPANSO (e se c'è foto)
        if (_isAttachmentsExpanded && hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 100, // Altezza fissa per la miniatura
              child: Row(
                children: [
                  GestureDetector(
                    // CLICK -> APRE FULL SCREEN
                    onTap: () => _openFullScreenImage(_issue!.imageUrl!),
                    child: Container(
                      width: 100, // Larghezza fissa (quadrato)
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                        image: DecorationImage(
                          image: _getImageProvider(_issue!.imageUrl!),
                          fit: BoxFit.cover, // Taglia l'immagine per riempire il quadrato
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    // Logica ID + Email
    bool isMyComment = false;
    if (_currentUserId != null && comment.authorId != 0) {
      isMyComment = (_currentUserId == comment.authorId);
    } else if (_currentUserEmail != null && comment.authorEmail != null) {
      isMyComment = _currentUserEmail!.trim().toLowerCase() == comment.authorEmail!.trim().toLowerCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade700, 
                    radius: 14, 
                    child: Text(comment.authorEmail.isNotEmpty ? comment.authorEmail[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 12))
                  ),
                  const SizedBox(width: 10),
                  Text(comment.authorEmail, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13))
                ],
              ),
              if (isMyComment) 
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22), 
                  onPressed: () => _deleteComment(comment.id), 
                  padding: EdgeInsets.zero, 
                  constraints: const BoxConstraints()
                )
            ]
          ),
          const SizedBox(height: 8), 
          Padding(
            padding: const EdgeInsets.only(left: 38.0), 
            child: Text(comment.content, style: const TextStyle(color: Colors.white, fontSize: 15))
          ) 
        ]
      )
    );
  }

  // Helpers UI
  Widget _buildInfoCard({required String title, required String value, required IconData icon, required Color accentColor, bool isPlaceholder = false}) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: isPlaceholder ? Colors.white10 : accentColor.withValues(alpha: 0.3), width: 1.5)), child: Column(children: [Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isPlaceholder?Icons.label_off_outlined:icon, color: isPlaceholder?Colors.grey.shade600:accentColor, size: isPlaceholder?20:22), const SizedBox(width: 8), Flexible(child: Text(value, style: TextStyle(color: isPlaceholder?Colors.grey.shade600:accentColor, fontWeight: isPlaceholder?FontWeight.w500:FontWeight.w900, fontSize: isPlaceholder?16:18, fontStyle: isPlaceholder?FontStyle.italic:FontStyle.normal), overflow: TextOverflow.ellipsis))])]));
  }
  Widget _buildStatusPill(String s) { String t=s=="IN_PROGRESS"?"In corso":s=="DONE"?"Completata":"To do"; return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(8)), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))); }
  Widget _buildPriorityPill(String? p) { if(p==null)return const SizedBox(); String t=p.replaceAll('_',' ').toLowerCase().split(' ').map((w)=>w.isNotEmpty?'${w[0].toUpperCase()}${w.substring(1)}':'').join(' '); return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade900)), child: Row(children:[const Icon(Icons.keyboard_double_arrow_up, color: Colors.red, size: 16), const SizedBox(width: 6), Text(t, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])); }
  String _formatType(String type) => type[0] + type.substring(1).toLowerCase();
  Color _getTypeColor(String type) { switch (type) { case 'BUG': return Colors.red; case 'FEATURE': return Colors.blue; case 'QUESTION': return Colors.orange; default: return Colors.white; } }
  IconData _getIconDataForType(String type) { switch (type) { case 'BUG': return Icons.bug_report_outlined; case 'FEATURE': return Icons.check_box_outlined; case 'QUESTION': return Icons.help_outline; default: return Icons.description_outlined; } }
  Widget _getIconForType(String type) => Icon(_getIconDataForType(type), color: _getTypeColor(type), size: 32);
}