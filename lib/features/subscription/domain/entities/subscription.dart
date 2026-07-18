import 'subscription_plan.dart';

/// A Partner's active subscription. Persisted to Supabase (`subscriptions`
/// table) when a backend is configured, or on-device in demo mode.
class Subscription {
  const Subscription({
    required this.plan,
    required this.billing,
    required this.status,
    required this.listingLimit,
    this.currentPeriodEnd,
  });

  final SubscriptionPlan plan;
  final BillingCycle billing;
  final String status; // active | cancelled | past_due
  final int listingLimit; // -1 = unlimited / admin-defined
  final DateTime? currentPeriodEnd;

  bool get isActive => status == 'active';
  bool get isUnlimited => listingLimit < 0;

  /// True only when the plan is active *and* still within its paid period.
  /// This is what gates the Partner role — once it lapses the account reverts
  /// to a simple seeker.
  bool get isCurrentlyActive =>
      status == 'active' &&
      (currentPeriodEnd == null || currentPeriodEnd!.isAfter(DateTime.now()));

  bool get isExpired =>
      currentPeriodEnd != null && !currentPeriodEnd!.isAfter(DateTime.now());

  /// Builds a subscription for a freshly chosen plan, dating the period from
  /// now to a month or a year out.
  factory Subscription.fresh(SubscriptionPlan plan, BillingCycle billing) {
    final now = DateTime.now();
    return Subscription(
      plan: plan,
      billing: billing,
      status: 'active',
      listingLimit: plan.listingLimit,
      currentPeriodEnd: billing == BillingCycle.yearly
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day),
    );
  }

  Map<String, dynamic> toMap() => {
    'plan': plan.id,
    'billing': billing.id,
    'status': status,
    'listing_limit': listingLimit,
    'current_period_end': currentPeriodEnd?.toIso8601String(),
  };

  factory Subscription.fromMap(Map<String, dynamic> map) {
    final plan = SubscriptionPlanX.fromId(map['plan'] as String?);
    return Subscription(
      plan: plan,
      billing: BillingCycleX.fromId(map['billing'] as String?),
      status: (map['status'] as String?) ?? 'active',
      listingLimit: (map['listing_limit'] as num?)?.toInt() ?? plan.listingLimit,
      currentPeriodEnd: switch (map['current_period_end']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      },
    );
  }
}
