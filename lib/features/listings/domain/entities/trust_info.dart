import 'property.dart';

/// How thoroughly a listing has been checked. Drives the badge shown to seekers.
enum TrustLevel { basic, verified, premium }

extension TrustLevelX on TrustLevel {
  String get label => switch (this) {
    TrustLevel.premium => 'Premium verified',
    TrustLevel.verified => 'Verified',
    TrustLevel.basic => 'Basic listing',
  };

  String get shortLabel => switch (this) {
    TrustLevel.premium => 'Premium',
    TrustLevel.verified => 'Verified',
    TrustLevel.basic => 'Basic',
  };
}

/// A computed trust profile for a listing.
///
/// One of the biggest concerns in the Tunisian market is whether a listing is
/// authentic. Rather than requiring new backend fields, [TrustInfo.of] derives a
/// transparent trust score from signals already present on a [Property] —
/// verification proxies, listing completeness, tour quality and user feedback —
/// so the feature works on both demo and live data and can be upgraded to
/// owner-submitted proofs later without changing the UI.
class TrustInfo {
  const TrustInfo({
    required this.score,
    required this.level,
    required this.identityVerified,
    required this.ownershipVerified,
    required this.locationVerified,
    required this.wellReviewed,
  });

  /// 0–100 overall trust score.
  final int score;
  final TrustLevel level;

  final bool identityVerified;
  final bool ownershipVerified;
  final bool locationVerified;
  final bool wellReviewed;

  bool get isVerified => level != TrustLevel.basic;

  factory TrustInfo.of(Property p) {
    final identityVerified = p.isSuperhost;
    final ownershipVerified = p.isSuperhost || p.reviewCount >= 50;
    final locationVerified = p.address.trim().isNotEmpty;
    final wellReviewed = p.reviewCount >= 30 && p.rating >= 4.5;

    var score = 0;
    if (identityVerified) score += 24;
    if (ownershipVerified) score += 22;
    if (locationVerified) score += 16;
    if (wellReviewed) score += 22;
    if (p.gallery.length >= 3) score += 10;
    if (p.gallery.length >= 6) score += 8;
    if (p.amenities.length >= 4) score += 10;
    score = score.clamp(0, 100);

    final level = score >= 80
        ? TrustLevel.premium
        : score >= 55
        ? TrustLevel.verified
        : TrustLevel.basic;

    return TrustInfo(
      score: score,
      level: level,
      identityVerified: identityVerified,
      ownershipVerified: ownershipVerified,
      locationVerified: locationVerified,
      wellReviewed: wellReviewed,
    );
  }
}
