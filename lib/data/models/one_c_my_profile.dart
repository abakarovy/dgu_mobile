/// Ответ `GET /api/1c/my-profile` (поля 1С могут отличаться по именам).
class OneCMyProfile {
  const OneCMyProfile({
    this.fullName,
    this.birthDate,
    this.group,
    this.department,
    this.direction,
    this.curator,
    this.fundingType,
    this.socialRole,
    this.admissionYear,
    this.studyForm,
    this.status,
    this.studentBookNumber,
    this.course,
  });

  final String? fullName;
  final String? birthDate;
  final String? group;
  final String? department;
  final String? direction;
  final String? curator;
  final String? fundingType;
  final String? socialRole;
  final String? admissionYear;
  final String? studyForm;
  final String? status;
  final String? studentBookNumber;
  final int? course;

  static String? _str(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v == null) continue;
      final s = v is String ? v : '$v';
      final t = s.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static int? _int(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
    }
    return null;
  }

  /// Последнее 4‑значное число 19xx/20xx в названии группы (напр. «ОИБАС 3к 1г 2023»).
  static String? inferAdmissionYearFromGroup(String? groupLabel) {
    if (groupLabel == null || groupLabel.isEmpty) return null;
    final re = RegExp(r'\b(19|20)\d{2}\b');
    final matches = re.allMatches(groupLabel).toList();
    if (matches.isEmpty) return null;
    return matches.last.group(0);
  }

  static String? _normalizeBirthDisplay(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) {
      return _formatDdMmYyyy(v);
    }
    final s = (v is String) ? v.trim() : '$v'.trim();
    if (s.isEmpty) return null;
    if (RegExp(r'^\d{1,2}\.\d{1,2}\.\d{4}').hasMatch(s)) return s;
    final iso = DateTime.tryParse(s);
    if (iso != null) return _formatDdMmYyyy(iso);
    return s;
  }

  static String _formatDdMmYyyy(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}.${p2(d.month)}.${d.year}';
  }

  static String? _birthFromNested(Map<String, dynamic> j) {
    for (final root in ['personal', 'student', 'profile', 'data', 'card']) {
      final n = j[root];
      if (n is! Map) continue;
      final m = Map<String, dynamic>.from(n);
      final direct = _normalizeBirthDisplay(
        _pickBirthRaw(m),
      );
      if (direct != null && direct.isNotEmpty) return direct;
    }
    return null;
  }

  static dynamic _pickBirthRaw(Map<String, dynamic> m) {
    for (final k in [
      'birth_date',
      'birthDate',
      'birthday',
      'birth_day',
      'birthDay',
      'date_of_birth',
      'dateOfBirth',
      'ДатаРождения',
      'дата_рождения',
      'дата рождения',
    ]) {
      final v = m[k];
      if (v != null) return v;
    }
    return null;
  }

  factory OneCMyProfile.fromJson(Map<String, dynamic> j) {
    final groupStr = _str(j, [
      'group',
      'study_group',
      'group_name',
      'учебная_группа',
      'group_label',
    ]);

    var admission = _str(j, [
      'admission_year',
      'year_of_admission',
      'enrollment_year',
      'год_поступления',
      'admissionYear',
      'year_admission',
    ]);
    admission ??= inferAdmissionYearFromGroup(groupStr);

    var birth = _normalizeBirthDisplay(
      _pickBirthRaw(j),
    );
    birth ??= _birthFromNested(j);

    return OneCMyProfile(
      fullName: _str(j, [
        'full_name',
        'fio',
        'name',
        'student_name',
        'display_name',
      ]),
      birthDate: birth,
      group: groupStr,
      department: _str(j, ['department', 'faculty', 'отделение']),
      direction: _str(j, ['direction', 'specialty', 'специальность']),
      curator: _str(j, ['curator', 'curator_name', 'куратор']),
      fundingType: _str(j, ['funding_type', 'тип_финансирования', 'тип финансирования']),
      socialRole: _str(j, ['social_role', 'общественное_поручение', 'общественное поручение']),
      admissionYear: admission,
      studyForm: _str(j, ['study_form', 'education_form', 'форма_обучения']),
      status: _str(j, ['status', 'student_status', 'статус']),
      studentBookNumber: _str(j, [
        'student_book_number',
        'record_book',
        'зачетка',
        'student_id',
      ]),
      course: _int(j, ['course', 'курс']),
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'full_name': fullName,
        'birth_date': birthDate,
        'group': group,
        'department': department,
        'direction': direction,
        'curator': curator,
        'funding_type': fundingType,
        'social_role': socialRole,
        'admission_year': admissionYear,
        'study_form': studyForm,
        'status': status,
        'student_book_number': studentBookNumber,
        'course': course,
      };

  /// Подпись группы для UI: сначала строка из 1С, иначе из `GroupModel`.
  static String? resolveGroupLabel({
    required String? groupFrom1c,
    required String? groupFromApi,
  }) {
    final a = groupFrom1c?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = groupFromApi?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
