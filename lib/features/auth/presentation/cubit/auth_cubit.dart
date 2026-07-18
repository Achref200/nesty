import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/local_store.dart';
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

  /// The role the space an OAuth sign-in was launched from expects. Set right
  /// before launching the provider so the session that arrives asynchronously
  /// can be validated against the door it came through. Null for the universal
  /// "Sign in" entry, which accepts any role.
  UserRole? _pendingProviderRole;

  /// Persists a client-side role upgrade the server can't store yet (e.g. a
  /// seeker who paid to become a Partner before the backend migration lands).
  /// Scoped to the user id so it never leaks across accounts, and cleared on
  /// sign-out. Once the server can hold the role, its value simply matches.
  static const _overrideKey = 'auth.role_override';

  /// Applies any pending local role override to [user] so the whole app sees
  /// the upgraded role even when the backend returned the old one.
  AppUser? _applyOverride(AppUser? user) {
    if (user == null) return null;
    final o = LocalStore.instance.getJson(_overrideKey);
    if (o == null || o['uid'] != user.id) return user;
    final role = UserRoleX.fromId(o['role'] as String?);
    return role == user.role ? user : user.copyWith(role: role);
  }

  void _setRoleOverride(String uid, UserRole role) =>
      LocalStore.instance.setJson(_overrideKey, {'uid': uid, 'role': role.id});

  Future<void> _clearRoleOverride() =>
      LocalStore.instance.remove(_overrideKey);

  void _onAuthChanged(AppUser? user) {
    final resolved = _applyOverride(user);
    if (resolved == null) {
      if (state.status == AuthStatus.authenticated) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
      return;
    }

    // Enforce role scoping for OAuth: a session that arrives out-of-band must
    // match the space it was launched from. Only applies to a fresh sign-in
    // (not a token refresh on an already-authenticated session).
    final expected = _pendingProviderRole;
    if (expected != null && state.status != AuthStatus.authenticated) {
      _pendingProviderRole = null;
      if (resolved.role != expected) {
        // Seeker landing in the Partner space is the paid upgrade path — the
        // paywall already ran, so grant Partner instead of rejecting.
        if (expected == UserRole.partner &&
            resolved.role == UserRole.seeker) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: resolved,
            clearMismatch: true,
          ));
          switchRole(UserRole.partner);
          return;
        }
        // Wrong door — don't authenticate. Sign the session back out and tell
        // the UI which space this account really belongs to.
        _signOut(const NoParams());
        emit(AuthState(
          status: AuthStatus.unauthenticated,
          mismatchRole: resolved.role,
        ));
        return;
      }
    }

    emit(state.copyWith(
      status: AuthStatus.authenticated,
      user: resolved,
      clearMismatch: true,
    ));
  }

  /// Clears a pending OAuth role-mismatch flag once the UI has shown it.
  void clearMismatch() {
    if (state.mismatchRole != null) {
      emit(state.copyWith(clearMismatch: true));
    }
  }

  /// Called once at startup to restore any existing session.
  Future<void> checkSession() async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (_) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (user) {
        final resolved = _applyOverride(user);
        emit(
          resolved == null
              ? state.copyWith(status: AuthStatus.unauthenticated)
              : state.copyWith(
                  status: AuthStatus.authenticated, user: resolved),
        );
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    await signInScoped(email, password);
  }

  /// Signs in and, when [expectedRole] is given, enforces that the account is
  /// actually that role — you can't enter the Partner space with a seeker login
  /// or vice-versa. On a mismatch the session is signed back out and the result
  /// reports which role the account really is so the UI can redirect.
  Future<AuthAttempt> signInScoped(
    String email,
    String password, {
    UserRole? expectedRole,
  }) async {
    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    final result = await _signIn(
      SignInParams(email: email.trim(), password: password),
    );
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          ),
        );
        return AuthAttempt(error: failure.message);
      },
      (user) {
        final resolved = _applyOverride(user) ?? user;
        if (expectedRole != null && resolved.role != expectedRole) {
          // Wrong door — don't authenticate here. Sign the fresh session out
          // and tell the UI where this account belongs.
          _signOut(const NoParams());
          emit(const AuthState(status: AuthStatus.unauthenticated));
          return AuthAttempt(roleMismatch: true, actualRole: resolved.role);
        }
        emit(
          state.copyWith(status: AuthStatus.authenticated, user: resolved),
        );
        return const AuthAttempt();
      },
    );
  }

  Future<void> signUp(
    String fullName,
    String email,
    String password,
    UserRole role,
  ) async {
    emit(state.copyWith(status: AuthStatus.submitting, clearError: true));
    // Partner is a paid, self-serve upgrade. Create the base account as a
    // seeker first — so the backend never has to accept a role it may not
    // support yet — then apply the Partner role (which falls back to a local
    // override when the server can't store it).
    final wantsPartner = role == UserRole.partner;
    final signUpRole = wantsPartner ? UserRole.seeker : role;
    final result = await _signUp(
      SignUpParams(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        role: signUpRole,
      ),
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (user) async {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: _applyOverride(user),
          ),
        );
        if (wantsPartner) await switchRole(UserRole.partner);
      },
    );
  }

  Future<void> signOut() async {
    _pendingProviderRole = null;
    await _signOut(const NoParams());
    await _clearRoleOverride();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Switches the active role, adapting the whole experience between browsing
  /// (seeker) and hosting. Persisted so it survives a restart. Returns an error
  /// message, or null on success.
  Future<String?> switchRole(UserRole role) async {
    if (state.user?.role == role) return null;
    final result = await _updateProfile(UpdateProfileParams(role: role));
    return result.fold(
      (failure) => failure.message,
      (user) {
        if (user.role == role) {
          // Server accepted it — it's the source of truth now.
          _clearRoleOverride();
          emit(state.copyWith(user: user));
        } else {
          // The backend can't store this role yet (feature not provisioned).
          // Keep a local override so the app is fully usable now; the server
          // takes over automatically once the migration is applied.
          _setRoleOverride(user.id, role);
          emit(state.copyWith(user: user.copyWith(role: role)));
        }
        return null;
      },
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
  /// the flow launched — the session then arrives via the auth-state stream,
  /// where it's validated against [expectedRole] (null = the universal entry
  /// that accepts any role).
  Future<String?> signInWithProvider(
    String provider, {
    UserRole? expectedRole,
  }) async {
    _pendingProviderRole = expectedRole;
    emit(state.copyWith(
      status: AuthStatus.submitting,
      clearError: true,
      clearMismatch: true,
    ));
    final result = await _repository.signInWithProvider(provider);
    return result.fold((f) {
      _pendingProviderRole = null;
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

/// Outcome of a scoped sign-in. Exactly one of these holds:
/// * success (both false / null),
/// * [error] set for bad credentials / network, or
/// * [roleMismatch] true with [actualRole] for a wrong-space login.
class AuthAttempt {
  const AuthAttempt({
    this.error,
    this.roleMismatch = false,
    this.actualRole,
  });

  final String? error;
  final bool roleMismatch;
  final UserRole? actualRole;

  bool get ok => error == null && !roleMismatch;
}
