import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/db_error_messages.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/property.dart';
import '../models/property_model.dart';
import 'local_listings_store.dart';

/// The agency's own listings. When Supabase is connected it reads the real
/// `listings` rows the host owns (so a place published from mobile OR the web
/// appears here and in the seeker feed); otherwise it falls back to the
/// on-device [LocalListingsStore] for the demo.
class HostListingsStore extends ChangeNotifier {
  HostListingsStore(this._local) {
    // Reflect on-device changes in demo mode.
    _local.addListener(notifyListeners);
  }

  final LocalListingsStore _local;
  final List<PropertyModel> _remote = [];

  bool get _isRemote => SupabaseService.isReady;

  /// Published listings, newest first.
  List<Property> get items => _isRemote
      ? List.unmodifiable(_remote)
      : _local.items;

  /// Loads the host's listings from Supabase. Safe to call repeatedly.
  Future<void> load() async {
    if (!_isRemote) {
      notifyListeners();
      return;
    }
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await client
          .from('listings')
          .select()
          .eq('host_id', uid)
          .order('created_at', ascending: false);
      _remote
        ..clear()
        ..addAll(
          (rows as List).map((e) => PropertyModel.fromMap(e as Map<String, dynamic>)),
        );
      notifyListeners();
    } catch (_) {
      // Keep whatever we have; the screen shows a graceful empty state.
    }
  }

  /// Deletes a listing. Returns `null` on success, or a sentence explaining why
  /// it's still there — most often because it has bookings on it, which the
  /// database refuses to orphan.
  Future<String?> remove(String id) async {
    if (_isRemote) {
      try {
        await SupabaseService.client.from('listings').delete().eq('id', id);
        _remote.removeWhere((p) => p.id == id);
        notifyListeners();
        return null;
      } on PostgrestException catch (e) {
        // A foreign-key violation here means reservations still reference it.
        if (e.message.toLowerCase().contains('foreign key')) {
          return 'This listing has bookings on it. Deactivate it instead.';
        }
        return describeDbError(e.message);
      } catch (_) {
        return 'We couldn\'t reach Nesty. Check your connection and try again.';
      }
    }
    await _local.removeById(id);
    return null;
  }

  @override
  void dispose() {
    _local.removeListener(notifyListeners);
    super.dispose();
  }
}
