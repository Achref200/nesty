import 'package:flutter/material.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'spinning_cube.dart';

/// A minimal iPhone-style device frame that renders a live app-screen mock
/// ([child]) behind a dynamic-island pill. Used by the onboarding showcase to
/// present real Nesty features — reserving, trip prep, 3D tours, nearby — as
/// little working screens rather than a static poster.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 234,
      height: 470,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(46),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 20),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: child,
                ),
              ),
              // Dynamic-island pill.
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 11),
                  width: 80,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared chrome for a feature mock: a small app header, the feature body, and
/// a four-tab bottom bar — so each preview reads as a genuine app screen.
class _MockScreen extends StatelessWidget {
  const _MockScreen({
    required this.title,
    required this.body,
    this.activeTab = 0,
  });

  final String title;
  final Widget body;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: body,
          ),
        ),
        _MockTabBar(active: activeTab),
      ],
    );
  }
}

class _MockTabBar extends StatelessWidget {
  const _MockTabBar({this.active = 0});
  final int active;

  static const _icons = [
    AppIcons.explore,
    AppIcons.saved,
    AppIcons.trips,
    AppIcons.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 9, bottom: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.separator)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < _icons.length; i++)
            Icon(
              _icons[i],
              size: 20,
              color: i == active ? AppColors.ink : AppColors.tertiaryLabel,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- primitives --

Widget _bar({double width = 90, double height = 9, Color? color}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: color ?? AppColors.separator,
    borderRadius: BorderRadius.circular(4),
  ),
);

Widget _infoRow(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(
    children: [
      Icon(icon, size: 15, color: AppColors.secondaryLabel),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
);

Widget _cta(String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
  decoration: BoxDecoration(
    color: AppColors.accent,
    borderRadius: BorderRadius.circular(AppRadius.pill),
  ),
  child: Text(
    label,
    style: const TextStyle(
      color: AppColors.onAccent,
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget _pill(String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
  decoration: BoxDecoration(
    color: AppColors.ink.withValues(alpha: 0.82),
    borderRadius: BorderRadius.circular(AppRadius.pill),
  ),
  child: Text(
    label,
    style: const TextStyle(
      color: AppColors.white,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget _chip(String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.fill,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    border: Border.all(color: AppColors.separator),
  ),
  child: Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    ),
  ),
);

Widget _checkRow(String text, {required bool done}) => Padding(
  padding: const EdgeInsets.only(bottom: 11),
  child: Row(
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: done ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: done ? AppColors.accent : AppColors.separator,
            width: 1.5,
          ),
        ),
        child: done
            ? const Icon(AppIcons.check, size: 12, color: AppColors.onAccent)
            : null,
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: done ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    ],
  ),
);

// -------------------------------------------------------------------- mocks --

/// Reserve a stay — a listing with dates, guests and a clear CTA.
class ReserveMock extends StatelessWidget {
  const ReserveMock({super.key});

  @override
  Widget build(BuildContext context) {
    return _MockScreen(
      title: context.copy('Reserve', 'Réserver'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.separator,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _pill(context.copy('Sea view', 'Vue mer')),
                ),
                const Positioned(
                  right: 10,
                  top: 10,
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _bar(width: 132, height: 10),
          const SizedBox(height: 7),
          _bar(width: 84),
          const SizedBox(height: 14),
          _infoRow(AppIcons.calendar, context.copy('Jul 12 → 19', '12 → 19 juil.')),
          _infoRow(AppIcons.guests, context.copy('4 guests', '4 voyageurs')),
          const Spacer(),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '720 DT',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    context.copy('total stay', 'séjour total'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.tertiaryLabel,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _cta(context.copy('Reserve', 'Réserver')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Prepare your trip — a friendly pre-arrival checklist.
class TripPrepMock extends StatelessWidget {
  const TripPrepMock({super.key});

  @override
  Widget build(BuildContext context) {
    return _MockScreen(
      title: context.copy('Your trip', 'Votre voyage'),
      activeTab: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.location, size: 18, color: AppColors.white),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hammamet',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.copy('Check-in in 5 days', 'Arrivée dans 5 jours'),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.copy('Before you go', 'Avant de partir'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLabel,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          _checkRow(context.copy('Booking confirmed', 'Réservation confirmée'),
              done: true),
          _checkRow(context.copy('Identity verified', 'Identité vérifiée'),
              done: true),
          _checkRow(context.copy('Message your host', 'Contacter l\'hôte'),
              done: false),
          _checkRow(context.copy('Pack the essentials', 'Préparer l\'essentiel'),
              done: false),
        ],
      ),
    );
  }
}

/// Tour in 3D — the product's signature: turn any home in real 3D.
class Tour3dMock extends StatelessWidget {
  const Tour3dMock({super.key});

  @override
  Widget build(BuildContext context) {
    return _MockScreen(
      title: context.copy('3D tour', 'Visite 3D'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: SpinningCube(size: 92, icon: AppIcons.tour3d),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _pill('AR'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _bar(width: 150, height: 10),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(context.copy('Living', 'Salon')),
              const SizedBox(width: 8),
              _chip(context.copy('Kitchen', 'Cuisine')),
              const SizedBox(width: 8),
              _chip(context.copy('Bedroom', 'Chambre')),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _cta(context.copy('Enter 3D tour', 'Entrer en 3D')),
          ),
        ],
      ),
    );
  }
}

/// Discover nearby — a little map with homes popping up around you.
class NearbyMock extends StatelessWidget {
  const NearbyMock({super.key});

  @override
  Widget build(BuildContext context) {
    return _MockScreen(
      title: context.copy('Nearby', 'À proximité'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.separator),
              ),
              child: Stack(
                children: [
                  // A couple of faint "roads".
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 60,
                    child: Container(height: 6, color: AppColors.separator),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 96,
                    child: Container(width: 6, color: AppColors.separator),
                  ),
                  // Home pins.
                  const Positioned(left: 24, top: 24, child: _MapPin()),
                  const Positioned(right: 22, top: 40, child: _MapPin()),
                  const Positioned(left: 40, bottom: 30, child: _MapPin()),
                  const Positioned(right: 34, bottom: 22, child: _MapPin()),
                  // You.
                  Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.separator),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.location, size: 17, color: AppColors.ink),
                const SizedBox(width: 10),
                Text(
                  context.copy('12 homes within 2 km', '12 logements à 2 km'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(AppIcons.home, size: 13, color: AppColors.white),
    );
  }
}
