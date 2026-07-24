import '../../domain/entities/account_standing.dart';
import '../../domain/entities/user_role.dart';
import '../models/app_user_model.dart';

/// Contract for the remote authentication source. Two implementations exist:
/// [SupabaseAuthRemoteDataSource] and [DemoAuthRemoteDataSource].
abstract interface class AuthRemoteDataSource {
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  });

  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  Future<void> signOut();

  Future<AppUserModel?> currentUser();

  /// Updates the signed-in user's editable profile fields and returns the
  /// refreshed user. Passing null for a field leaves it unchanged.
  Future<AppUserModel> updateProfile({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
  });

  /// Sends a password-reset email with a deep link back into the app.
  Future<void> sendPasswordReset(String email);

  /// Sets a new password for the signed-in (or recovering) user.
  Future<void> updatePassword(String newPassword);

  /// Launches an OAuth flow ('google' | 'apple'). The session arrives via
  /// [authStateChanges] once the provider redirects back.
  Future<bool> signInWithProvider(String provider);

  /// Emits the mapped user whenever the auth session changes (sign in/out,
  /// OAuth completion, token refresh). Null means signed out.
  Stream<AppUserModel?> authStateChanges();

  /// Re-checks with the backend whether this account may still use the app —
  /// catching a ban, a paused contract, or a deletion applied since the token
  /// was issued. Never throws.
  Future<AccountStanding> accountStatus();

  /// Permanently deletes the signed-in account.
  Future<void> deleteAccount();
}
