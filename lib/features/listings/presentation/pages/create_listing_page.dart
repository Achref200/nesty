import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../../core/widgets/neu/neu_icon_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/datasources/local_listings_store.dart';
import '../../data/models/property_model.dart';
import '../../domain/entities/property.dart';

/// A publish failure carrying a message that's safe to show the host.
class _PublishError implements Exception {
  const _PublishError(this.message);
  final String message;
}

/// The host's "publish a place" flow. A single, calm, sectioned form that turns
/// a few details and a cover into a live listing. When connected to Supabase it
/// publishes to the shared catalog (photos uploaded to Storage) exactly like the
/// web dashboard.
class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();

  ListingType _type = ListingType.entirePlace;
  RentalTerm _term = RentalTerm.longTerm;
  final Set<String> _audience = {'adults'};
  int _bedrooms = 1;
  int _bathrooms = 1;
  int _area = 45;
  int _cover = 0;
  final Set<String> _amenities = {'Wi-Fi'};
  final List<String> _photos = []; // local file paths the host imported
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;
  String? _error;

  /// The host's imported photos first, then curated fallbacks — so a place can
  /// be published with or without device photos.
  List<String> get _allCovers => [..._photos, ..._covers];

  static const _covers = [
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1200&q=80',
  ];

  static const _allAmenities = [
    'Wi-Fi',
    'Heating',
    'Air-con',
    'Elevator',
    'Washer',
    'Balcony',
    'Parking',
    'Kitchenette',
    'Desk',
    'Bills included',
  ];

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _address.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_title.text.trim().isEmpty) return 'Give your place a title.';
    if (_city.text.trim().isEmpty) return 'Where is it? Add a city or area.';
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) return 'Enter a monthly price in DT.';
    return null;
  }

  /// Lets the host import photos from their device. These feed the cover, the
  /// gallery and every room's frames for the 3D reconstruction.
  Future<void> _pickPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;
      setState(() {
        _photos.addAll(picked.map((x) => x.path));
        _cover = 0; // focus the first imported photo as the cover
        _error = null;
      });
      HapticFeedback.selectionClick();
    } catch (_) {
      setState(() => _error = 'Couldn\'t open your photos. Please try again.');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      if (_cover >= _allCovers.length) _cover = 0;
    });
  }

  void _publish() async {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      HapticFeedback.mediumImpact();
      setState(() => _error = error);
      return;
    }
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (SupabaseService.isReady) {
        await _publishToSupabase();
      } else {
        // Demo mode — keep it on-device so the feed still lights up.
        sl<LocalListingsStore>().add(_buildProperty(images: _photos));
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e is _PublishError
            ? e.message
            : 'Couldn\'t publish. Check your connection and try again.';
      });
    }
  }

  /// Publishes to Supabase like the web dashboard: uploads the imported photos
  /// to Cloudinary, then inserts the listing so it appears for every seeker.
  Future<void> _publishToSupabase() async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw const _PublishError('Please sign in to publish.');

    final urls = await _uploadPhotos();
    final property = _buildProperty(images: urls);

    final map = property.toMap()
      ..remove('id')
      ..['host_id'] = uid
      ..['status'] = 'active';
    // Drop optional columns when empty so publishing still works even if the
    // location migration hasn't been applied yet.
    map.removeWhere(
      (k, v) => (k == 'latitude' || k == 'longitude') && v == null,
    );

    try {
      await client.from('listings').insert(map);
    } catch (e) {
      throw _PublishError(_friendlyDbError(e.toString()));
    }
  }

  /// Uploads the imported photos to Cloudinary and returns their URLs.
  Future<List<String>> _uploadPhotos() async {
    final urls = <String>[];
    for (final path in _photos) {
      try {
        urls.add(await Cloudinary.uploadFile(File(path)));
      } on CloudinaryException catch (e) {
        throw _PublishError(e.message);
      } catch (_) {
        throw const _PublishError(
          'Couldn\'t upload your photos. Check your connection and try again.',
        );
      }
    }
    return urls;
  }

  String _friendlyDbError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('row-level security') || r.contains('rls')) {
      return 'Only agency accounts can publish listings.';
    }
    if (r.contains('column') && r.contains('does not exist')) {
      return 'The database is missing a recent migration. Please run them.';
    }
    return 'Couldn\'t publish the listing. Please try again.';
  }

  /// Builds the listing from the form. [images] are the final image sources
  /// (uploaded URLs for Supabase, local paths for the on-device demo).
  PropertyModel _buildProperty({required List<String> images}) {
    final id = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final hostName = context.read<AuthCubit>().state.user?.displayName ?? 'You';
    final hasPhotos = images.isNotEmpty;

    final cover = hasPhotos ? images.first : _covers.first;
    final gallery = <String>{
      cover,
      ...images,
      if (!hasPhotos) ..._covers,
    }.take(8).toList();

    return PropertyModel(
      id: id,
      title: _title.text.trim(),
      city: _city.text.trim(),
      address: _address.text.trim().isEmpty
          ? _city.text.trim()
          : _address.text.trim(),
      pricePerMonth: double.parse(_price.text.trim()),
      currency: 'TND',
      type: _type,
      rentalTerm: _term,
      audience: _audience.toList(),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      areaSqm: _area.toDouble(),
      coverImage: cover,
      gallery: gallery,
      rating: 0,
      reviewCount: 0,
      hostName: hostName,
      description: _description.text.trim().isEmpty
          ? 'A new place on Nesty.'
          : _description.text.trim(),
      amenities: _amenities.toList(),
      isSuperhost: false,
      availableFrom: 'Now',
      billsIncluded: _amenities.contains('Bills included'),
      flatmates: _type == ListingType.sharedRoom ? 2 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                0,
              ),
              child: Row(
                children: [
                  NeuIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text('New listing', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  AppSpacing.xxl,
                ),
                children: [
                  FadeSlideIn(
                    child: Text(
                      'List your place',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 40),
                    child: Text(
                      'A few details and a cover — we wire the rooms into a '
                      '3D walkthrough so seekers can tour before they visit.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('Photos'),
                  const SizedBox(height: AppSpacing.sm),
                  _CoverPicker(
                    covers: _allCovers,
                    photoCount: _photos.length,
                    selected: _cover,
                    onSelected: (i) => setState(() => _cover = i),
                    onAdd: _pickPhotos,
                    onRemovePhoto: _removePhoto,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Import your own photos — they power the 3D tour. Tap one to '
                    'set the cover.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('The basics'),
                  const SizedBox(height: AppSpacing.sm),
                  NeuField(
                    controller: _title,
                    placeholder: 'Title — e.g. Bright T3 near Lac 2',
                    icon: Icons.title_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _city,
                    placeholder: 'City or area — e.g. Tunis, Lac 2',
                    icon: Icons.place_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _address,
                    placeholder: 'Street address (optional)',
                    icon: Icons.signpost_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('What are you listing?'),
                  const SizedBox(height: AppSpacing.sm),
                  _TypeSelector(
                    type: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('Rental term'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final t in RentalTerm.values) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _term = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                                horizontal: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: _term == t
                                    ? AppColors.ink
                                    : AppColors.fill,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _term == t
                                          ? AppColors.onAccent
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.blurb,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _term == t
                                          ? AppColors.onAccent
                                          : AppColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (t != RentalTerm.values.last)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('Suitable for'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final a in const [
                        'adults',
                        'children',
                        'baby',
                        'pets',
                      ])
                        _SelectChip(
                          label: '${a[0].toUpperCase()}${a.substring(1)}',
                          selected: _audience.contains(a),
                          onTap: () => setState(() {
                            _audience.contains(a)
                                ? _audience.remove(a)
                                : _audience.add(a);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('Price & size'),
                  const SizedBox(height: AppSpacing.sm),
                  NeuField(
                    controller: _price,
                    placeholder: 'Monthly price in DT',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Stepper(
                    label: 'Bedrooms',
                    value: _bedrooms,
                    min: 0,
                    onChanged: (v) => setState(() => _bedrooms = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Stepper(
                    label: 'Bathrooms',
                    value: _bathrooms,
                    min: 1,
                    onChanged: (v) => setState(() => _bathrooms = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Stepper(
                    label: 'Area (m²)',
                    value: _area,
                    min: 8,
                    step: 5,
                    onChanged: (v) => setState(() => _area = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('Amenities'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final a in _allAmenities)
                        _SelectChip(
                          label: a,
                          selected: _amenities.contains(a),
                          onTap: () => setState(() {
                            _amenities.contains(a)
                                ? _amenities.remove(a)
                                : _amenities.add(a);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label('Description'),
                  const SizedBox(height: AppSpacing.sm),
                  NeuField(
                    controller: _description,
                    placeholder:
                        'Tell seekers what makes this place feel like '
                        'home…',
                    icon: Icons.notes_rounded,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              child: NeuButton(
                label: 'Publish place',
                icon: Icons.check_rounded,
                loading: _submitting,
                onPressed: _publish,
              ),
            ),
          ],
        ),
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
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.secondaryLabel,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.covers,
    required this.photoCount,
    required this.selected,
    required this.onSelected,
    required this.onAdd,
    required this.onRemovePhoto,
  });

  final List<String> covers;
  final int photoCount;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: covers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.separator, width: 0.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 22,
                      color: AppColors.ink,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Import',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final i = index - 1;
          final active = i == selected;
          final isImported = i < photoCount;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.separator,
                  width: active ? 2 : 0.5,
                ),
                image: DecorationImage(
                  image: appImageProvider(covers[i]),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  if (active)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ),
                  if (isImported)
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => onRemovePhoto(i),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.type, required this.onChanged});
  final ListingType type;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in ListingType.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(t);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t == type ? AppColors.ink : AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  t.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t == type ? AppColors.onAccent : AppColors.label,
                  ),
                ),
              ),
            ),
          ),
          if (t != ListingType.values.last)
            const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _RoundBtn(
            icon: Icons.remove_rounded,
            onTap: value > min
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value - step);
                  }
                : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          _RoundBtn(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(value + step);
            },
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.separator, width: 0.5),
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

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onAccent : AppColors.label,
          ),
        ),
      ),
    );
  }
}
