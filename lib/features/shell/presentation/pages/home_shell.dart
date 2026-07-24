import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/push_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assistant/presentation/widgets/assistant_launcher.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../listings/data/datasources/host_listings_store.dart';
import '../../../listings/presentation/cubit/listing_filter.dart';
import '../../../listings/presentation/cubit/listings_cubit.dart';
import '../../../listings/presentation/pages/create_listing_page.dart';
import '../../../listings/presentation/pages/home_page.dart';
import '../../../listings/presentation/pages/host_dashboard_page.dart';
import '../../../listings/presentation/pages/my_listings_page.dart';
import '../../../../core/widgets/ios/liquid_glass.dart';
import '../../../notifications/data/notifications_store.dart';
import '../../../onboarding/data/profile_setup_store.dart';
import '../../../onboarding/presentation/pages/profile_setup_flow_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../partner/presentation/pages/partner_home_page.dart';
import '../../../reservations/data/reservations_store.dart';
import '../../../reservations/presentation/pages/host_calendar_page.dart';
import '../../../reservations/presentation/pages/my_trips_page.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../../../subscription/data/subscription_store.dart';
import '../../../subscription/presentation/partner_gate.dart';
import '../../../verification/data/verification_store.dart';

/// Root shell with a floating "Liquid Glass" tab bar that hovers above the
/// content. The selected tab expands into a solid brand lozenge. The tab set is
/// role-aware: seekers browse & save homes, while hosts get a dashboard, their
/// listings and a floating action to publish a new place.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Owned here (rather than created inline by the provider) so discovery can
  /// be seeded with the member's onboarding preferences once they're loaded.
  late final ListingsCubit _listings = sl<ListingsCubit>();

  @override
  void initState() {
    super.initState();
    // Load the discovery feed straight away for a prompt first paint.
    _listings.load();
    // Pull the signed-in user's reservations (guest or host) from the backend.
    sl<ReservationsStore>().load();
    // Load & live-subscribe to the notification center.
    sl<NotificationsStore>().load();
    // Ask for the OS notification permission now the member is inside the app.
    PushService.requestPermission();
    // Load the one-time identity-verification state.
    sl<VerificationStore>().load();
    // Load the Partner subscription, then enforce the rule that a Partner must
    // hold an active plan — otherwise they revert to a simple seeker.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  @override
  void dispose() {
    _listings.close();
    super.dispose();
  }

  Future<void> _onFirstFrame() async {
    await _syncPartnerAccess();
    await _maybePromptProfileSetup();
    await _applyDiscoveryPreferences();
  }

  /// Shows the light "tell us about you" questions once, on a member's first
  /// run. Agencies are provisioned by Nesty, so they're never asked.
  Future<void> _maybePromptProfileSetup() async {
    if (!mounted) return;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.seeker;
    if (role == UserRole.host) return;
    await sl<ProfileSetupStore>().load();
    if (!mounted || !sl<ProfileSetupStore>().shouldPrompt) return;
    await startProfileSetupFlow(context);
  }

  /// Seeds the seeker's feed with filters derived from their onboarding answers
  /// — budget, destination, rental term and household — so discovery opens
  /// already tuned to them. Colocation seekers also land on the shared-room
  /// category. They can still change or clear everything from the search bar.
  Future<void> _applyDiscoveryPreferences() async {
    if (!mounted) return;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.seeker;
    if (role != UserRole.seeker) return;
    final prefs = sl<ProfileSetupStore>().value;
    final filter = ListingFilter.fromPreferences(
      region: prefs.regions.isNotEmpty ? prefs.regions.first : null,
      budgetId: prefs.budget,
      purposeId: prefs.purpose,
      householdId: prefs.household,
    );
    final wantsColocation = prefs.purpose == 'colocation';
    if (!filter.isActive && !wantsColocation) return;
    if (filter.isActive) await _listings.applyFilter(filter);
    if (wantsColocation) await _listings.selectCategory('sharedRoom');
  }

  Future<void> _syncPartnerAccess() async {
    await sl<SubscriptionStore>().load();
    if (!mounted) return;
    final auth = context.read<AuthCubit>();
    if (auth.state.user?.role == UserRole.partner &&
        !sl<SubscriptionStore>().isActivePartner) {
      // Subscription cancelled or lapsed — the only ways back to a seeker.
      await auth.switchRole(UserRole.seeker);
    }
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthCubit, UserRole>(
      (c) => c.state.user?.role ?? UserRole.seeker,
    );
    final isHost = role == UserRole.host;
    final isPartner = role == UserRole.partner;

    // Role-specific tab sets. Seekers browse; agencies get a full dashboard;
    // partners get a lighter overview but the same publish/manage powers.
    final List<Widget> pages;
    final List<_TabItem> tabs;
    if (isHost) {
      pages = const [
        HostDashboardPage(),
        HostCalendarPage(),
        MyListingsPage(),
        ProfilePage(),
      ];
      tabs = [
        _TabItem(AppIcons.dashboard, AppIcons.dashboard,
            context.copy('Dashboard', 'Tableau')),
        _TabItem(AppIcons.calendar, AppIcons.calendar,
            context.copy('Calendar', 'Agenda')),
        _TabItem(AppIcons.listings, AppIcons.listings,
            context.copy('Listings', 'Annonces')),
        _TabItem(AppIcons.profile, AppIcons.profile,
            context.copy('Profile', 'Profil')),
      ];
    } else if (isPartner) {
      pages = const [
        PartnerHomePage(),
        MyListingsPage(),
        HostCalendarPage(),
        ProfilePage(),
      ];
      tabs = [
        _TabItem(AppIcons.partner, AppIcons.partner,
            context.copy('Space', 'Espace')),
        _TabItem(AppIcons.listings, AppIcons.listings,
            context.copy('Listings', 'Annonces')),
        _TabItem(AppIcons.calendar, AppIcons.calendar,
            context.copy('Calendar', 'Agenda')),
        _TabItem(AppIcons.profile, AppIcons.profile,
            context.copy('Profile', 'Profil')),
      ];
    } else {
      pages = const [HomePage(), SavedPage(), MyTripsPage(), SettingsPage()];
      tabs = [
        _TabItem(AppIcons.explore, AppIcons.explore,
            context.copy('Explore', 'Explorer')),
        _TabItem(AppIcons.saved, AppIcons.saved,
            context.copy('Saved', 'Favoris')),
        _TabItem(AppIcons.trips, AppIcons.trips,
            context.copy('Trips', 'Voyages')),
        _TabItem(AppIcons.settings, AppIcons.settings,
            context.copy('Settings', 'Réglages')),
      ];
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BlocProvider.value(
      value: _listings,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(index: _index, children: pages),
            Positioned(
              right: 16,
              bottom: bottomInset + 84,
              child: AssistantLauncher(
                contextNote:
                    'The user is browsing the Nestly app, currently on the '
                    '"${tabs[_index].label}" tab as a ${role.name}.',
                suggestions: isHost || isPartner
                    ? [
                        context.copy(
                          'Help me write a great listing description',
                          'Aide-moi à rédiger une belle annonce',
                        ),
                        context.copy(
                          'How should I price my place?',
                          'Comment fixer le prix de mon logement ?',
                        ),
                        context.copy(
                          'Tips to get more bookings',
                          'Astuces pour plus de réservations',
                        ),
                      ]
                    : [
                        context.copy(
                          'Find a place that fits my budget',
                          'Trouver un logement dans mon budget',
                        ),
                        context.copy(
                          'Which area in Tunisia suits me best?',
                          'Quelle région de Tunisie me convient ?',
                        ),
                        context.copy(
                          'What should I check before I rent?',
                          'Que vérifier avant de louer ?',
                        ),
                      ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 10,
              child: Builder(
                builder: (innerContext) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GlassTabBar(
                      tabs: tabs,
                      index: _index,
                      onSelected: _select,
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 10),
                      _HostAction(onTap: () => _addPlace(innerContext)),
                    ],
                    if (isPartner) ...[
                      const SizedBox(width: 10),
                      _HostAction(onTap: () => _addPlace(innerContext,
                          enforceLimit: true)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPlace(
    BuildContext innerContext, {
    bool enforceLimit = false,
  }) async {
    HapticFeedback.mediumImpact();
    // Partners are capped by their subscription tier — check before publishing.
    if (enforceLimit && !await ensureWithinListingLimit(innerContext)) return;
    if (!innerContext.mounted) return;
    final listingsCubit = innerContext.read<ListingsCubit>();
    final published = await Navigator.of(innerContext).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateListingPage()),
    );
    if (published == true) {
      // Refresh the seeker feed AND the host's own listings so the new place
      // shows up in both immediately.
      await Future.wait([
        listingsCubit.refresh(),
        sl<HostListingsStore>().load(),
      ]);
    }
  }
}

class _TabItem {
  const _TabItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// The floating Liquid Glass capsule holding the tabs.
class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.tabs,
    required this.index,
    required this.onSelected,
  });

  final List<_TabItem> tabs;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      radius: 30,
      padding: const EdgeInsets.all(6),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 110,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < tabs.length; i++)
                _TabButton(
                  item: tabs[i],
                  active: i == index,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 16 : 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active ? AppColors.onAccent : AppColors.secondaryLabel,
            ),
            if (active) ...[
              const SizedBox(width: 7),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.onAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Host-only floating action, a solid accent circle beside the glass bar.
class _HostAction extends StatelessWidget {
  const _HostAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.22),
              offset: const Offset(0, 8),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: const Icon(
          AppIcons.add,
          color: AppColors.onAccent,
          size: 26,
        ),
      ),
    );
  }
}
