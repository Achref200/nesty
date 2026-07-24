part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, submitting, blocked }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.mismatchRole,
    this.block,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  final UserRole? mismatchRole;

  /// Set when the account was blocked (banned/disabled/deleted) — drives the
  /// full-screen "account unavailable" surface.
  final AccountStanding? block;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isSubmitting => status == AuthStatus.submitting;
  bool get isBlocked => status == AuthStatus.blocked;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
    UserRole? mismatchRole,
    bool clearMismatch = false,
    AccountStanding? block,
    bool clearBlock = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mismatchRole: clearMismatch ? null : (mismatchRole ?? this.mismatchRole),
      block: clearBlock ? null : (block ?? this.block),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, mismatchRole, block];
}
