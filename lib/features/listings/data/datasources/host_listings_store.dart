import 'package:flutter/foundation.dart';

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

  Future<void> remove(String id) async {
    if (_isRemote) {
      try {
        await SupabaseService.client.from('listings').delete().eq('id', id);
        _remote.removeWhere((p) => p.id == id);
        notifyListeners();
      } catch (_) {}
      return;
    }
    await _local.removeById(id);
  }

  @override
  void dispose() {
    _local.removeListener(notifyListeners);
    super.dispose();
  }
}
