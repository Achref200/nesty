/// The result of re-checking, against the backend, whether a signed-in account
/// is still allowed to use the app. Evaluated on every launch and on resume so
/// a ban, a paused contract or a deletion takes effect without waiting for the
/// access token to expire.
enum AccountStandingKind {
  /// The account is in good standing — carry on.
  active,

  /// A sanction (a seeker/partner violation). Violation-tone messaging.
  banned,

  /// A paused contract (a host/agency). Neutral-tone messaging.
  disabled,

  /// The account no longer exists on the backend.
  deleted,

  /// The check couldn't reach the backend — never block on this.
  unknown,
}

class AccountStanding {
  const AccountStanding(this.kind, {this.reason, this.until});

  final AccountStandingKind kind;

  /// The human-readable reason for a suspension, when the console provided one.
  final String? reason;

  /// When a temporary suspension lifts, when known.
  final DateTime? until;

  static const active = AccountStanding(AccountStandingKind.active);
  static const unknown = AccountStanding(AccountStandingKind.unknown);

  /// True when the account may keep using the app (active, or an inconclusive
  /// check we won't punish the user for).
  bool get isUsable =>
      kind == AccountStandingKind.active || kind == AccountStandingKind.unknown;

  bool get isBlocked => !isUsable;
}
