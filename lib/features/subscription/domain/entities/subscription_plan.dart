import 'package:flutter/widgets.dart';

import '../../../../core/branding/app_icons.dart';

/// How the subscription is billed. Yearly trades a discount for commitment.
enum BillingCycle { monthly, yearly }

extension BillingCycleX on BillingCycle {
  String get id => name;
  String get label => switch (this) {
    BillingCycle.monthly => 'Monthly',
    BillingCycle.yearly => 'Yearly',
  };

  static BillingCycle fromId(String? id) =>
      id == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
}

/// The three Partner tiers. Each unlocks a different monthly listing quota and
/// set of perks. "Customized" is negotiated hand-to-hand with an admin, so its
/// online price/limit are placeholders resolved off-app.
enum SubscriptionPlan { standard, premium, customized }

extension SubscriptionPlanX on SubscriptionPlan {
  String get id => name;

  String get label => switch (this) {
    SubscriptionPlan.standard => 'Standard',
    SubscriptionPlan.premium => 'Premium',
    SubscriptionPlan.customized => 'Customized',
  };

  String get tagline => switch (this) {
    SubscriptionPlan.standard => 'Start turning your network into income.',
    SubscriptionPlan.premium => 'For active partners who list at scale.',
    SubscriptionPlan.customized => 'A plan shaped around your business.',
  };

  IconData get icon => switch (this) {
    SubscriptionPlan.standard => AppIcons.planStandard,
    SubscriptionPlan.premium => AppIcons.planPremium,
    SubscriptionPlan.customized => AppIcons.planCustom,
  };

  /// Listings a partner may keep active in a month. -1 means unlimited /
  /// admin-defined (resolved when the customized plan is set up).
  int get listingLimit => switch (this) {
    SubscriptionPlan.standard => 10,
    SubscriptionPlan.premium => 30,
    SubscriptionPlan.customized => -1,
  };

  /// Price in Tunisian dinars for the given cycle. Customized is quoted, so it
  /// returns null (shown as "Let's talk").
  int? priceFor(BillingCycle cycle) => switch (this) {
    SubscriptionPlan.standard =>
      cycle == BillingCycle.monthly ? 29 : 290,
    SubscriptionPlan.premium =>
      cycle == BillingCycle.monthly ? 59 : 590,
    SubscriptionPlan.customized => null,
  };

  bool get isMostPopular => this == SubscriptionPlan.premium;

  List<String> get perks => switch (this) {
    SubscriptionPlan.standard => const [
      'Up to 10 active listings / month',
      'Requests, calendar & notifications',
      '3D tours on every listing',
      'Your own Partner space',
    ],
    SubscriptionPlan.premium => const [
      'Up to 30 active listings / month',
      'Everything in Standard',
      'Priority placement in search',
      'Performance insights on your listings',
    ],
    SubscriptionPlan.customized => const [
      'Unlimited or tailored listing volume',
      'Everything in Premium',
      'Dedicated onboarding with an admin',
      'Custom privileges & branding',
    ],
  };

  static SubscriptionPlan fromId(String? id) => switch (id) {
    'premium' => SubscriptionPlan.premium,
    'customized' => SubscriptionPlan.customized,
    _ => SubscriptionPlan.standard,
  };
}
