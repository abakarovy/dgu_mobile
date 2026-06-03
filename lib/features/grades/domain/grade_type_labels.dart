/// Распознавание типов контроля из 1С и короткие подписи для UI.
abstract final class GradeTypeLabels {
  GradeTypeLabels._();

  static String _norm(String raw) =>
      raw.trim().toLowerCase().replaceAll('ё', 'е');

  /// Диф./деферинцированный зачёт — в ответах 1С часто «деферинцированный».
  static bool isDifferentiatedCredit(String typeRaw) {
    final t = _norm(typeRaw);
    if (!t.contains('зач') || t.contains('незач')) return false;
    return t.contains('дифф') ||
        t.contains('диферен') ||
        t.contains('деферин') ||
        t.contains('дефенц') ||
        t.contains('different');
  }

  static bool isPlainCredit(String typeRaw) {
    final t = _norm(typeRaw);
    return t.contains('зач') && !t.contains('незач') && !isDifferentiatedCredit(typeRaw);
  }

  static bool isExam(String typeRaw) {
    final t = _norm(typeRaw);
    return t.contains('экзам') || t.contains('гэк') || t.contains('гос');
  }

  static bool isCoursework(String typeRaw) => _norm(typeRaw).contains('курсов');

  /// Итог сессии: зачёт, экзамен, курсовая и т.п. (не текущие К/Р, пропуски).
  static bool isSessionOutcome(String typeRaw) {
    final t = _norm(typeRaw);
    if (t.isEmpty) return false;
    if (t.contains('ответ у доски')) return false;
    if (t.contains('пропуск')) return false;
    if (t.contains('контрольная')) return false;
    if (t.contains('к/р')) return false;
    if (t.contains('незач')) return false;
    return isExam(typeRaw) ||
        isDifferentiatedCredit(typeRaw) ||
        isCoursework(typeRaw) ||
        t.contains('итог') ||
        isPlainCredit(typeRaw);
  }

  /// Короткая подпись для чипов и списков: «Диф. зачёт», «Зачёт», «Экзамен»…
  static String displayLabel(String typeRaw) {
    final t = _norm(typeRaw);
    if (t.isEmpty) return '';
    if (isDifferentiatedCredit(typeRaw)) return 'Диф. зачёт';
    if (isCoursework(typeRaw)) return 'Курсовая';
    if (t.contains('экзам')) return 'Экзамен';
    if (isPlainCredit(typeRaw)) return 'Зачёт';
    if (t.contains('итог')) return 'Итоговая атт.';
    if (t.contains('гэк')) return 'ГЭК';
    if (t.contains('гос')) return 'Гос. экзамен';
    if (t.contains('аттестация 1') || t.contains('att 1') || (t.contains('1 ат') && !t.contains('ответ'))) {
      return 'Аттестация 1';
    }
    if (t.contains('аттестация 2') || t.contains('att 2') || t.contains('2 ат')) {
      return 'Аттестация 2';
    }
    if (t.contains('пропуск')) return 'Пропуск';
    if (t.contains('контрольная')) return 'Контрольная';
    return typeRaw.trim();
  }

  /// Слот итога сессии для группировки по предмету.
  static String? sessionSlot(String typeRaw) {
    final t = _norm(typeRaw);
    if (t.contains('аттестация 1') ||
        t.contains('att 1') ||
        (t.contains('1 ат') && !t.contains('ответ'))) {
      return 'att1';
    }
    if (t.contains('аттестация 2') || t.contains('att 2') || t.contains('2 ат')) {
      return 'att2';
    }
    if (isDifferentiatedCredit(typeRaw)) return 'dfk';
    if (isCoursework(typeRaw)) return 'kurs';
    if (t.contains('экзам') || t.contains('итог') || t.contains('гэк') || t.contains('гос')) {
      return 'ekz';
    }
    if (isPlainCredit(typeRaw)) return 'zach';
    return null;
  }

  static bool matchesSlot(String typeLower, String slot) {
    switch (slot) {
      case 'dfk':
        return isDifferentiatedCredit(typeLower);
      case 'kurs':
        return isCoursework(typeLower);
      case 'ekz':
        final t = _norm(typeLower);
        return t.contains('экзам') || t.contains('итог') || t.contains('гэк') || t.contains('гос');
      case 'zach':
        return isPlainCredit(typeLower);
      case 'att1':
        final t = _norm(typeLower);
        return t.contains('аттестация 1') ||
            t.contains('att 1') ||
            (t.contains('1 ат') && !t.contains('ответ'));
      case 'att2':
        final t = _norm(typeLower);
        return t.contains('аттестация 2') || t.contains('att 2') || t.contains('2 ат');
      default:
        return false;
    }
  }
}
