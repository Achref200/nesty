import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// Data-layer representation of [AppUser] with (de)serialization helpers.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    super.role,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    final metadata =
        (map['user_metadata'] as Map<String, dynamic>?) ?? const {};
    return AppUserModel(
      id: map['id'] as String,
      email: (map['email'] as String?) ?? '',
      fullName: (map['full_name'] ?? metadata['full_name']) as String?,
      avatarUrl: (map['avatar_url'] ?? metadata['avatar_url']) as String?,
      role: UserRoleX.fromId((map['role'] ?? metadata['role']) as String?),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'role': role.id,
  };
}
