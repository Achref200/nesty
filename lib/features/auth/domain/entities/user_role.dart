/// The kind of account. Chosen up-front — a home seeker (B2C), a real-estate
/// agency (B2B, provisioned by Nesty) and a Partner (an independent individual
/// with an owner network — the modern take on the Tunisian "samsar") are
/// genuinely different users with different tabs and privileges.
///
/// Seeker and Agency are the two founding sides. Partner is a paid, self-serve
/// role a seeker can upgrade into behind a subscription paywall.
enum UserRole { seeker, host, partner }

extension UserRoleX on UserRole {
  String get id => name;

  String get title => switch (this) {
    UserRole.seeker => 'I\'m looking for a place',
    UserRole.host => 'I\'m a real-estate agency',
    UserRole.partner => 'I connect people to homes',
  };

  String get subtitle => switch (this) {
    UserRole.seeker =>
      'Browse homes, tour them in 3D and book a visit or reserve your dates.',
    UserRole.host =>
      'List your properties, and track visits, reservations and requests.',
    UserRole.partner =>
      'Turn your network into income — list homes, manage requests and grow '
          'your own space. Subscription required.',
  };

  String get shortLabel => switch (this) {
    UserRole.seeker => 'Seeker',
    UserRole.host => 'Agency',
    UserRole.partner => 'Partner',
  };

  /// Whether this role publishes and manages listings (agency or partner).
  bool get canHost => this == UserRole.host || this == UserRole.partner;

  static UserRole fromId(String? id) => switch (id) {
    'host' => UserRole.host,
    'partner' => UserRole.partner,
    _ => UserRole.seeker,
  };
}
