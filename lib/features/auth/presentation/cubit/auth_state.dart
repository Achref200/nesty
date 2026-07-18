part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, submitting }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.mismatchRole,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;


  final UserRole? mismatchRole;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isSubmitting => status == AuthStatus.submitting;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
    UserRole? mismatchRole,
    bool clearMismatch = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mismatchRole: clearMismatch ? null : (mismatchRole ?? this.mismatchRole),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, mismatchRole];
}
