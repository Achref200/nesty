import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/typing_text.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../../core/widgets/neu/neu_icon_button.dart';
import '../../../onboarding/presentation/widgets/spinning_cube.dart';
import '../../domain/entities/user_role.dart';
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
    if (_isCreate && _name.text.trim().isEmpty) return 'Enter your name.';
    final emailOk = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_email.text.trim());
    if (!emailOk) return 'Enter a valid email.';
    if (_isCreate) {
      if (_password.text.length < 8) {
        return 'Use at least 8 characters.';
      }
      if (_passwordScore(_password.text) < 2) {
        return 'Add a number or a capital letter to strengthen your password.';
      }
    } else if (_password.text.length < 6) {
      return 'Password needs 6+ characters.';
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

  void _submit() {
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
      cubit.signUp(
        _name.text,
        _email.text,
        _password.text,
        widget.role ?? UserRole.seeker,
      );
    } else {
      cubit.signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.errorMessage != null &&
                state.status == AuthStatus.unauthenticated) {
              setState(() => _error = state.errorMessage);
            }
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
                                ? ((widget.role ?? UserRole.seeker) ==
                                          UserRole.host
                                      ? AppIcons.agency
                                      : AppIcons.seeker)
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
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('Sign in')),
                            ButtonSegment(value: 1, label: Text('Create')),
                          ],
                          selected: {_mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => _setMode(s.first),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? AppColors.accent
                                  : AppColors.fill,
                            ),
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? AppColors.onAccent
                                  : AppColors.label,
                            ),
                            side: WidgetStateProperty.all(BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                  const SizedBox(height: AppSpacing.lg),
                  if (!_agencyOnly) ...[
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
                    NeuButton(
                      label: 'Continue with Google',
                      filled: false,
                      onPressed: () => _social(context, 'google'),
                    ),
                    if (!kIsWeb && Platform.isIOS) ...[
                      const SizedBox(height: AppSpacing.md),
                      NeuButton(
                        label: 'Continue with Apple',
                        filled: false,
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
    final error = await context.read<AuthCubit>().signInWithProvider(provider);
    if (error != null && context.mounted) {
      AppFeedback.error(context, error);
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
