import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/page_transitions.dart';
import '../../../../core/widgets/motion/typing_text.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/verification_store.dart';
import '../../domain/entities/verification.dart';

/// Starts the one-time identity-verification process and resolves to true once
/// it's submitted. Same calm paged design as the reservation flow: an intro,
/// pick a document, upload it, a selfie, your details, a review, and a warm
/// confirmation — the Upwork/marketplace "get verified" step, in Nesty's voice.
Future<bool> startVerificationFlow(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    softPageRoute(const _VerificationFlow(), fullscreenDialog: true),
  );
  return result ?? false;
}

class _VerificationFlow extends StatefulWidget {
  const _VerificationFlow();

  @override
  State<_VerificationFlow> createState() => _VerificationFlowState();
}

class _VerificationFlowState extends State<_VerificationFlow> {
  static const _lastStep =
      5; // 0 intro · 1 document · 2 selfie · 3 details · 4 review · 5 done

  int _step = 0;
  bool _forward = true;
  String? _error;
  bool _submitting = false;

  IdDocumentType? _docType;
  String? _frontPath;
  String? _backPath;
  String? _selfiePath;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    if (user != null) _name.text = user.displayName;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _go(int next) {
    setState(() {
      _forward = next > _step;
      _error = null;
      _step = next;
    });
  }

