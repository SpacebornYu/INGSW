class Issue {
  final int id;
  final String title;
  final String description;
  final String type;
  final String? priority;
  final String status;
  final String creatorEmail;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String> tags;
  final List<Comment> comments; // <--- NUOVO: Lista commenti

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.priority,
    required this.status,
    required this.creatorEmail,
    required this.createdAt,
    this.imageUrl,
    required this.tags,
    required this.comments,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    var tagsList = <String>[];
    if (json['tags'] != null) {
      tagsList = (json['tags'] as List).map((t) {
        if (t is String) return t;
        if (t is Map && t['name'] != null) return t['name'].toString();
        return t.toString();
      }).toList();
    }

    // Parsing dei commenti
    var commentsList = <Comment>[];
    if (json['Comments'] != null) { // Nota: Sequelize spesso usa la maiuscola per le relazioni
      commentsList = (json['Comments'] as List).map((c) => Comment.fromJson(c)).toList();
    } else if (json['comments'] != null) {
      commentsList = (json['comments'] as List).map((c) => Comment.fromJson(c)).toList();
    }

    return Issue(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'],
      priority: json['priority'],
      status: json['status'],
      creatorEmail: json['creator'] != null ? json['creator']['email'] : 'Unknown',
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'],
      tags: tagsList,
      comments: commentsList,
    );
  }
}

// NUOVA CLASSE COMMENTO
class Comment {
  final int id;
  final String content;
  final String authorEmail;
  final int authorId; // Serve per capire se posso cancellarlo
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorEmail,
    required this.authorId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      authorEmail: json['author'] != null ? json['author']['email'] : 'Unknown',
      authorId: json['userId'] ?? 0, // Assicuriamoci di avere l'ID
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}