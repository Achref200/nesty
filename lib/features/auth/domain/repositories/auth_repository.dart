import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/account_standing.dart';
import '../entities/app_user.dart';
import '../entities/user_role.dart';

/// Contract for authentication. Implemented in the data layer against either
/// Supabase or a local demo source.
abstract interface class AuthRepository {
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  Future<Either<Failure, Unit>> signOut();

  /// Returns the currently signed-in user, or null when signed out.
  Future<Either<Failure, AppUser?>> currentUser();

  /// Updates editable profile fields for the signed-in user.
  Future<Either<Failure, AppUser>> updateProfile({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
  });

  /// Sends a password-reset email.
  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  /// Sets a new password for the signed-in user.
  Future<Either<Failure, Unit>> updatePassword(String newPassword);

  /// Launches OAuth ('google' | 'apple').
  Future<Either<Failure, Unit>> signInWithProvider(String provider);

  /// Stream of the user across session changes (null = signed out).
  Stream<AppUser?> authStateChanges();

  /// Re-checks account standing with the backend. Returns
  /// [AccountStanding.unknown] when the check itself fails (never blocks on
  /// an error).
  Future<AccountStanding> accountStatus();

  /// Permanently deletes the signed-in account.
  Future<Either<Failure, Unit>> deleteAccount();
}
