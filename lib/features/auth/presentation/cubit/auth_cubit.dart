import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/update_profile.dart';

part 'auth_state.dart';

/// Owns the authentication session for the whole app.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required UpdateProfile updateProfile,
    required AuthRepository repository,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _updateProfile = updateProfile,
       _repository = repository,
       super(const AuthState()) {
    // React to sessions arriving out-of-band: OAuth callbacks, magic links,
    // password recovery and token refresh all flow through here.
    _authSub = _repository.authStateChanges().listen(_onAuthChanged);
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _authSub;

  void _onAuthChanged(AppUser? user) {
    if (user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else if (state.status == AuthStatus.authenticated) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  /// Called once at startup to restore any existing session.
  Future<void> checkSession() async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (_) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (user) => emit(
        user == null
            ? state.copyWith(status: AuthStatus.unauthenticated)
            : state.copyWith(status: AuthStatus.authenticated, user: user),
      ),
    );
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    final result = await _signIn(
      SignInParams(email: email.trim(), password: password),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (user) =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> signUp(
    String fullName,
    String email,
    String password,
    UserRole role,
  ) async {
    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    final result = await _signUp(
      SignUpParams(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        role: role,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (user) =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> signOut() async {
    await _signOut(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Switches the active role, adapting the whole experience between browsing
  /// (seeker) and hosting. Persisted so it survives a restart.
  Future<void> switchRole(UserRole role) async {
    if (state.user?.role == role) return;
    final result = await _updateProfile(UpdateProfileParams(role: role));
    result.fold(
      (_) {},
      (user) => emit(state.copyWith(user: user)),
    );
  }

  /// Updates the display name on the profile.
  Future<void> updateName(String fullName) async {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty || trimmed == state.user?.fullName) return;
    final result = await _updateProfile(
      UpdateProfileParams(fullName: trimmed),
    );
    result.fold(
      (_) {},
      (user) => emit(state.copyWith(user: user)),
    );
  }

  /// Updates the profile avatar (an uploaded image URL). Returns an error, or
  /// null on success.
  Future<String?> updateAvatar(String url) async {
    final result = await _updateProfile(UpdateProfileParams(avatarUrl: url));
    return result.fold((f) => f.message, (user) {
      emit(state.copyWith(user: user));
      return null;
    });
  }

  /// Sends a password-reset email. Returns an error message, or null on success.
  Future<String?> sendPasswordReset(String email) async {
    final result = await _repository.sendPasswordReset(email.trim());
    return result.fold((f) => f.message, (_) => null);
  }

  /// Sets a new password for the signed-in user. Returns an error, or null.
  Future<String?> updatePassword(String newPassword) async {
    final result = await _repository.updatePassword(newPassword);
    return result.fold((f) => f.message, (_) => null);
  }

  /// Launches OAuth ('google' | 'apple'). Returns an error message, or null if
  /// the flow launched — the session then arrives via the auth-state stream.
  Future<String?> signInWithProvider(String provider) async {
    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    final result = await _repository.signInWithProvider(provider);
    return result.fold((f) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return f.message;
    }, (_) => null);
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
