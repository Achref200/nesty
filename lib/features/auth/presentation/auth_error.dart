/// Buckets a raw auth error message from the backend into an actionable kind so
/// the sign-in / sign-up surface can respond with the right guidance instead of
/// a raw provider string.
enum AuthErrorKind {
  /// Tried to create an account that already exists.
  alreadyRegistered,

  /// Tried to sign in to an account that doesn't exist.
  noAccount,

  /// The email exists but the password was wrong.
  wrongPassword,

  /// The account is suspended.
  banned,

  /// The email hasn't been confirmed yet.
  emailNotConfirmed,

  /// Too many attempts — rate limited.
  rateLimited,

  /// Couldn't reach the backend.
  network,

  /// Anything else.
  unknown,
}

/// Classifies a provider error message (GoTrue/Supabase) into an [AuthErrorKind].
AuthErrorKind classifyAuthError(String? message) {
  final m = (message ?? '').toLowerCase();
  if (m.isEmpty) return AuthErrorKind.unknown;

  if (m.contains('already registered') ||
      m.contains('already been registered') ||
      m.contains('user already exists') ||
      m.contains('email address is already') ||
      m.contains('duplicate')) {
    return AuthErrorKind.alreadyRegistered;
  }
  if (m.contains('banned') ||
      m.contains('suspended') ||
      m.contains('user_banned')) {
    return AuthErrorKind.banned;
  }
  if (m.contains('email not confirmed') ||
      m.contains('not confirmed') ||
      m.contains('confirm your email')) {
    return AuthErrorKind.emailNotConfirmed;
  }
  if (m.contains('rate limit') ||
      m.contains('too many') ||
      m.contains('try again later')) {
    return AuthErrorKind.rateLimited;
  }
  if (m.contains('invalid login') ||
      m.contains('invalid credentials') ||
      m.contains('invalid email or password')) {
    // GoTrue returns one obfuscated message for both a missing account and a
    // wrong password. Surface it as "no account" so we can invite sign-up,
    // which is the more common and more helpful branch to guide toward.
    return AuthErrorKind.noAccount;
  }
  if (m.contains('password')) return AuthErrorKind.wrongPassword;
  if (m.contains('network') ||
      m.contains('socket') ||
      m.contains('timeout') ||
      m.contains('failed host lookup') ||
      m.contains('connection')) {
    return AuthErrorKind.network;
  }
  return AuthErrorKind.unknown;
}
