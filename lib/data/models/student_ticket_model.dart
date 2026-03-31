class StudentTicketModel {
  const StudentTicketModel({
    this.fullName,
    this.studentBookNumber,
    this.birthDate,
    this.department,
    this.studyGroup,
    this.admissionYear,
    this.studyForm,
    this.status,
    this.course,
  });

  final String? fullName;
  final String? studentBookNumber;
  final String? birthDate;
  final String? department;
  final String? studyGroup;
  final String? admissionYear;
  final String? studyForm;
  final String? status;
  final int? course;

  factory StudentTicketModel.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      final out = (v is String) ? v.trim() : (v == null ? '' : '$v').trim();
      return out.isEmpty ? null : out;
    }

    int? i(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final t = s(v);
      return t == null ? null : int.tryParse(t);
    }

    return StudentTicketModel(
      fullName: s(json['full_name'] ?? json['fullName'] ?? json['fio']),
      studentBookNumber: s(json['student_book_number'] ?? json['studentBookNumber'] ?? json['record_book']),
      birthDate: s(json['birth_date'] ?? json['birthDate'] ?? json['birthday']),
      department: s(json['department'] ?? json['faculty']),
      studyGroup: s(json['study_group'] ?? json['group'] ?? json['group_label']),
      admissionYear: s(json['admission_year'] ?? json['year_of_admission']),
      studyForm: s(json['study_form'] ?? json['education_form']),
      status: s(json['status'] ?? json['student_status']),
      course: i(json['course']),
    );
  }

  Map<String, dynamic> toJsonMap() => {
        'full_name': fullName,
        'student_book_number': studentBookNumber,
        'birth_date': birthDate,
        'department': department,
        'study_group': studyGroup,
        'admission_year': admissionYear,
        'study_form': studyForm,
        'status': status,
        'course': course,
      };
}

