/// Сущность пользователя (студент/преподаватель/админ).
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentBookNumber,
    this.course,
    this.direction,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? studentBookNumber;
  final int? course;
  final String? direction;
}
