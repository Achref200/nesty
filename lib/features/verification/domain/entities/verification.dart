// Identity-verification domain: the status a member's account is in, and the
// kind of ID document they submitted. Kept tiny and serialisable so it can be
// persisted locally (and later synced to the backend).

enum VerificationStatus { none, pending, verified, rejected }

enum IdDocumentType {
  nationalId,
  passport,
  driverLicense;

  String get label => switch (this) {
    IdDocumentType.nationalId => 'National ID (CIN)',
    IdDocumentType.passport => 'Passport',
    IdDocumentType.driverLicense => "Driver's licence",
  };

  String get blurb => switch (this) {
    IdDocumentType.nationalId => 'Your Tunisian CIN — front and back.',
    IdDocumentType.passport => 'The photo page of your passport.',
    IdDocumentType.driverLicense => 'Your licence — front and back.',
  };

  /// Whether the document has two sides to capture (front + back).
  bool get twoSided => this != IdDocumentType.passport;

  /// Snake-case value stored in the Supabase `verifications.doc_type` column.
  String get dbValue => switch (this) {
    IdDocumentType.nationalId => 'national_id',
    IdDocumentType.passport => 'passport',
    IdDocumentType.driverLicense => 'driver_license',
  };

  static IdDocumentType fromId(String? v) => IdDocumentType.values.firstWhere(
    (e) => e.name == v,
    orElse: () => IdDocumentType.nationalId,
  );
}

class Verification {
  const Verification({
    this.status = VerificationStatus.none,
    this.docType,
    this.fullName,
    this.phone,
    this.submittedAt,
  });

  final VerificationStatus status;
  final IdDocumentType? docType;
  final String? fullName;
  final String? phone;
  final DateTime? submittedAt;

  bool get isVerified => status == VerificationStatus.verified;
  bool get isPending => status == VerificationStatus.pending;
  bool get isRejected => status == VerificationStatus.rejected;

  /// True only before anything has ever been submitted — the first-time state.
  bool get needsVerification => status == VerificationStatus.none;

  Map<String, dynamic> toMap() => {
    'status': status.name,
    if (docType != null) 'docType': docType!.name,
    if (fullName != null) 'fullName': fullName,
    if (phone != null) 'phone': phone,
    if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
  };

  factory Verification.fromMap(Map<String, dynamic> m) => Verification(
    status: VerificationStatus.values.firstWhere(
      (e) => e.name == m['status'],
      orElse: () => VerificationStatus.none,
    ),
    docType: m['docType'] == null
        ? null
        : IdDocumentType.fromId(m['docType'] as String?),
    fullName: m['fullName'] as String?,
    phone: m['phone'] as String?,
    submittedAt: m['submittedAt'] == null
        ? null
        : DateTime.tryParse(m['submittedAt'] as String),
  );
}
