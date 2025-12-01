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
  final List<String> tags; // <--- Questo è il campo fondamentale che manca!

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
    );
  }
}