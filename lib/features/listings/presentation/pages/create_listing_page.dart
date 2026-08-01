import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/localization/app_locale.dart';
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
import '../../domain/entities/listing_schema.dart';
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
  final _district = TextEditingController();
  final _phone = TextEditingController();
  final _instructions = TextEditingController();

  ListingType _type = ListingType.entirePlace;
  RentalTerm _term = RentalTerm.longTerm;
  final Set<String> _audience = {'adults'};
  int _bedrooms = 1;
  int _bathrooms = 1;
  int _area = 45;
  int _cover = 0;

  /// Canonical ids, not display strings — the dashboard reads these back and
  /// only understands the ids in `listing_schema.dart`.
  final Set<String> _amenities = {...defaultAmenityIds};
  final Set<String> _tags = {};

  // The rest of what the agency wizard collects, so a listing created on a
  // phone is indistinguishable from one created on the web.
  PropertyType _propertyType = PropertyType.apartment;
  int _maxGuests = 2;
  PricingModel _pricingModel = PricingModel.month;
  int _minNights = 1;
  CancellationPolicy _cancellation = CancellationPolicy.flexible;
  final Set<PaymentMethod> _paymentMethods = {PaymentMethod.cash};
  PaymentPolicy _paymentPolicy = PaymentPolicy.optionalAdvance;
  bool _allowPets = false;
  bool _allowSmoking = false;
  bool _allowParties = false;
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

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _address.dispose();
    _price.dispose();
    _description.dispose();
    _district.dispose();
    _phone.dispose();
    _instructions.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_title.text.trim().isEmpty) {
      return context.copy(
        'Give your place a title.',
        'Donnez un titre à votre logement.',
      );
    }
    if (_city.text.trim().isEmpty) {
      return context.copy(
        'Where is it? Add a city or area.',
        'Où est-ce ? Ajoutez une ville ou une zone.',
      );
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      return context.copy(
        'Enter a price in DT.',
        'Saisissez un prix en DT.',
      );
    }
    // Same check the dashboard runs — eight local digits, +216 optional.
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !isValidTunisianPhone(phone)) {
      return context.copy(
        'That contact number doesn\'t look right.',
        'Ce numéro de contact semble incorrect.',
      );
    }
    if (_paymentMethods.isEmpty) {
      return context.copy(
        'Pick at least one payment method.',
        'Choisissez au moins un mode de paiement.',
      );
    }
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
    // Resolve the language now (synchronously) so the error copy below never
    // touches BuildContext across the async publish gap.
    final french = context.isFrench;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (SupabaseService.isReady) {
        await _publishToSupabase(french);
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
            : (french
                  ? 'Impossible de publier. Vérifiez votre connexion.'
                  : 'Couldn\'t publish. Check your connection and try again.');
      });
    }
  }

  /// Publishes to Supabase like the web dashboard: uploads the imported photos
  /// to Cloudinary, then inserts the listing so it appears for every seeker.
  Future<void> _publishToSupabase(bool french) async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw _PublishError(
        french ? 'Connectez-vous pour publier.' : 'Please sign in to publish.',
      );
    }

    final urls = await _uploadPhotos(french);
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
      throw _PublishError(_friendlyDbError(e.toString(), french));
    }
  }

  /// Uploads the imported photos to Cloudinary and returns their URLs.
  Future<List<String>> _uploadPhotos(bool french) async {
    final urls = <String>[];
    for (final path in _photos) {
      try {
        urls.add(await Cloudinary.uploadFile(File(path)));
      } on CloudinaryException catch (e) {
        throw _PublishError(e.message);
      } catch (_) {
        throw _PublishError(
          french
              ? 'Impossible d\'envoyer vos photos. Vérifiez votre connexion.'
              : 'Couldn\'t upload your photos. Check your connection and try again.',
        );
      }
    }
    return urls;
  }

  String _friendlyDbError(String raw, bool french) {
    final r = raw.toLowerCase();
    if (r.contains('row-level security') || r.contains('rls')) {
      return french
          ? 'Seuls les comptes agence peuvent publier des annonces.'
          : 'Only agency accounts can publish listings.';
    }
    if (r.contains('column') && r.contains('does not exist')) {
      return french
          ? 'Une migration récente manque dans la base de données.'
          : 'The database is missing a recent migration. Please run them.';
    }
    return french
        ? 'Impossible de publier l\'annonce. Réessayez.'
        : 'Couldn\'t publish the listing. Please try again.';
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
      tags: _tags.toList(),
      isSuperhost: false,
      availableFrom: 'Now',
      billsIncluded: false,
      flatmates: _type == ListingType.sharedRoom ? 2 : 0,
      // Published straight away: a phone listing goes live, it doesn't sit in
      // the dashboard's draft queue.
      status: ListingStatus.published,
      propertyType: _propertyType,
      maxGuests: _maxGuests,
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
      contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      rules: HouseRules(
        pets: _allowPets,
        smoking: _allowSmoking,
        party: _allowParties,
        instructions: _instructions.text.trim(),
      ),
      pricing: ListingPricing(
        model: _pricingModel,
        amount: double.parse(_price.text.trim()),
        minNights: _minNights,
      ),
      conditions: BookingConditions(
        cancellation: _cancellation,
        paymentMethods: _paymentMethods.toList(),
        paymentPolicy: _paymentPolicy,
      ),
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
                  Text(
                    context.copy('New listing', 'Nouvelle annonce'),
                    style: theme.textTheme.titleMedium,
                  ),
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
                      context.copy('List your place', 'Publiez votre logement'),
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 40),
                    child: Text(
                      context.copy(
                        'A few details and a cover — we wire the rooms into a '
                        '3D walkthrough so seekers can tour before they visit.',
                        'Quelques détails et une couverture — nous assemblons '
                        'les pièces en visite 3D pour explorer avant de venir.',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Photos', 'Photos')),
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
                    context.copy(
                      'Import your own photos — they power the 3D tour. Tap one to '
                      'set the cover.',
                      'Importez vos photos — elles alimentent la visite 3D. '
                      'Touchez-en une pour définir la couverture.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('The basics', 'Les bases')),
                  const SizedBox(height: AppSpacing.sm),
                  NeuField(
                    controller: _title,
                    placeholder: context.copy(
                      'Title — e.g. Bright T3 near Lac 2',
                      'Titre — ex. T3 lumineux près du Lac 2',
                    ),
                    icon: Icons.title_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _city,
                    placeholder: context.copy(
                      'City or area — e.g. Tunis, Lac 2',
                      'Ville ou zone — ex. Tunis, Lac 2',
                    ),
                    icon: Icons.place_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _district,
                    placeholder: context.copy(
                      'Neighbourhood (optional) — e.g. Khezama',
                      'Quartier (facultatif) — ex. Khezama',
                    ),
                    icon: Icons.explore_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _address,
                    placeholder: context.copy(
                      'Street address (optional)',
                      'Adresse (facultatif)',
                    ),
                    icon: Icons.signpost_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _phone,
                    placeholder: context.copy(
                      'Contact number — e.g. +216 20 000 000',
                      'Numéro de contact — ex. +216 20 000 000',
                    ),
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Property type', 'Type de bien')),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final t in PropertyType.values)
                        _SelectChip(
                          label: t.labelFor(context.isFrench),
                          selected: _propertyType == t,
                          onTap: () => setState(() => _propertyType = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('What are you listing?', 'Que proposez-vous ?')),
                  const SizedBox(height: AppSpacing.sm),
                  _TypeSelector(
                    type: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Rental term', 'Durée de location')),
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
                                    t.labelFor(context.isFrench),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _term == t
                                          ? AppColors.onAccent
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.blurbFor(context.isFrench),
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

                  _Label(context.copy('Suitable for', 'Convient pour')),
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
                          label: _audienceLabel(context, a),
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

                  _Label(context.copy('Price & size', 'Prix & surface')),
                  const SizedBox(height: AppSpacing.sm),
                  // The period has to travel with the number. A bare "180" is
                  // meaningless to whoever reads the row next.
                  Row(
                    children: [
                      for (final m in PricingModel.values) ...[
                        Expanded(
                          child: _SelectChip(
                            label: m.labelFor(context.isFrench),
                            selected: _pricingModel == m,
                            onTap: () => setState(() => _pricingModel = m),
                          ),
                        ),
                        if (m != PricingModel.values.last)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _price,
                    placeholder: context.copy(
                      'Price in DT per ${_pricingModel.unitFor(false)}',
                      'Prix en DT par ${_pricingModel.unitFor(true)}',
                    ),
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Stepper(
                    label: context.copy('Sleeps', 'Couchages'),
                    value: _maxGuests,
                    min: 1,
                    onChanged: (v) => setState(() => _maxGuests = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_pricingModel == PricingModel.night) ...[
                    _Stepper(
                      label: context.copy('Minimum nights', 'Nuits minimum'),
                      value: _minNights,
                      min: 1,
                      onChanged: (v) => setState(() => _minNights = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _Stepper(
                    label: context.copy('Bedrooms', 'Chambres'),
                    value: _bedrooms,
                    min: 0,
                    onChanged: (v) => setState(() => _bedrooms = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Stepper(
                    label: context.copy('Bathrooms', 'Salles de bain'),
                    value: _bathrooms,
                    min: 1,
                    onChanged: (v) => setState(() => _bathrooms = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Stepper(
                    label: context.copy('Area (m²)', 'Surface (m²)'),
                    value: _area,
                    min: 8,
                    step: 5,
                    onChanged: (v) => setState(() => _area = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Amenities', 'Équipements')),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final id in amenityIds)
                        _SelectChip(
                          label: amenityLabel(id, context.isFrench),
                          selected: _amenities.contains(id),
                          onTap: () => setState(() {
                            _amenities.contains(id)
                                ? _amenities.remove(id)
                                : _amenities.add(id);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Highlights', 'Points forts')),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final id in listingTagIds)
                        _SelectChip(
                          label: listingTagLabel(id, context.isFrench),
                          selected: _tags.contains(id),
                          onTap: () => setState(() {
                            _tags.contains(id)
                                ? _tags.remove(id)
                                : _tags.add(id);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('House rules', 'Règles du logement')),
                  const SizedBox(height: AppSpacing.sm),
                  _RuleSwitch(
                    label: context.copy('Pets allowed', 'Animaux acceptés'),
                    value: _allowPets,
                    onChanged: (v) => setState(() => _allowPets = v),
                  ),
                  _RuleSwitch(
                    label: context.copy('Smoking allowed', 'Fumeur autorisé'),
                    value: _allowSmoking,
                    onChanged: (v) => setState(() => _allowSmoking = v),
                  ),
                  _RuleSwitch(
                    label: context.copy(
                      'Parties & events allowed',
                      'Fêtes & événements autorisés',
                    ),
                    value: _allowParties,
                    onChanged: (v) => setState(() => _allowParties = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeuField(
                    controller: _instructions,
                    maxLines: 2,
                    placeholder: context.copy(
                      'Anything else guests should know…',
                      'Autre chose à savoir pour les voyageurs…',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(
                    context.copy('Cancellation policy', 'Politique d\'annulation'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in CancellationPolicy.values)
                        _SelectChip(
                          label: p.labelFor(context.isFrench),
                          selected: _cancellation == p,
                          onTap: () => setState(() => _cancellation = p),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Payment accepted', 'Paiement accepté')),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final m in PaymentMethod.values)
                        _SelectChip(
                          label: m.labelFor(context.isFrench),
                          selected: _paymentMethods.contains(m),
                          // At least one method has to stay on, mirroring the
                          // dashboard's `paymentMethodRequired` rule.
                          onTap: () => setState(() {
                            if (_paymentMethods.contains(m)) {
                              if (_paymentMethods.length > 1) {
                                _paymentMethods.remove(m);
                              }
                            } else {
                              _paymentMethods.add(m);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in PaymentPolicy.values)
                        _SelectChip(
                          label: p.labelFor(context.isFrench),
                          selected: _paymentPolicy == p,
                          onTap: () => setState(() => _paymentPolicy = p),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _Label(context.copy('Description', 'Description')),
                  const SizedBox(height: AppSpacing.sm),
                  NeuField(
                    controller: _description,
                    placeholder: context.copy(
                      'Tell seekers what makes this place feel like home…',
                      'Décrivez ce qui rend ce logement accueillant…',
                    ),
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
                label: context.copy('Publish place', 'Publier le logement'),
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

/// Localized label for an audience id used by the "Suitable for" chips.
String _audienceLabel(BuildContext context, String id) => switch (id) {
  'adults' => context.copy('Adults', 'Adultes'),
  'children' => context.copy('Children', 'Enfants'),
  'baby' => context.copy('Baby', 'Bébé'),
  'pets' => context.copy('Pets', 'Animaux'),
  _ => id,
};

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
          // Centred so the chip still reads right when it's stretched inside an
          // Expanded row rather than sized to its own text.
          textAlign: TextAlign.center,
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

/// One house rule, as a plain labelled toggle. Deliberately quieter than a chip
/// row — these are answers to yes/no questions, not choices to browse.
class _RuleSwitch extends StatelessWidget {
  const _RuleSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.label,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.ink,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
