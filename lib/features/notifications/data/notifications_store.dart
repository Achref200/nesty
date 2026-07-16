import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

/// A single notification shown in the activity center.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.read = false,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final bool read;
  final DateTime createdAt;

  AppNotification copyRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    createdAt: createdAt,
    body: body,
    read: true,
  );
}

/// Reactive store for the notification center. Reads the Supabase
/// `notifications` table (fed by reservation triggers) and subscribes to
/// realtime inserts, so an agency confirmation on the web pings the seeker's
/// phone live. No-op in demo mode.
class NotificationsStore extends ChangeNotifier {
  final List<AppNotification> _items = [];
  RealtimeChannel? _channel;

  List<AppNotification> get all => List.unmodifiable(_items);
  int get unread => _items.where((n) => !n.read).length;

  bool get _remote => SupabaseService.isReady;
  SupabaseClient get _client => SupabaseService.client;

  Future<void> load() async {
    if (!_remote) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      _items
        ..clear()
        ..addAll((rows as List).map((e) => _from(e as Map<String, dynamic>)));
      notifyListeners();
      _subscribe(uid);
    } catch (_) {
      // Table not migrated yet or offline — screens show an empty state.
    }
  }

  void _subscribe(String uid) {
    _channel?.unsubscribe();
    _channel = _client.channel('public:notifications:$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (payload) {
          _items.insert(0, _from(payload.newRecord));
          notifyListeners();
        },
      )
      ..subscribe();
  }

  Future<void> markAllRead() async {
    if (_items.every((n) => n.read)) return;
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].read) _items[i] = _items[i].copyRead();
    }
    notifyListeners();
    if (!_remote) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', uid)
          .eq('read', false);
    } catch (_) {}
  }

  AppNotification _from(Map<String, dynamic> m) => AppNotification(
    id: m['id'].toString(),
    type: (m['type'] as String?) ?? '',
    title: (m['title'] as String?) ?? 'Notification',
    body: m['body'] as String?,
    read: (m['read'] as bool?) ?? false,
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
