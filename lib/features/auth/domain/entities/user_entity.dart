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
    this.isAdmin = false,
    this.position,
    this.avatarUrl,
    this.canAccessSiteAdmin = false,
    this.canAccessAdmissionAdmin = false,
    this.canAccessDepartmentCabinet = false,
    this.isTeacher = false,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? studentBookNumber;
  final int? course;
  final String? direction;
  final bool isAdmin;
  final String? position;
  final String? avatarUrl;
  final bool canAccessSiteAdmin;
  final bool canAccessAdmissionAdmin;
  final bool canAccessDepartmentCabinet;
  final bool isTeacher;
}
