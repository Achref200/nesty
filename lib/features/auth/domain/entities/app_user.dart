import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Domain entity representing an authenticated user.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.role = UserRole.seeker,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;

  /// A friendly display name, falling back to the email handle.
  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    return email.split('@').first;
  }

  AppUser copyWith({UserRole? role, String? fullName, String? avatarUrl}) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, avatarUrl, role];
}
