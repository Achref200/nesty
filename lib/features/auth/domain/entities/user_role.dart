/// The kind of account. Chosen up-front and fixed — a home seeker (B2C) and a
/// real-estate agency are genuinely different users with different apps, not a
/// toggle on one profile.
enum UserRole { seeker, host }

extension UserRoleX on UserRole {
  String get id => name;

  String get title => switch (this) {
    UserRole.seeker => 'I\'m looking for a place',
    UserRole.host => 'I\'m a real-estate agency',
  };

  String get subtitle => switch (this) {
    UserRole.seeker =>
      'Browse homes, tour them in 3D and book a visit or reserve your dates.',
    UserRole.host =>
      'List your properties, and track visits, reservations and requests.',
  };

  String get shortLabel => switch (this) {
    UserRole.seeker => 'Seeker',
    UserRole.host => 'Agency',
  };

  static UserRole fromId(String? id) => switch (id) {
    'host' => UserRole.host,
    _ => UserRole.seeker,
  };
}
