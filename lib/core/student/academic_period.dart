/// Учебный год и семестр для стипендиального рейтинга
/// (`GET /scholarship-rating/my/summary`, `POST .../my/upload`).
///
/// В query **`semester`** передаётся строка **`fall`** или **`spring`** (см. MOBILE_SCHOLARSHIP_RATING_CATALOG_RU).
class AcademicPeriod {
  const AcademicPeriod({required this.academicYear, required this.semester});

  final String academicYear;

  /// В приложении хранится как **`1`** (осень) или **`2`** (весна). Для API см. [normalizedSemester].
  final String semester;

  /// Семестр для query API: `1`/`2` → `fall`/`spring` (см. MOBILE_SCHOLARSHIP_RATING_CATALOG_RU).
  String get normalizedSemester {
    switch (semester) {
      case '1':
        return 'fall';
      case '2':
        return 'spring';
      case 'fall':
      case 'spring':
        return semester;
      default:
        return semester;
    }
  }

  /// Подпись в карточках (рус.).
  String get semesterLabelRu => switch (semester) {
        '1' || 'fall' => 'осенний',
        '2' || 'spring' => 'весенний',
        _ => semester,
      };

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

    // Сентябрь–январь — 1-й семестр (осень); февраль–август — 2-й (весна). В API уходит как fall/spring.
    final String semester;
    if (m >= 9 || m == 1) {
      semester = '1';
    } else {
      semester = '2';
    }

    return AcademicPeriod(academicYear: academicYear, semester: semester);
  }
}
