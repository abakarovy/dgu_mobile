import '../../features/auth/domain/entities/user_entity.dart';

/// DTO пользователя из College DGU API.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentBookNumber,
    this.parentEmail,
    this.course,
    this.direction,
    this.groupId,
    this.department,
    this.bio,
    this.isActive = true,
    this.createdAt,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? studentBookNumber;
  final String? parentEmail;
  final int? course;
  final String? direction;
  final int? groupId;
  final String? department;
  final String? bio;
  final bool isActive;
  final String? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      studentBookNumber: json['student_book_number'] as String?,
      parentEmail: json['parent_email'] as String?,
      course: json['course'] as int?,
      direction: json['direction'] as String?,
      groupId: json['group_id'] as int?,
      department: json['department'] as String?,
      bio: json['bio'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'student_book_number': studentBookNumber,
      'parent_email': parentEmail,
      'course': course,
      'direction': direction,
      'group_id': groupId,
      'department': department,
      'bio': bio,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  UserEntity toEntity() => UserEntity(
        id: id.toString(),
        email: email,
        fullName: fullName,
        role: role,
        studentBookNumber: studentBookNumber,
        course: course,
        direction: direction,
      );
}
