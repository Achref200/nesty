import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/local_store.dart';
import '../../../../core/services/supabase_service.dart';
import '../domain/entities/verification.dart';

/// Holds the signed-in member's identity-verification state. Persisted on-device
/// via [LocalStore] so the "get verified" prompt only appears until it's done —
/// exactly like the one-time KYC step on Upwork or a marketplace after sign-up.
///
/// When Supabase is configured the submission is also mirrored to the backend:
/// the ID photos go to the private `verification-docs` bucket and a row lands in
/// `verifications`, where a Nesty Base admin approves or rejects it. The local
/// record is updated only after Supabase accepts that submission, so "under
/// review" always means it is visible in the Nesty Base review queue.
class VerificationStore extends ChangeNotifier {
  Verification _value = const Verification();
  RealtimeChannel? _statusChannel;
  Verification get value => _value;

  VerificationStatus get status => _value.status;
  bool get isVerified => _value.isVerified;
  bool get isPending => _value.isPending;

  /// First-time state: nothing submitted yet.
  bool get needsVerification => _value.needsVerification;

  static const _keyPrefix = 'verification.';
  String _storageKey = '${_keyPrefix}anonymous';

  Future<void> load({String? userId}) async {
    _storageKey = '$_keyPrefix${userId ?? 'anonymous'}';
    final map = LocalStore.instance.getJson(_storageKey);
    _value = map == null ? const Verification() : Verification.fromMap(map);
    notifyListeners();
    await refreshFromBackend();
    _subscribeToStatusChanges();
  }

  /// Pulls the latest status from Supabase so an admin's approve/reject decision
  /// shows up in the app. No-ops when the backend isn't configured.
  Future<void> refreshFromBackend() async {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await client
          .from('verifications')
          .select('status, doc_type, full_name, phone, submitted_at')
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) {
        _value = const Verification();
        await LocalStore.instance.setJson(_storageKey, _value.toMap());
        notifyListeners();
        return;
      }
      final status = VerificationStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => _value.status,
      );
      _value = Verification(
        status: status,
        docType: row['doc_type'] == null
            ? _value.docType
            : IdDocumentType.fromDbValue(row['doc_type'] as String?),
        fullName: (row['full_name'] as String?) ?? _value.fullName,
        phone: (row['phone'] as String?) ?? _value.phone,
        submittedAt: row['submitted_at'] == null
            ? _value.submittedAt
            : DateTime.tryParse(row['submitted_at'] as String),
      );
      await LocalStore.instance.setJson(_storageKey, _value.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Verification backend refresh failed: $e');
    }
  }

  /// Uploads a submission and moves the account to "pending review" only after
  /// the backend accepts it. Demo mode remains local-only when Supabase is off.
  Future<void> submit({
    required IdDocumentType docType,
    required String fullName,
    required String phone,
    Uint8List? frontBytes,
    String? frontFileName,
    Uint8List? backBytes,
    String? backFileName,
    Uint8List? selfieBytes,
    String? selfieFileName,
  }) async {
    final submission = Verification(
      status: VerificationStatus.pending,
      docType: docType,
      fullName: fullName.trim(),
      phone: phone.trim(),
      submittedAt: DateTime.now(),
    );
    await _submitToBackend(
      docType: docType,
      fullName: fullName.trim(),
      phone: phone.trim(),
      frontBytes: frontBytes,
      frontFileName: frontFileName,
      backBytes: backBytes,
      backFileName: backFileName,
      selfieBytes: selfieBytes,
      selfieFileName: selfieFileName,
    );
    _value = submission;
    await LocalStore.instance.setJson(_storageKey, _value.toMap());
    notifyListeners();
  }

  /// Writes through the guarded `submit_verification` database function. Direct
  /// client table writes are deliberately not used: users must never be able to
  /// set their own verification status to verified.
  Future<void> _submitToBackend({
    required IdDocumentType docType,
    required String fullName,
    required String phone,
    Uint8List? frontBytes,
    String? frontFileName,
    Uint8List? backBytes,
    String? backFileName,
    Uint8List? selfieBytes,
    String? selfieFileName,
  }) async {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw const VerificationSubmissionException(
        'Please sign in and try again.',
      );
    }

    try {
      Future<String?> upload(
        Uint8List? bytes,
        String? fileName,
        String name,
      ) async {
        if (bytes == null) return null;
        final rawExtension = fileName?.split('.').last.toLowerCase() ?? 'jpg';
        final ext = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(rawExtension)
            ? rawExtension
            : 'jpg';
        final objectPath = '$uid/$name.$ext';
        await client.storage
            .from('verification-docs')
            .uploadBinary(
              objectPath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        return objectPath;
      }

      final frontUrl = await upload(frontBytes, frontFileName, 'front');
      final backUrl = await upload(backBytes, backFileName, 'back');
      final selfieUrl = await upload(selfieBytes, selfieFileName, 'selfie');

      await client.rpc(
        'submit_verification',
        params: {
          'p_full_name': fullName,
          'p_phone': phone,
          'p_doc_type': docType.dbValue,
          'p_doc_front_path': frontUrl,
          'p_doc_back_path': backUrl,
          'p_selfie_path': selfieUrl,
        },
      );
    } catch (e) {
      debugPrint('Verification submission failed: $e');
      throw const VerificationSubmissionException(
        "Couldn't send your verification. Check your connection and try again.",
      );
    }
  }

  void _subscribeToStatusChanges() {
    if (!SupabaseService.isReady) return;
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    _statusChannel?.unsubscribe();
    _statusChannel = client
        .channel('verification-status-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'verifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => refreshFromBackend(),
        )
        .subscribe();
  }

  Future<void> reset() async {
    _value = const Verification();
    await LocalStore.instance.remove(_storageKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _statusChannel?.unsubscribe();
    super.dispose();
  }
}

class VerificationSubmissionException implements Exception {
  const VerificationSubmissionException(this.message);

  final String message;
}
