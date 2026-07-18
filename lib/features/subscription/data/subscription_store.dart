import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/local_store.dart';
import '../../../../core/services/supabase_service.dart';
import '../domain/entities/subscription.dart';
import '../domain/entities/subscription_plan.dart';

/// Owns the signed-in Partner's subscription. Backed by Supabase when
/// configured (the `subscriptions` table), or on-device via [LocalStore] in
/// demo mode — mirroring how the rest of the app degrades gracefully.
///
/// It also carries a *pending* plan across the onboarding paywall: an
/// unauthenticated seeker picks a plan, creates a Partner account, and the
/// pending choice is committed the moment the session lands.
class SubscriptionStore extends ChangeNotifier {
  static const _key = 'subscription';

  Subscription? _current;
  Subscription? get current => _current;

  bool _loading = false;
  bool get loading => _loading;

  /// A plan chosen at the paywall before the account exists yet.
  SubscriptionPlan? _pendingPlan;
  BillingCycle? _pendingBilling;

  bool get hasActive => _current?.isActive == true;

  /// True when the current subscription still entitles the user to the Partner
  /// role (active and within its paid period). When false, a Partner should be
  /// reverted to a simple seeker.
  bool get isActivePartner => _current?.isCurrentlyActive == true;

  /// The active listing quota, or null when there is no active plan.
  int? get listingLimit => hasActive ? _current!.listingLimit : null;

  void setPending(SubscriptionPlan plan, BillingCycle billing) {
    _pendingPlan = plan;
    _pendingBilling = billing;
  }

  void clearPending() {
    _pendingPlan = null;
    _pendingBilling = null;
  }

  /// Loads the current subscription, then commits any plan chosen at the
  /// paywall before sign-up. Safe to call on every app launch.
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _current = await _read();
    } catch (_) {
      _current = null;
    }
    // Commit a plan chosen before the account existed.
    if (_current == null && _pendingPlan != null) {
      await subscribe(_pendingPlan!, _pendingBilling ?? BillingCycle.monthly);
    }
    clearPending();
    _loading = false;
    notifyListeners();
  }

  Future<Subscription?> _read() async {
    if (SupabaseService.isReady) {
      final client = SupabaseService.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return null;
      try {
        final row = await client
            .from('subscriptions')
            .select()
            .eq('user_id', uid)
            .maybeSingle();
        return row == null ? null : Subscription.fromMap(row);
      } on PostgrestException catch (e) {
        if (!_isSetupIssue(e)) rethrow;
        // The subscriptions table isn't provisioned yet — read the on-device
        // fallback so an already-subscribed Partner keeps their plan.
        return _readLocal();
      }
    }
    return _readLocal();
  }

  Subscription? _readLocal() {
    final saved = LocalStore.instance.getJson(_key);
    return saved == null ? null : Subscription.fromMap(saved);
  }

  /// Starts (or changes) the subscription for [plan] on the [billing] cycle.
  /// Returns an error message, or null on success.
  Future<String?> subscribe(SubscriptionPlan plan, BillingCycle billing) async {
    final sub = Subscription.fresh(plan, billing);
    try {
      if (SupabaseService.isReady) {
        final client = SupabaseService.client;
        final uid = client.auth.currentUser?.id;
        if (uid == null) return 'Please sign in to subscribe.';
        try {
          await client.from('subscriptions').upsert({
            'user_id': uid,
            ...sub.toMap(),
            'price': plan.priceFor(billing),
          });
        } on PostgrestException catch (e) {
          if (!_isSetupIssue(e)) return e.message;
          // The Partner feature isn't provisioned on the server yet — keep the
          // plan on-device so the app stays fully usable. Once the migration
          // is applied, the server becomes the source of truth automatically.
          await LocalStore.instance.setJson(_key, sub.toMap());
        }
      } else {
        await LocalStore.instance.setJson(_key, sub.toMap());
      }
      _current = sub;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Couldn\'t start your subscription. Check your connection and '
          'try again.';
    }
  }

  /// Cancels the active subscription (keeps the row for history).
  Future<String?> cancel() async {
    final sub = _current;
    if (sub == null) return null;
    final cancelled = Subscription(
      plan: sub.plan,
      billing: sub.billing,
      status: 'cancelled',
      listingLimit: sub.listingLimit,
      currentPeriodEnd: sub.currentPeriodEnd,
    );
    try {
      if (SupabaseService.isReady) {
        final client = SupabaseService.client;
        final uid = client.auth.currentUser?.id;
        if (uid == null) return 'Please sign in.';
        try {
          await client
              .from('subscriptions')
              .update({'status': 'cancelled'}).eq('user_id', uid);
        } on PostgrestException catch (e) {
          if (!_isSetupIssue(e)) return e.message;
          await LocalStore.instance.setJson(_key, cancelled.toMap());
        }
      } else {
        await LocalStore.instance.setJson(_key, cancelled.toMap());
      }
      _current = cancelled;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Couldn\'t cancel right now. Please try again.';
    }
  }

  /// Whether a Postgrest error means the Partner feature simply isn't
  /// provisioned on the server yet (missing table/column or a role/plan check
  /// constraint from before the `20260717120000_partner_role.sql` migration).
  /// In that case we fall back to on-device storage rather than failing.
  bool _isSetupIssue(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == 'PGRST205' ||
        e.code == '42P01' || // undefined_table
        e.code == '42703' || // undefined_column
        e.code == '23514' || // check_violation (profiles role / plan)
        msg.contains('schema cache') ||
        msg.contains('could not find the table') ||
        msg.contains('does not exist');
  }
}
