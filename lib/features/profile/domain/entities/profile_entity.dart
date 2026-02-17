/// Профиль студента (ФИО, группа, факультет).
class ProfileEntity {
  const ProfileEntity({
    required this.fullName,
    this.group,
    this.faculty,
    this.avatarUrl,
  });

  final String fullName;
  final String? group;
  final String? faculty;
  final String? avatarUrl;
}
