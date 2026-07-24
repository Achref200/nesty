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
    this.bannedUntil,
    this.banReason,
    this.banType,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;

  /// When set to a future instant, the account is currently suspended. The
  /// value rides in the session (Supabase `app_metadata`) so a ban applied by
  /// the admin console takes effect without waiting for the access token to
  /// expire.
  final DateTime? bannedUntil;

  /// The reason for a suspension, when the console provided one.
  final String? banReason;

  /// 'disable' for a paused contract (host/agency), otherwise a sanction.
  final String? banType;

  /// A friendly display name, falling back to the email handle.
  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    return email.split('@').first;
  }

  /// True while a suspension is in effect (a future [bannedUntil]).
  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  AppUser copyWith({UserRole? role, String? fullName, String? avatarUrl}) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      bannedUntil: bannedUntil,
      banReason: banReason,
      banType: banType,
    );
  }

  @override
  List<Object?> get props =>
      [id, email, fullName, avatarUrl, role, bannedUntil, banReason, banType];
}
