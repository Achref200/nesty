import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../listings/data/datasources/host_listings_store.dart';
import '../../../listings/presentation/cubit/listings_cubit.dart';
import '../../../listings/presentation/pages/create_listing_page.dart';
import '../../../listings/presentation/pages/home_page.dart';
import '../../../listings/presentation/pages/host_dashboard_page.dart';
import '../../../listings/presentation/pages/my_listings_page.dart';
import '../../../../core/widgets/ios/liquid_glass.dart';
import '../../../notifications/data/notifications_store.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../reservations/data/reservations_store.dart';
import '../../../reservations/presentation/pages/host_calendar_page.dart';
import '../../../reservations/presentation/pages/my_trips_page.dart';
import '../../../saved/presentation/pages/saved_page.dart';

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

  @override
  void initState() {
    super.initState();
    // Pull the signed-in user's reservations (guest or host) from the backend.
    sl<ReservationsStore>().load();
    // Load & live-subscribe to the notification center.
    sl<NotificationsStore>().load();
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

    // Role-specific tab sets. Seekers browse; hosts manage.
    final List<Widget> pages;
    final List<_TabItem> tabs;
    if (isHost) {
      pages = const [
        HostDashboardPage(),
        HostCalendarPage(),
        MyListingsPage(),
        ProfilePage(),
      ];
      tabs = const [
        _TabItem(AppIcons.dashboard, AppIcons.dashboard, 'Dashboard'),
        _TabItem(AppIcons.calendar, AppIcons.calendar, 'Calendar'),
        _TabItem(AppIcons.listings, AppIcons.listings, 'Listings'),
        _TabItem(AppIcons.profile, AppIcons.profile, 'Profile'),
      ];
    } else {
      pages = const [HomePage(), SavedPage(), MyTripsPage(), ProfilePage()];
      tabs = const [
        _TabItem(AppIcons.explore, AppIcons.explore, 'Explore'),
        _TabItem(AppIcons.saved, AppIcons.saved, 'Saved'),
        _TabItem(AppIcons.trips, AppIcons.trips, 'Trips'),
        _TabItem(AppIcons.profile, AppIcons.profile, 'Profile'),
      ];
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BlocProvider(
      create: (_) => sl<ListingsCubit>()..load(),
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(index: _index, children: pages),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPlace(BuildContext innerContext) async {
    HapticFeedback.mediumImpact();
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
