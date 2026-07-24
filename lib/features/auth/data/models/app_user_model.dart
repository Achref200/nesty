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
    super.bannedUntil,
    super.banReason,
    super.banType,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    final metadata =
        (map['user_metadata'] as Map<String, dynamic>?) ?? const {};
    final appMeta =
        (map['app_metadata'] as Map<String, dynamic>?) ?? const {};
    return AppUserModel(
      id: map['id'] as String,
      email: (map['email'] as String?) ?? '',
      fullName: (map['full_name'] ?? metadata['full_name']) as String?,
      avatarUrl: (map['avatar_url'] ?? metadata['avatar_url']) as String?,
      role: UserRoleX.fromId((map['role'] ?? metadata['role']) as String?),
      bannedUntil: _parseDate(
        map['banned_until'] ?? appMeta['banned_until'] ?? appMeta['ban_until'],
      ),
      banReason: (map['ban_reason'] ?? appMeta['ban_reason']) as String?,
      banType: (map['ban_type'] ?? appMeta['ban_type']) as String?,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'role': role.id,
    if (bannedUntil != null) 'banned_until': bannedUntil!.toIso8601String(),
    if (banReason != null) 'ban_reason': banReason,
    if (banType != null) 'ban_type': banType,
  };
}
