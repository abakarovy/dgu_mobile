class AssignmentModel {
  const AssignmentModel({
    this.id,
    required this.title,
    this.description,
    this.subject,
    this.deadlineAt,
    this.createdAt,
    this.isDone,
  });

  final int? id;
  final String title;
  final String? description;
  final String? subject;
  final DateTime? deadlineAt;
  final DateTime? createdAt;
  final bool? isDone;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v is String) ? v : (v == null ? '' : '$v');
    String? sn(dynamic v) {
      final t = s(v).trim();
      return t.isEmpty ? null : t;
    }

    DateTime? dt(dynamic v) {
      final t = s(v).trim();
      if (t.isEmpty) return null;
      return DateTime.tryParse(t);
    }

    int? i(dynamic v) => v is int ? v : int.tryParse(s(v).trim());

    bool? b(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final t = s(v).trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
      return null;
    }

    return AssignmentModel(
      id: i(json['id']),
      title: (sn(json['title'] ?? json['name']) ?? 'Задание'),
      description: sn(json['description'] ?? json['text'] ?? json['content']),
      subject: sn(json['subject'] ?? json['subject_name'] ?? json['discipline']),
      deadlineAt: dt(json['deadline_at'] ?? json['deadline'] ?? json['due_at'] ?? json['due_date']),
      createdAt: dt(json['created_at']),
      isDone: b(json['is_done'] ?? json['done'] ?? json['completed']),
    );
  }
}

class AssignmentCreate {
  const AssignmentCreate({
    required this.title,
    this.description,
    this.subject,
    this.deadlineAt,
  });

  final String title;
  final String? description;
  final String? subject;
  final DateTime? deadlineAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null) 'description': description,
        if (subject != null) 'subject': subject,
        if (deadlineAt != null) 'deadline_at': deadlineAt!.toIso8601String(),
      };
}

