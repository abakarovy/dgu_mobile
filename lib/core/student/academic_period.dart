/// Учебный год и семестр для стипендиального рейтинга
/// (`GET /scholarship-rating/my/summary`, `POST .../my/upload`).
///
/// В API передаётся **`semester`** как строка **`1`** или **`2`** (как на действующем бэкенде колледжа).
class AcademicPeriod {
  const AcademicPeriod({required this.academicYear, required this.semester});

  final String academicYear;

  /// Значение для query: `1` или `2`.
  final String semester;

  /// Подпись в карточках (рус.).
  String get semesterLabelRu => semester == '1'
      ? '1-й'
      : semester == '2'
          ? '2-й'
          : semester;

  static AcademicPeriod current({DateTime? at}) {
    final now = at ?? DateTime.now();
    final y = now.year;
    final m = now.month;

    final String academicYear;
    if (m >= 9) {
      academicYear = '$y-${y + 1}';
    } else {
      academicYear = '${y - 1}-$y';
    }

    // Сентябрь–январь — 1-й семестр; февраль–август — 2-й.
    final String semester;
    if (m >= 9 || m == 1) {
      semester = '1';
    } else {
      semester = '2';
    }

    return AcademicPeriod(academicYear: academicYear, semester: semester);
  }
}
