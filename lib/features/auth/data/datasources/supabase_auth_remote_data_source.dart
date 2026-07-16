import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_role.dart';
import '../models/app_user_model.dart';
import 'auth_remote_data_source.dart';

/// Supabase-backed authentication. Used automatically once real credentials
/// are configured.
class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  const SupabaseAuthRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthException('Invalid credentials.');
      return await _mapUser(user);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role.id},
      );
      final user = res.user;
      if (user == null) throw const AuthException('Could not create account.');
      return await _mapUser(user);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<AppUserModel?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await _mapUser(user);
  }

  @override
  Future<AppUserModel> updateProfile({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
  }) async {
    final current = _client.auth.currentUser;
    if (current == null) throw const AuthException('You need to be signed in.');
    final metadata = <String, dynamic>{...?current.userMetadata};
    if (fullName != null) metadata['full_name'] = fullName;
    if (role != null) metadata['role'] = role.id;
    if (avatarUrl != null) metadata['avatar_url'] = avatarUrl;
    try {
      final res = await _client.auth.updateUser(
        sb.UserAttributes(data: metadata),
      );
      final user = res.user;
      if (user == null) throw const AuthException('Could not update profile.');
      // Persist to the profiles table too — that's the source _mapUser reads,
      // so name/avatar/role changes reflect everywhere (web + mobile).
      final patch = <String, dynamic>{'id': user.id};
      if (fullName != null) patch['full_name'] = fullName;
      if (role != null) patch['role'] = role.id;
      if (avatarUrl != null) patch['avatar_url'] = avatarUrl;
      if (patch.length > 1) {
        try {
          await _client.from('profiles').upsert(patch);
        } catch (_) {
          // RLS/offline — metadata still updated; profile catches up later.
        }
      }
      return await _mapUser(user);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Builds the app user, reading the authoritative role from the `profiles`
  /// table (same source the web dashboard uses) and falling back to the auth
  /// metadata. This is what makes a host land on the host experience and a
  /// seeker on the seeker experience — even for accounts provisioned in SQL.
  Future<AppUserModel> _mapUser(sb.User user) async {
    String? role;
    String? fullName = user.userMetadata?['full_name'] as String?;
    String? avatar = user.userMetadata?['avatar_url'] as String?;
    try {
      final row = await _client
          .from('profiles')
          .select('role, full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        role = row['role'] as String?;
        fullName = (row['full_name'] as String?) ?? fullName;
        avatar = (row['avatar_url'] as String?) ?? avatar;
      }
    } catch (_) {
      // Offline or RLS hiccup — fall back to auth metadata below.
    }
    role ??= user.userMetadata?['role'] as String?;
    return AppUserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
      avatarUrl: avatar,
      role: UserRoleX.fromId(role),
    );
  }

  static const _oauthRedirect = 'io.supabase.nesty://login-callback';
  static const _resetRedirect = 'io.supabase.nesty://reset-callback';

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: _resetRedirect);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<bool> signInWithProvider(String provider) async {
    final p = provider == 'apple'
        ? sb.OAuthProvider.apple
        : sb.OAuthProvider.google;
    try {
      return await _client.auth.signInWithOAuth(p, redirectTo: _oauthRedirect);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Stream<AppUserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      return user == null ? null : await _mapUser(user);
    });
  }
}
