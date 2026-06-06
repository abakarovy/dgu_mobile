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
    this.isAdmin = false,
    this.position,
    this.avatarUrl,
    this.canAccessSiteAdmin = false,
    this.canAccessAdmissionAdmin = false,
    this.canAccessDepartmentCabinet = false,
    this.isTeacher = false,
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
  final bool isAdmin;
  final String? position;
  final String? avatarUrl;
  final bool canAccessSiteAdmin;
  final bool canAccessAdmissionAdmin;
  final bool canAccessDepartmentCabinet;
  final bool isTeacher;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullNameRaw = json['full_name'] ?? json['fio'];
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: fullNameRaw as String? ?? '',
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
      isAdmin: json['is_admin'] as bool? ?? false,
      position: json['position'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      canAccessSiteAdmin: json['can_access_site_admin'] as bool? ?? false,
      canAccessAdmissionAdmin: json['can_access_admission_admin'] as bool? ?? false,
      canAccessDepartmentCabinet: json['can_access_department_cabinet'] as bool? ?? false,
      isTeacher: json['is_teacher'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'fio': fullName,
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
      'is_admin': isAdmin,
      'position': position,
      'avatar_url': avatarUrl,
      'can_access_site_admin': canAccessSiteAdmin,
      'can_access_admission_admin': canAccessAdmissionAdmin,
      'can_access_department_cabinet': canAccessDepartmentCabinet,
      'is_teacher': isTeacher,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? role,
    bool? isAdmin,
    String? position,
    String? avatarUrl,
    bool? canAccessSiteAdmin,
    bool? canAccessAdmissionAdmin,
    bool? canAccessDepartmentCabinet,
    bool? isTeacher,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      studentBookNumber: studentBookNumber,
      parentEmail: parentEmail,
      course: course,
      direction: direction,
      groupId: groupId,
      department: department,
      bio: bio,
      isActive: isActive,
      createdAt: createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      position: position ?? this.position,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      canAccessSiteAdmin: canAccessSiteAdmin ?? this.canAccessSiteAdmin,
      canAccessAdmissionAdmin:
          canAccessAdmissionAdmin ?? this.canAccessAdmissionAdmin,
      canAccessDepartmentCabinet:
          canAccessDepartmentCabinet ?? this.canAccessDepartmentCabinet,
      isTeacher: isTeacher ?? this.isTeacher,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id.toString(),
        email: email,
        fullName: fullName,
        role: role,
        studentBookNumber: studentBookNumber,
        course: course,
        direction: direction,
        isAdmin: isAdmin,
        position: position,
        avatarUrl: avatarUrl,
        canAccessSiteAdmin: canAccessSiteAdmin,
        canAccessAdmissionAdmin: canAccessAdmissionAdmin,
        canAccessDepartmentCabinet: canAccessDepartmentCabinet,
        isTeacher: isTeacher,
      );
}
