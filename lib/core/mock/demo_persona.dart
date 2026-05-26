/// Демо-студент: структура как у реального API (college.dgu.ru), ФИО в формате «Имя Фамилия Отчество».
abstract final class DemoPersona {
  static const userId = 10;
  static const email = 'test@test.ru';

  static const firstName = 'Магомедгаджи';
  static const lastName = 'Гаджилаев';
  static const patronymic = 'Гаджилавович';

  /// Отображаемое ФИО: имя, фамилия, отчество (не капс, не «фамилия первая»).
  static const fullName = '$firstName $lastName $patronymic';

  static const studentBookNumber = '22325';
  static const course = 4;
  static const direction = '09.02.07 Информационные системы и программирование';
  static const department = 'Информационные системы и программирование';
  static const studyGroup = 'ИСиП 4к 1г 2022';
  static const curator = 'Абдуллаева Наргис Ассадуллаевна';
  static const birthday = '23.04.2007';
  static const admissionYear = '2022';
  static const studyForm = 'Очная форма обучения';
  static const status = 'Обучается';
  static const fundingType = 'Бюджетное финансирование';

  static const createdAt = '2026-05-12T10:03:43.923440Z';
}
