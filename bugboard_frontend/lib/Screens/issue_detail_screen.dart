import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
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

  List<String> _parseImages(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [jsonString!];
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
              _buildFancyStatusOption("To Do", "TODO", Colors.orange, Icons.schedule),
              const SizedBox(height: 12),
              _buildFancyStatusOption("In Corso", "IN_CORSO", Colors.blue, Icons.autorenew),
              const SizedBox(height: 12),
              _buildFancyStatusOption("Completata", "COMPLETATA", Colors.green, Icons.check_circle_outline),
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
        decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(icon, color: isSelected ? color : Colors.grey, size: 24), const SizedBox(width: 16), Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold))]),
          if (isSelected) Icon(Icons.check, color: color, size: 24),
        ]),
      ),
    );
  }

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF2C2C2C), title: const Text("Commento non valido", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), content: const Text("Il contenuto del commento non può essere vuoto.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Ok", style: TextStyle(color: Colors.blue)))]));
      return;
    }
    bool success = await _issueService.postComment(widget.issueId, _commentController.text);
    if (success) { _commentController.clear(); FocusScope.of(context).unfocus(); _loadData(); }
    else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore invio commento"))); }
  }

  void _deleteComment(int commentId) async {
    bool confirm = await showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF2C2C2C), title: const Text("Elimina", style: TextStyle(color: Colors.white)), content: const Text("Vuoi eliminare questo commento?", style: TextStyle(color: Colors.white70)), actions: [TextButton(child: const Text("No"), onPressed: () => Navigator.pop(c, false)), TextButton(child: const Text("Sì", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(c, true))])) ?? false;
    if (confirm) { await _issueService.deleteComment(commentId); _loadData(); }
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), title: const Text("Allegato", style: TextStyle(color: Colors.white))), body: Center(child: InteractiveViewer(child: Image(image: _getImageProvider(imageUrl), fit: BoxFit.contain))))));
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
      appBar: AppBar(backgroundColor: Colors.black, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => Navigator.pop(context)), elevation: 0),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(_issue!.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))), const SizedBox(width: 8), _getIconForType(_issue!.type)]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [GestureDetector(onTap: _changeStatus, child: _buildStatusPill(_issue!.status)), _buildPriorityPill(_issue!.priority)]),
          const SizedBox(height: 24),
          Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)), child: Text(_issue!.description, style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14))),
          const SizedBox(height: 24),
          _buildAttachmentsSection(),
          const SizedBox(height: 24),

          
          // Box TIPO 
          _buildTypeCard(
            title: "TIPO", 
            value: _formatType(_issue!.type), 
            icon: _getIconDataForType(_issue!.type), 
            color: _getTypeColor(_issue!.type)
          ),
          
          const SizedBox(height: 24),

          // Sezione ETICHETTE (Wrap)
          const Text("ETICHETTE", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          
          if (_issue!.tags.isEmpty)
            const Text("Nessuna etichetta", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _issue!.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade700)
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )).toList(),
            ),

          const SizedBox(height: 32),
          const Text("Commenti", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_issue!.comments.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 20), child: Text("Nessun commento ancora.", style: TextStyle(color: Colors.grey))),
          ..._issue!.comments.map((c) => _buildCommentItem(c)),
          const SizedBox(height: 20),
        ])),
        Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 30), decoration: const BoxDecoration(color: Color(0xFF121212), border: Border(top: BorderSide(color: Colors.white10, width: 1))), child: Row(children: [Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(24)), child: TextField(controller: _commentController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Scrivi un commento...", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12))))), const SizedBox(width: 12), GestureDetector(onTap: _sendComment, child: const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 22, child: Icon(Icons.arrow_upward, color: Colors.white, size: 24)))]))
      ]),
    );
  }

  Widget _buildTypeCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5), 
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22), 
              const SizedBox(width: 8),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() { List<String> images = _parseImages(_issue!.imageUrl); bool hasImages = images.isNotEmpty; return Column(children: [GestureDetector(onTap: hasImages ? () => setState(() => _isAttachmentsExpanded = !_isAttachmentsExpanded) : null, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Allegati", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Icon(_isAttachmentsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: hasImages ? Colors.white : Colors.grey.shade700)]))), if(_isAttachmentsExpanded && hasImages) Container(margin: const EdgeInsets.only(top: 12), height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: images.length, itemBuilder: (context, index) { return GestureDetector(onTap: () => _openFullScreenImage(images[index]), child: Container(width: 100, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800), image: DecorationImage(image: _getImageProvider(images[index]), fit: BoxFit.cover))));}))]); }
  Widget _buildCommentItem(dynamic c) { bool isMy = (_currentUserId != null && _currentUserId == c.authorId) || (_currentUserEmail != null && c.authorEmail != null && _currentUserEmail!.trim().toLowerCase() == c.authorEmail!.trim().toLowerCase()); return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [CircleAvatar(backgroundColor: Colors.grey.shade700, radius: 14, child: Text(c.authorEmail.isNotEmpty ? c.authorEmail[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 12))), const SizedBox(width: 10), Text(c.authorEmail, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13))]), if (isMy) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22), onPressed: () => _deleteComment(c.id), padding: EdgeInsets.zero, constraints: const BoxConstraints())]), const SizedBox(height: 8), Padding(padding: const EdgeInsets.only(left: 38.0), child: Text(c.content, style: const TextStyle(color: Colors.white, fontSize: 15))) ])); }
  Widget _buildStatusPill(String s) { String t=s=="IN_PROGRESS"?"In corso":s=="DONE"?"Completata":"To do"; return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(8)), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))); }
  Widget _buildPriorityPill(String? p) { if(p==null)return const SizedBox(); String t=p.replaceAll('_',' ').toLowerCase().split(' ').map((w)=>w.isNotEmpty?'${w[0].toUpperCase()}${w.substring(1)}':'').join(' '); Color c=Colors.grey; IconData i=Icons.help; if(p.toUpperCase().contains('VERY HIGH')){c=const Color(0xFFE53935);i=Icons.keyboard_double_arrow_up;}else if(p.toUpperCase().contains('HIGH')){c=const Color(0xFFFF5252);i=Icons.keyboard_arrow_up;}else if(p.toUpperCase().contains('MEDIUM')){c=const Color(0xFFFF9800);i=Icons.drag_handle;}else if(p.toUpperCase().contains('VERY LOW')){c=const Color(0xFF64B5F6);i=Icons.keyboard_double_arrow_down;}else if(p.toUpperCase().contains('LOW')){c=const Color(0xFF2196F3);i=Icons.keyboard_arrow_down;} return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.5), width: 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, color: c, size: 16), const SizedBox(width: 6), Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold))])); }
  String _formatType(String type) => type[0] + type.substring(1).toLowerCase();
  Color _getTypeColor(String type) { switch (type) { case 'BUG': return Colors.red; case 'FEATURE': return Colors.blue; case 'QUESTION': return Colors.orange; default: return Colors.white; } }
  IconData _getIconDataForType(String type) { switch (type) { case 'BUG': return Icons.bug_report_outlined; case 'FEATURE': return Icons.check_box_outlined; case 'QUESTION': return Icons.help_outline; default: return Icons.description_outlined; } }
  Widget _getIconForType(String type) => Icon(_getIconDataForType(type), color: _getTypeColor(type), size: 32);
}