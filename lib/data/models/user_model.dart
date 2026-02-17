import '../../features/auth/domain/entities/user_entity.dart';

/// DTO пользователя из API.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
}
