import 'supabase_service.dart';

/// Records lightweight, fire-and-forget engagement events (views, saves, tour
/// opens) into Supabase so the agency dashboard can see what's attracting
/// interest. No-op in demo mode; failures are swallowed — analytics must never
/// interrupt the experience.
abstract final class Analytics {
  static const _table = 'listing_events';

  static Future<void> log(String listingId, String type) async {
    if (!SupabaseService.isReady || listingId.isEmpty) return;
    try {
      final client = SupabaseService.client;
      final uid = client.auth.currentUser?.id;
      await client.from(_table).insert({
        'listing_id': listingId,
        'type': type,
        'user_id': ?uid,
      });
    } catch (_) {
      // Best-effort only.
    }
  }

  static void view(String listingId) => log(listingId, 'view');
  static void save(String listingId) => log(listingId, 'save');
  static void tour(String listingId) => log(listingId, 'tour');
  static void reservation(String listingId) => log(listingId, 'reservation');
}
