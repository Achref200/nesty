import '../../../../core/error/exceptions.dart';
import '../../../../core/services/local_store.dart';
import '../../domain/entities/account_standing.dart';
import '../../domain/entities/user_role.dart';
import '../models/app_user_model.dart';
import 'auth_remote_data_source.dart';

/// Local demo authentication used when Supabase is not configured.
///
/// Accepts any well-formed email/password so the full UX can be explored
/// without a backend. The signed-in user is persisted on-device via
/// [LocalStore], so the session (and the chosen role) survives a restart —
/// exactly like a real app.
class DemoAuthRemoteDataSource implements AuthRemoteDataSource {
  static const _sessionKey = 'auth.session';

  AppUserModel? _current;

  DemoAuthRemoteDataSource() {
    final saved = LocalStore.instance.getJson(_sessionKey);
    if (saved != null) _current = AppUserModel.fromMap(saved);
  }

  Future<void> _persist(AppUserModel? user) async {
    if (user == null) {
      await LocalStore.instance.remove(_sessionKey);
    } else {
      await LocalStore.instance.setJson(_sessionKey, user.toMap());
    }
  }

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _fakeLatency();
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    // Preserve the role of a returning account if we've seen it before.
    final previousRole = _current?.email == email.trim()
        ? _current?.role ?? UserRole.seeker
        : UserRole.seeker;
    // Demo simulation: an email containing 'banned' or 'disabled' comes back
    // suspended so the blocked-account UX can be explored without a backend.
    final ban = _simulatedBan(email);
    _current = AppUserModel(
      id: 'demo-${email.hashCode}',
      email: email,
      fullName: email.split('@').first,
      role: previousRole,
      bannedUntil: ban?.until,
      banReason: ban?.reason,
      banType: ban?.type,
    );
    await _persist(_current);
    return _current!;
  }

  @override
  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    await _fakeLatency();
    _current = AppUserModel(
      id: 'demo-${email.hashCode}',
      email: email,
      fullName: fullName,
      role: role,
    );
    await _persist(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    await _fakeLatency();
    _current = null;
    await _persist(null);
  }

  @override
  Future<AppUserModel?> currentUser() async => _current;

  @override
  Future<AppUserModel> updateProfile({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
  }) async {
    final current = _current;
    if (current == null) {
      throw const AuthException('You need to be signed in.');
    }
    _current = AppUserModel(
      id: current.id,
      email: current.email,
      fullName: fullName ?? current.fullName,
      avatarUrl: avatarUrl ?? current.avatarUrl,
      role: role ?? current.role,
    );
    await _persist(_current);
    return _current!;
  }

  Future<void> _fakeLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<bool> signInWithProvider(String provider) async {
    throw const AuthException('Social sign-in needs the live backend.');
  }

  @override
  Stream<AppUserModel?> authStateChanges() => const Stream.empty();

  @override
  Future<AccountStanding> accountStatus() async {
    await _fakeLatency();
    final user = _current;
    if (user == null) {
      return const AccountStanding(AccountStandingKind.deleted);
    }
    final email = user.email.toLowerCase();
    if (email.contains('deleted')) {
      return const AccountStanding(AccountStandingKind.deleted);
    }
    final ban = _simulatedBan(email);
    if (ban != null) {
      return AccountStanding(
        ban.type == 'disable'
            ? AccountStandingKind.disabled
            : AccountStandingKind.banned,
        reason: ban.reason,
        until: ban.until,
      );
    }
    return AccountStanding.active;
  }

  @override
  Future<void> deleteAccount() async {
    await _fakeLatency();
    _current = null;
    await _persist(null);
  }

  /// Demo-only: derive a simulated suspension from magic words in the email
  /// ('banned' → sanction, 'disabled' → paused contract).
  ({DateTime until, String reason, String type})? _simulatedBan(String email) {
    final e = email.toLowerCase();
    final disabled = e.contains('disabled');
    final banned = e.contains('banned');
    if (!disabled && !banned) return null;
    return (
      until: DateTime.now().add(const Duration(days: 20)),
      reason: disabled
          ? 'Your host contract is paused (demo simulation).'
          : 'Repeated policy violations (demo simulation).',
      type: disabled ? 'disable' : 'ban',
    );
  }
}