  Future<void> _pick(ImageSource source, void Function(String) onPicked) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        preferredCameraDevice: CameraDevice.front,
      );
      if (x != null) setState(() => onPicked(x.path));
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.copy(
          "Couldn't open the camera or gallery.",
          "Impossible d'ouvrir l'appareil photo ou la galerie.",
        ));
      }
    }
  }

  bool _validate() {
    switch (_step) {
      case 1:
        if (_docType == null) {
          _fail(context.copy(
            'Choose which document you\u2019ll use.',
            'Choisissez le document à utiliser.',
          ));
          return false;
        }
        if (_frontPath == null) {
          _fail(context.copy(
            'Add a photo of your ${_docType!.label}.',
            'Ajoutez une photo de votre ${_docType!.labelFor(true)}.',
          ));
          return false;
        }
        if (_docType!.twoSided && _backPath == null) {
          _fail(context.copy(
            'Add the back of your document too.',
            'Ajoutez aussi le verso de votre document.',
          ));
          return false;
        }
        return true;
      case 2:
        if (_selfiePath == null) {
          _fail(context.copy(
            'Add a quick selfie so we can match it to your ID.',
            'Ajoutez un selfie pour le comparer à votre pièce.',
          ));
          return false;
        }
        return true;
      case 3:
        if (_name.text.trim().length < 3) {
          _fail(context.copy(
            'Enter your full legal name.',
            'Saisissez votre nom légal complet.',
          ));
          return false;
        }
        if (_phone.text.trim().length < 6) {
          _fail(context.copy(
            'Enter a phone number we can reach you on.',
            'Saisissez un numéro où vous joindre.',
          ));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _fail(String message) {
    HapticFeedback.mediumImpact();
    setState(() => _error = message);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await sl<VerificationStore>().submit(
        docType: _docType!,
        fullName: _name.text,
        phone: _phone.text,
        frontPath: _frontPath,
        backPath: _backPath,
        selfiePath: _selfiePath,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _submitting = false);
      _go(_lastStep);
    } on VerificationSubmissionException catch (error) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = context.copy(
          "Couldn't send your verification. Please try again.",
          "Impossible d'envoyer votre vérification. Réessayez.",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onDone = _step == _lastStep;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              lastStep: _lastStep,
              onBack: _step == 0
                  ? () => Navigator.of(context).pop(false)
                  : (onDone ? null : () => _go(_step - 1)),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 340),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: Offset(_forward ? 0.12 : -0.12, 0),
                    end: Offset.zero,
                  ).animate(anim);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: _stepBody(),
                ),
              ),
            ),
            if (!onDone) _footer(),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    0 => _introStep(),
    1 => _documentStep(),
    2 => _selfieStep(),
    3 => _detailsStep(),
    4 => _reviewStep(),
    _ => _doneStep(),
  };

  // ---- Step 0: intro ----
  Widget _introStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(AppIcons.shield, size: 28, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.copy('Verify your identity', 'Vérifiez votre identité'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.copy(
            'A quick one-time check — the same trust step you\u2019d do on Upwork '
            'or with your bank. It takes about two minutes.',
            'Une vérification rapide et unique — la même étape de confiance '
            'que sur Upwork ou avec votre banque. Environ deux minutes.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _BenefitRow(
          icon: AppIcons.verified,
          title: context.copy('A verified badge', 'Un badge vérifié'),
          subtitle: context.copy(
            'Show agencies and owners you\u2019re a real, trusted member.',
            'Montrez aux agences et propriétaires que vous êtes un membre '
            'réel et fiable.',
          ),
        ),
        _BenefitRow(
          icon: AppIcons.trending,
          title: context.copy('Faster replies', 'Réponses plus rapides'),
          subtitle: context.copy(
            'Verified requests are prioritised by agencies.',
            'Les demandes vérifiées sont prioritaires pour les agences.',
          ),
        ),
        _BenefitRow(
          icon: AppIcons.lock,
          title: context.copy('Private & secure', 'Privé et sécurisé'),
          subtitle: context.copy(
            'Your documents are used only to confirm it\u2019s you.',
            'Vos documents servent uniquement à confirmer votre identité.',
          ),
          last: true,
        ),
      ],
    );
  }

  // ---- Step 1: document ----
  Widget _documentStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Choose your document', 'Choisissez votre document'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final t in IdDocumentType.values) ...[
          _TypeCard(
            icon: t == IdDocumentType.passport
                ? AppIcons.document
                : AppIcons.billing,
            title: t.labelFor(context.isFrench),
            subtitle: t.blurbFor(context.isFrench),
            selected: _docType == t,
            onTap: () => setState(() {
              _docType = t;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_docType != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _MiniLabel(
            context.copy('Upload your document', 'Téléversez votre document'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UploadTile(
            label: _docType!.twoSided
                ? context.copy('Front side', 'Recto')
                : context.copy('Photo page', 'Page photo'),
            path: _frontPath,
            onTap: () => _pick(ImageSource.gallery, (p) => _frontPath = p),
          ),
          if (_docType!.twoSided) ...[
            const SizedBox(height: AppSpacing.sm),
            _UploadTile(
              label: context.copy('Back side', 'Verso'),
              path: _backPath,
              onTap: () => _pick(ImageSource.gallery, (p) => _backPath = p),
            ),
          ],
        ],
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 2: selfie ----
  Widget _selfieStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Add a selfie', 'Ajoutez un selfie'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.copy(
            'We match it to your document to confirm it\u2019s really you. '
            'Good light, no hat or sunglasses.',
            'Nous le comparons à votre document pour confirmer votre identité. '
            'Bonne lumière, sans chapeau ni lunettes de soleil.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _UploadTile(
          label: context.copy('Take a selfie', 'Prendre un selfie'),
          icon: AppIcons.camera,
          path: _selfiePath,
          tall: true,
          onTap: () => _pick(ImageSource.camera, (p) => _selfiePath = p),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => _pick(ImageSource.gallery, (p) => _selfiePath = p),
          icon: const Icon(AppIcons.image, size: 16),
          label: Text(
            context.copy('Choose from gallery instead', 'Choisir depuis la galerie'),
          ),
        ),
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 3: details ----
  Widget _detailsStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Your details', 'Vos informations'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.copy(
            'Enter them exactly as they appear on your document.',
            'Saisissez-les exactement comme sur votre document.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _MiniLabel(context.copy('Full legal name', 'Nom légal complet')),
        const SizedBox(height: AppSpacing.sm),
        NeuField(
          controller: _name,
          placeholder: context.copy('e.g. Ahmed Ben Salah', 'ex. Ahmed Ben Salah'),
          icon: AppIcons.profile,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.lg),
        _MiniLabel(context.copy('Phone number', 'Numéro de téléphone')),
        const SizedBox(height: AppSpacing.sm),
        NeuField(
          controller: _phone,
          placeholder: '+216 …',
          icon: AppIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 4: review ----
  Widget _reviewStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Review & submit', 'Vérifier & envoyer'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.separator, width: 0.5),
          ),
          child: Column(
            children: [
              _ReviewRow(
                icon: AppIcons.profile,
                label: context.copy('Name', 'Nom'),
                value: _name.text.trim(),
              ),
              _ReviewRow(
                icon: AppIcons.phone,
                label: context.copy('Phone', 'Téléphone'),
                value: _phone.text.trim(),
              ),
              _ReviewRow(
                icon: AppIcons.document,
                label: context.copy('Document', 'Document'),
                value: _docType?.labelFor(context.isFrench) ?? '',
              ),
              _ReviewRow(
                icon: AppIcons.check,
                label: context.copy('Uploaded', 'Téléversé'),
                value: _docType != null && _docType!.twoSided
                    ? context.copy(
                        'ID (front & back) · Selfie',
                        'Pièce (recto & verso) · Selfie',
                      )
                    : context.copy('Document · Selfie', 'Document · Selfie'),
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.copy(
            'Our team reviews submissions within 24–48h. We\u2019ll notify you the '
            'moment your badge is ready.',
            'Notre équipe examine les demandes sous 24–48h. Nous vous préviendrons '
            'dès que votre badge est prêt.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 5: submitted ----
  Widget _doneStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutBack,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.verified,
                color: AppColors.onAccent,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TypingText(
            context.copy('You\u2019re all set.', 'Tout est prêt.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
            startDelay: const Duration(milliseconds: 260),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.copy(
              'Your identity is under review. We\u2019ll add your verified badge '
              'as soon as it\u2019s approved — usually within a day.',
              'Votre identité est en cours d\u2019examen. Nous ajouterons votre '
              'badge vérifié dès qu\u2019il est approuvé — souvent en un jour.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          NeuButton(
            label: context.copy('Done', 'Terminé'),
            icon: AppIcons.check,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final isReview = _step == 4;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: NeuButton(
        label: _step == 0
            ? context.copy('Get started', 'Commencer')
            : (isReview
                  ? context.copy('Submit for review', 'Envoyer pour examen')
                  : context.copy('Continue', 'Continuer')),
        icon: isReview ? AppIcons.check : AppIcons.forward,
        loading: isReview && _submitting,
        onPressed: () {
          if (!_validate()) return;
          if (isReview) {
            _submit();
          } else {
            HapticFeedback.selectionClick();
            _go(_step + 1);
          }
        },
      ),
    );
  }

  Widget _errorRow(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: AppColors.danger,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

/// A one-line benefit on the intro step.
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.secondaryLabel,
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

/// Selectable document-type card — same look as the reservation flow's cards.
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.separator,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.onAccent.withValues(alpha: 0.14)
                    : AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.onAccent : AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: selected ? AppColors.onAccent : AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: selected
                          ? AppColors.onAccent.withValues(alpha: 0.7)
                          : AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dashed-look upload tile that becomes a thumbnail once an image is picked.
class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.path,
    required this.onTap,
    this.icon = AppIcons.upload,
    this.tall = false,
  });

  final String label;
  final String? path;
  final VoidCallback onTap;
  final IconData icon;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final has = path != null;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: tall ? 168 : 72,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: has ? AppColors.ink : AppColors.separator,
            width: has ? 1.2 : 0.5,
          ),
        ),
        child: has
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path!), fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.check,
                            size: 13,
                            color: AppColors.onAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: AppColors.onAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.ink),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.label,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: AppColors.secondaryLabel,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
              ),
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.secondaryLabel,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryLabel),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryLabel,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.lastStep,
    required this.onBack,
  });

  final int step;
  final int lastStep;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (step / (lastStep - 1)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : IconButton(
                    icon: const Icon(AppIcons.back, size: 20),
                    onPressed: onBack,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColors.fill,
                  valueColor: const AlwaysStoppedAnimation(AppColors.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}
