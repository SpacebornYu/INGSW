class Issue {
  final int id;
  final String title;
  final String description;
  final String type;      // BUG, FEATURE, ecc.
  final String? priority; // HIGH, LOW...
  final String status;    // TODO, IN_PROGRESS...
  final String creatorEmail;
  final DateTime createdAt;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.priority,
    required this.status,
    required this.creatorEmail,
    required this.createdAt,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'],
      priority: json['priority'],
      status: json['status'],
      // Il backend manda l'utente dentro l'oggetto 'creator'
      creatorEmail: json['creator'] != null ? json['creator']['email'] : 'Unknown',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}