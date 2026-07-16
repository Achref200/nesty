import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/property.dart';
import '../cubit/listing_filter.dart';

/// Opens the search & filter sheet. [destinations] are the real cities from the
/// loaded feed (no mock data). Returns the chosen filter, or null if dismissed.
Future<ListingFilter?> showFilterSheet(
  BuildContext context,
  ListingFilter current,
  List<String> destinations,
) {
  return showModalBottomSheet<ListingFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (_, controller) => _FilterSheet(
        initial: current,
        destinations: destinations,
        controller: controller,
      ),
    ),
  );
}

const _audience = <(String, String, IconData)>[
  ('adults', 'Adults', Icons.person_rounded),
  ('children', 'Children', Icons.child_care_rounded),
  ('baby', 'Baby', Icons.crib_rounded),
  ('pets', 'Pets', Icons.pets_rounded),
];

const _minPrice = 200.0;
const _maxPrice = 6000.0;

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.destinations,
    required this.controller,
  });

  final ListingFilter initial;
  final List<String> destinations;
  final ScrollController controller;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _search =
      TextEditingController(text: widget.initial.city ?? '');
  late RentalTerm? _term = widget.initial.rentalTerm;
  late final Set<String> _aud = {...widget.initial.audience};
  late int _guests = widget.initial.guests ?? 1;
  late double _price = widget.initial.maxPrice ?? _maxPrice;
  late bool _nearest = widget.initial.nearestFirst;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearAll() {
    HapticFeedback.selectionClick();
    setState(() {
      _search.clear();
      _term = null;
      _aud.clear();
      _guests = 1;
      _price = _maxPrice;
      _nearest = false;
    });
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    final city = _search.text.trim();
    Navigator.of(context).pop(
      ListingFilter(
        city: city.isEmpty ? null : city,
        rentalTerm: _term,
        audience: _aud,
        guests: _guests > 1 ? _guests : null,
        maxPrice: _price >= _maxPrice ? null : _price,
        nearestFirst: _nearest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const _Grabber(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text('Filters', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.separator),
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.lg,
              AppSpacing.gutter,
              AppSpacing.xl,
            ),
            children: [
              // -------- Where --------
              const _Label('Where to?'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(AppIcons.explore,
                        size: 20, color: AppColors.secondaryLabel),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search a city or area',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _search.clear()),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.secondaryLabel),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Chip(
                    label: 'Nearby',
                    icon: Icons.near_me_rounded,
                    selected: _nearest,
                    onTap: () => setState(() => _nearest = !_nearest),
                  ),
                  for (final city in widget.destinations)
                    _Chip(
                      label: city,
                      selected:
                          _search.text.trim().toLowerCase() == city.toLowerCase(),
                      onTap: () => setState(() {
                        if (_search.text.trim().toLowerCase() ==
                            city.toLowerCase()) {
                          _search.clear();
                        } else {
                          _search.text = city;
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // -------- Rental term --------
              const _Label('How long'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _Segment(
                    label: 'Any',
                    selected: _term == null,
                    onTap: () => setState(() => _term = null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Segment(
                    label: 'Long term',
                    selected: _term == RentalTerm.longTerm,
                    onTap: () => setState(() => _term = RentalTerm.longTerm),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Segment(
                    label: 'Short term',
                    selected: _term == RentalTerm.shortTerm,
                    onTap: () => setState(() => _term = RentalTerm.shortTerm),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // -------- Who --------
              Row(
                children: [
                  const _Label('Guests'),
                  const Spacer(),
                  _RoundBtn(
                    icon: Icons.remove_rounded,
                    enabled: _guests > 1,
                    onTap: () => setState(() => _guests--),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_guests',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _RoundBtn(
                    icon: Icons.add_rounded,
                    enabled: _guests < 16,
                    onTap: () => setState(() => _guests++),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _Label('Suitable for'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final a in _audience)
                    _Chip(
                      label: a.$2,
                      icon: a.$3,
                      selected: _aud.contains(a.$1),
                      onTap: () => setState(() {
                        _aud.contains(a.$1)
                            ? _aud.remove(a.$1)
                            : _aud.add(a.$1);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // -------- Budget --------
              Row(
                children: [
                  const _Label('Max monthly price'),
                  const Spacer(),
                  Text(
                    _price >= _maxPrice ? 'Any' : '${_price.round()} TND',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _price,
                min: _minPrice,
                max: _maxPrice,
                divisions: 29,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.fill,
                onChanged: (v) => setState(() => _price = v),
              ),
            ],
          ),
        ),
        _Footer(onClear: _clearAll, onApply: _apply),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.separator,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? AppColors.onAccent : AppColors.ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onAccent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onAccent : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.ink : AppColors.separator,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.ink : AppColors.tertiaryLabel,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onClear, required this.onApply});
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Clear all',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, size: 20, color: AppColors.onAccent),
                  SizedBox(width: 8),
                  Text(
                    'Show homes',
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
