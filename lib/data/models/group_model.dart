class GroupModel {
  const GroupModel({
    this.id,
    this.name,
    this.code,
  });

  final int? id;
  final String? name;
  final String? code;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v is String ? v : (v == null ? null : '$v');
    int? intv(dynamic v) => v is int ? v : int.tryParse(str(v) ?? '');

    return GroupModel(
      id: intv(json['id'] ?? json['group_id']),
      name: str(json['name'] ?? json['title']),
      code: str(json['code'] ?? json['group_code'] ?? json['number']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
      };

  String? get displayLabel {
    final c = (code ?? '').trim();
    final n = (name ?? '').trim();
    if (c.isNotEmpty) return c;
    if (n.isNotEmpty) return n;
    return null;
  }
}

