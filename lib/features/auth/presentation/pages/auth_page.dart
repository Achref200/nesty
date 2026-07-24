import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/three_dot_loader.dart';
import '../../../../core/widgets/motion/typing_text.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../../core/widgets/neu/neu_icon_button.dart';
import '../../../onboarding/presentation/widgets/spinning_cube.dart';
import '../../domain/entities/user_role.dart';
import '../auth_error.dart';
import '../cubit/auth_cubit.dart';

/// One adaptive auth surface for both sign-in and account creation.
///
/// The mode is a Material segmented button — no separate pages, no dead-ends.
/// When arriving from the welcome flow with a chosen [role], it opens directly
/// in "Create" mode and remembers the role for sign-up.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.role});

  /// The role chosen on the welcome screen, if any.
  final UserRole? role;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late int _mode; // 0 = sign in, 1 = create
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Agencies (hosts) are provisioned by Nesty — they can only sign in.
    _mode = (widget.role != null && widget.role != UserRole.host) ? 1 : 0;
    // Keep the live strength meter in sync while creating an account.
    _password.addListener(() {
      if (_isCreate && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isCreate => _mode == 1;

  /// Agencies are created by the Nesty team, so this surface is sign-in only.
  bool get _agencyOnly => widget.role == UserRole.host;

  void _setMode(int? value) {
    if (value == null || value == _mode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = value;
      _error = null;
    });
  }

  String? _validate() {
    if (_isCreate && _name.text.trim().length < 2) {
      return context.copy('Enter your name.', 'Saisissez votre nom.');
    }
    final emailOk = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_email.text.trim());
    if (!emailOk) {
      return context.copy(
        'Enter a valid email address.',
        'Saisissez une adresse e-mail valide.',
      );
    }
    if (_isCreate) {
      if (_password.text.length < 8) {
        return context.copy(
          'Use at least 8 characters.',
          'Utilisez au moins 8 caractères.',
        );
      }
      if (_passwordScore(_password.text) < 2) {
        return context.copy(
          'Add a number or a capital letter to strengthen your password.',
          'Ajoutez un chiffre ou une majuscule pour renforcer le mot de passe.',
        );
      }
    } else if (_password.text.isEmpty) {
      return context.copy('Enter your password.', 'Saisissez votre mot de passe.');
    } else if (_password.text.length < 6) {
      return context.copy(
        'Password needs 6+ characters.',
        'Le mot de passe doit comporter 6+ caractères.',
      );
    }
    return null;
  }

  /// A 0–4 password-strength score: length, mixed case, a digit, a symbol.
  static int _passwordScore(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      HapticFeedback.mediumImpact();
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);
    final cubit = context.read<AuthCubit>();
    if (_isCreate) {
      final err = await cubit.signUp(
        _name.text,
        _email.text,
        _password.text,
        widget.role ?? UserRole.seeker,
      );
      if (!mounted || err == null) return; // success → the router takes over
      _handleAuthError(err, creating: true);
    } else {
      // Role-scoped sign-in: an account can only enter its own space.
      final attempt = await cubit.signInScoped(
        _email.text,
        _password.text,
        expectedRole: widget.role,
      );
      if (!mounted) return;
      if (attempt.roleMismatch) {
        _showRoleMismatch(attempt.actualRole);
      } else if (attempt.error != null) {
        _handleAuthError(attempt.error!, creating: false);
      }
    }
  }

  /// Turns a raw auth error into the right guidance: a dialog that switches the
  /// user to the branch they actually need (sign in vs. create), a suspension
  /// notice, or a clear inline message.
  void _handleAuthError(String message, {required bool creating}) {
    HapticFeedback.mediumImpact();
    final kind = classifyAuthError(message);
    switch (kind) {
      case AuthErrorKind.alreadyRegistered:
        _showAccountExists();
        return;
      case AuthErrorKind.noAccount:
        if (!creating) {
          _showNoAccount();
          return;
        }
        break;
      case AuthErrorKind.banned:
        _showBanned();
        return;
      case AuthErrorKind.emailNotConfirmed:
        _setError(context.copy(
          'Please confirm your email first — check your inbox for the link.',
          'Confirmez d\'abord votre e-mail — le lien est dans votre boîte.',
        ));
        return;
      default:
        break;
    }
    _setError(_friendly(message, kind));
  }

  void _setError(String message) {
    setState(() => _error = message);
    AppFeedback.errorToast(context, message);
  }

  /// A friendlier, localized message for the generic error kinds.
  String _friendly(String raw, AuthErrorKind kind) {
    switch (kind) {
      case AuthErrorKind.wrongPassword:
        return context.copy(
          'That password doesn\'t look right. Try again or reset it.',
          'Ce mot de passe semble incorrect. Réessayez ou réinitialisez-le.',
        );
      case AuthErrorKind.rateLimited:
        return context.copy(
          'Too many attempts. Please wait a moment and try again.',
          'Trop de tentatives. Patientez un instant puis réessayez.',
        );
      case AuthErrorKind.network:
        return context.copy(
          'Network issue — check your connection and try again.',
          'Problème réseau — vérifiez votre connexion et réessayez.',
        );
      default:
        return raw;
    }
  }

  /// Create tapped, but the email already has an account → offer to sign in.
  void _showAccountExists() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.profile, color: AppColors.ink),
        title: Text(context.copy(
          'You already have an account',
          'Vous avez déjà un compte',
        )),
        content: Text(context.copy(
          'An account with this email already exists. Sign in instead?',
          'Un compte existe déjà avec cet e-mail. Voulez-vous vous connecter ?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.copy('Cancel', 'Annuler')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _password.clear();
              _setMode(0); // switch to sign-in, keep the email
            },
            child: Text(context.copy('Sign in', 'Se connecter')),
          ),
        ],
      ),
    );
  }

  /// Sign in tapped, but no account exists → offer to create one.
  void _showNoAccount() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.mail, color: AppColors.ink),
        title: Text(context.copy(
          'No account found',
          'Aucun compte trouvé',
        )),
        content: Text(
          _agencyOnly
              ? context.copy(
                  'We couldn\'t sign you in. Agency accounts are created by '
                      'Nesty — double-check your credentials or contact us.',
                  'Connexion impossible. Les comptes agence sont créés par '
                      'Nesty — vérifiez vos identifiants ou contactez-nous.',
                )
              : context.copy(
                  'We couldn\'t find an account for this email, or the password '
                      'was wrong. Create a new account?',
                  'Aucun compte pour cet e-mail, ou mot de passe incorrect. '
                      'Créer un nouveau compte ?',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.copy('Cancel', 'Annuler')),
          ),
          if (!_agencyOnly)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _setMode(1); // switch to create, keep the email
              },
              child: Text(context.copy('Create account', 'Créer un compte')),
            ),
        ],
      ),
    );
  }

  /// A fresh sign-in was refused because the account is suspended. The reason
  /// isn't available on this path (no session), so we keep it general.
  void _showBanned() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.shield, color: AppColors.danger),
        title: Text(context.copy(
          'Account suspended',
          'Compte suspendu',
        )),
        content: Text(context.copy(
          'This account is suspended and can\'t sign in right now. '
              'Contact support@nesty.tn if you think this is a mistake.',
          'Ce compte est suspendu et ne peut pas se connecter pour le moment. '
              'Contactez support@nesty.tn si vous pensez qu\'il s\'agit d\'une erreur.',
        )),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.copy('OK', 'OK')),
          ),
        ],
      ),
    );
  }

  /// Alerts the user that they knocked on the wrong door, and offers to jump
  /// to the space their account actually belongs to.
  void _showRoleMismatch(UserRole? actual) {
    HapticFeedback.heavyImpact();
    final entered = widget.role;
    final actualLabel = (actual ?? UserRole.seeker).shortLabel;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.shield, color: AppColors.ink),
        title: Text('This is the ${entered?.shortLabel ?? 'sign in'} space'),
        content: Text(
          'That account is a $actualLabel account, so it can\'t sign in here. '
          'Head to the $actualLabel space to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (actual != null) {
                context.pushReplacement(AppRoutes.auth, extra: actual);
              }
            },
            child: Text('Go to $actualLabel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.mismatchRole != curr.mismatchRole,
          listener: (context, state) {
            if (state.mismatchRole != null) {
              context.read<AuthCubit>().clearMismatch();
              _showRoleMismatch(state.mismatchRole);
              return;
            }
            if (state.status == AuthStatus.authenticated) {
              AppFeedback.successToast(
                context,
                context.copy('Login successful.', 'Connexion réussie.'),
              );
            }
            // Sign-in / sign-up errors are handled inline by _submit with
            // tailored guidance, so no generic error toast is shown here.
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: NeuIconButton(
                      icon: AppIcons.back,
                      onTap: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SpinningCube(
                        size: 76,
                        icon: _agencyOnly
                            ? AppIcons.agency
                            : _isCreate
                                ? switch (widget.role ?? UserRole.seeker) {
                                    UserRole.host => AppIcons.agency,
                                    UserRole.partner => AppIcons.partner,
                                    UserRole.seeker => AppIcons.seeker,
                                  }
                                : AppIcons.tour3d,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 40),
                    child: TypingText(
                      _agencyOnly
                          ? 'Agency sign in'
                          : _isCreate
                              ? 'Create your account'
                              : 'Welcome back',
                      style: theme.textTheme.headlineMedium,
                      startDelay: const Duration(milliseconds: 220),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 90),
                    child: Text(
                      _agencyOnly
                          ? 'Agency accounts are created by Nesty. Sign in with the credentials we gave you.'
                          : _isCreate
                              ? 'You\'re joining as ${(widget.role ?? UserRole.seeker).shortLabel.toLowerCase()}.'
                              : 'Good to see you again.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (!_agencyOnly) ...[
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: _isCreate
                        ? Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
                            ),
                            child: NeuField(
                              controller: _name,
                              placeholder: 'Full name',
                              icon: AppIcons.profile,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  NeuField(
                    controller: _email,
                    placeholder: 'Email',
                    icon: AppIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  NeuField(
                    controller: _password,
                    placeholder: 'Password',
                    icon: AppIcons.lock,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.password],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: _isCreate && _password.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: _PasswordStrength(
                              score: _passwordScore(_password.text),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: NeuButton(
                      label: _isCreate ? 'Create account' : 'Continue',
                      loading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                  if (!_isCreate) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: () => _forgot(context),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.secondaryLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!_agencyOnly) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: () => _setMode(_isCreate ? 0 : 1),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppColors.secondaryLabel,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: _isCreate
                                    ? 'Already have an account?  '
                                    : 'New to Nesty?  ',
                              ),
                              TextSpan(
                                text: _isCreate ? 'Sign in' : 'Create account',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!_agencyOnly) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: AppColors.separator)),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'or',
                            style: TextStyle(color: AppColors.tertiaryLabel),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.separator)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GoogleButton(
                      loading: state.isSubmitting,
                      onTap: () => _social(context, 'google'),
                    ),
                    if (!kIsWeb && Platform.isIOS) ...[
                      const SizedBox(height: AppSpacing.md),
                      NeuButton(
                        label: 'Continue with Apple',
                        filled: false,
                        icon: Icons.apple,
                        onPressed: () => _social(context, 'apple'),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _social(BuildContext context, String provider) async {
    // Scope the OAuth sign-in to the space it was launched from, so an account
    // can only enter its own role. The universal "Sign in" entry (no role)
    // passes null and accepts any account.
    final error = await context.read<AuthCubit>().signInWithProvider(
          provider,
          expectedRole: widget.role,
        );
    if (error != null && context.mounted) {
      final e = error.toLowerCase();
      final notEnabled = e.contains('not enabled') ||
          e.contains('unsupported provider') ||
          e.contains('validation_failed') ||
          e.contains('provider is not enabled');
      final label = '${provider[0].toUpperCase()}${provider.substring(1)}';
      AppFeedback.errorToast(
        context,
        notEnabled
            ? '$label sign-in isn\'t enabled on the server yet. '
                'Ask an admin to turn on the $label provider in Supabase.'
            : error,
      );
    }
  }

  void _forgot(BuildContext context) {
    final controller = TextEditingController(text: _email.text.trim());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We\'ll email you a secure link to set a new password.',
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            NeuField(
              controller: controller,
              placeholder: 'Email',
              icon: AppIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.lg),
            NeuButton(
              label: 'Send reset link',
              onPressed: () async {
                final email = controller.text.trim();
                final emailOk = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(email);
                if (!emailOk) {
                  AppFeedback.error(sheetContext, 'Enter a valid email.');
                  return;
                }
                Navigator.of(sheetContext).pop();
                final error =
                    await context.read<AuthCubit>().sendPasswordReset(email);
                if (!context.mounted) return;
                if (error == null) {
                  AppFeedback.success(
                    context,
                    'Reset link sent — check your email.',
                  );
                } else {
                  AppFeedback.error(context, error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact password-strength meter: four bars that fill and a live label,
/// shown only while creating an account.
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.score});
  final int score; // 0..4

  @override
  Widget build(BuildContext context) {
    const labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final clamped = score.clamp(0, 4);
    final active = score <= 1
        ? AppColors.danger
        : score == 2
            ? AppColors.secondaryLabel
            : AppColors.accent;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < clamped ? active : AppColors.fill,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i != 3) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          labels[clamped],
          style: TextStyle(
            color: active,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// "Continue with Google" — an outlined button with the recognisable multi-tone
/// "G" mark (the one splash of colour we allow, for trust/recognition).
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, this.loading = false});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: loading ? null : onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.separator, width: 1.4),
          ),
          child: loading
              ? const ThreeDotLoader(color: AppColors.label, size: 9)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _GoogleGlyph(size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Continue with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The Google "G" drawn with its four brand colours.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stroke = w * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      w - stroke,
      w - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four arcs in Google's brand colours (blue, green, yellow, red).
    void arc(double startDeg, double sweepDeg, Color color) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDeg * 3.1415926 / 180,
        sweepDeg * 3.1415926 / 180,
        false,
        paint,
      );
    }

    arc(-20, 80, const Color(0xFF4285F4)); // blue (right)
    arc(60, 90, const Color(0xFF34A853)); // green (bottom)
    arc(150, 70, const Color(0xFFFBBC05)); // yellow (left)
    arc(220, 70, const Color(0xFFEA4335)); // red (top-left)

    // The blue horizontal bar of the G.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.52, w * 0.4, w * 0.46, stroke),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
