import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_icon_button.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../cubit/assistant_cubit.dart';
import '../cubit/assistant_state.dart';
import '../utils/assistant_brain.dart';
import 'voice_mode_sheet.dart';

/// Opens the assistant as a floating, blurred modal — the one surface reused
/// everywhere. [contextNote] tells the assistant what the user is looking at,
/// [autoAsk] optionally sends an opening question, and [suggestions] are the
/// tappable starter prompts shown on the empty state.
Future<void> showAssistant(
  BuildContext context, {
  String contextNote = '',
  String? autoAsk,
  List<String> suggestions = const [],
  String subtitle = 'Here to help, wherever you are',
}) {
  final languageCode = Localizations.localeOf(context).languageCode;
  final userName = sl<AuthCubit>().state.user?.displayName;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.black.withValues(alpha: 0.32),
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = AssistantCubit(
          sl<SendMessageUseCase>(),
          userName: userName,
          languageCode: languageCode,
          contextNote: contextNote,
        );
        if (autoAsk != null && autoAsk.trim().isNotEmpty) cubit.send(autoAsk);
        return cubit;
      },
      child: _AssistantSheet(
        subtitle: subtitle,
        suggestions: suggestions,
        languageCode: languageCode,
      ),
    ),
  );
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet({
    required this.subtitle,
    required this.suggestions,
    required this.languageCode,
  });

  final String subtitle;
  final List<String> suggestions;
  final String languageCode;

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    context.read<AssistantCubit>().send(value);
    _scrollToEnd();
  }

  /// Opens the immersive, hands-free voice conversation. It shares this sheet's
  /// [AssistantCubit], so anything said there lands in the same thread.
  Future<void> _openVoice() async {
    HapticFeedback.selectionClick();
    await showVoiceMode(
      context,
      context.read<AssistantCubit>(),
      languageCode: widget.languageCode,
    );
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 260,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.9;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.86),
              border: const Border(
                top: BorderSide(color: AppColors.white, width: 0.8),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryLabel,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                _Header(subtitle: widget.subtitle),
                const Divider(height: 1),
                Expanded(
                  child: BlocConsumer<AssistantCubit, AssistantState>(
                    listenWhen: (a, b) =>
                        a.messages.length != b.messages.length ||
                        a.isTyping != b.isTyping,
                    listener: (_, _) => _scrollToEnd(),
                    builder: (context, state) {
                      if (state.isEmpty && !state.isTyping) {
                        return _Welcome(
                          suggestions: widget.suggestions,
                          onPick: _send,
                        );
                      }
                      return ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        children: [
                          for (final m in state.messages) _Bubble(message: m),
                          if (state.isTyping) const _Typing(),
                          if (state.hasError)
                            _ErrorRow(
                              message: state.error,
                              onRetry: () =>
                                  context.read<AssistantCubit>().retry(),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                _InputBar(
                  controller: _input,
                  onSend: () => _send(),
                  onVoice: _openVoice,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const _Orb(size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AssistantBrain.assistantName,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          NeuIconButton(
            icon: AppIcons.close,
            size: 40,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.suggestions, required this.onPick});
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      children: [
        const Center(child: _Orb(size: 64)),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ask me anything',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Budgets, best-fit places, a listing\u2019s details, planning a visit '
          '\u2014 I\u2019m here for the whole journey.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SuggestionPill(text: s, onTap: () => onPick(s)),
          ),
      ],
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: NeuSurface(
        borderRadius: AppRadius.md,
        depth: 6,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            const Icon(AppIcons.assistant, size: 16, color: AppColors.ink),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
              ),
            ),
            const Icon(
              AppIcons.arrowUpRight,
              size: 16,
              color: AppColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 14.5,
      height: 1.4,
      color: isUser ? AppColors.onAccent : AppColors.label,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _Orb(size: 28),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: isUser
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: SelectableText(message.text, style: textStyle),
                  )
                : NeuSurface(
                    borderRadius: AppRadius.lg,
                    depth: 6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: SelectableText(message.text, style: textStyle),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Orb(size: 28),
          SizedBox(width: AppSpacing.sm),
          NeuSurface(
            borderRadius: AppRadius.lg,
            depth: 6,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            child: SizedBox(width: 34, height: 8, child: _Dots()),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_c.value + i * 0.2) % 1.0;
            final o = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: o),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.paddingOf(context).bottom * 0.4,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14.5),
              decoration: InputDecoration(
                hintText: 'Ask anything\u2026',
                hintStyle: const TextStyle(color: AppColors.tertiaryLabel),
                filled: true,
                fillColor: AppColors.fill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _VoiceButton(onTap: onVoice),
          const SizedBox(width: AppSpacing.sm),
          _RoundIconButton(
            icon: AppIcons.send,
            onTap: () {
              HapticFeedback.selectionClick();
              onSend();
            },
          ),
        ],
      ),
    );
  }
}

/// Opens the immersive, hands-free voice conversation (Voice Mode).
class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.fill,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: const Icon(AppIcons.mic, size: 20, color: AppColors.ink),
      ),
    );
  }
}

/// A solid ink action circle used for the send button.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.onAccent, size: 20),
      ),
    );
  }
}

/// The assistant's identity orb — a quiet monochrome ink gradient with the
/// sparkle glyph, matching the app's strict black / white / grey system.
class _Orb extends StatelessWidget {
  const _Orb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, AppColors.inkSoft],
        ),
      ),
      child: Icon(AppIcons.assistant, size: size * 0.5, color: AppColors.white),
    );
  }
}
