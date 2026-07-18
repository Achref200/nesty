import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/config/ai_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ios/liquid_glass.dart';
import 'assistant_sheet.dart';

/// A small floating "spark" button that opens the assistant from anywhere.
///
/// Built from the shared [LiquidGlass] material so it belongs to the same
/// floating chrome as the tab bar — a blurred, rim-lit dark-glass orb that
/// expands the full assistant on tap. Pass a [contextNote] / [suggestions] so
/// the assistant already knows the screen the user is on.
class AssistantLauncher extends StatelessWidget {
  const AssistantLauncher({
    super.key,
    this.contextNote = '',
    this.suggestions = const [
      'Find a place that fits my budget',
      'Help me plan a visit',
      'What should I check before renting?',
    ],
    this.subtitle = 'Here to help, wherever you are',
    this.size = 56,
  });

  final String contextNote;
  final List<String> suggestions;
  final String subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!AiConfig.enabled) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showAssistant(
          context,
          contextNote: contextNote,
          suggestions: suggestions,
          subtitle: subtitle,
        );
      },
      child: LiquidGlass.circle(
        dark: true,
        blur: 24,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              AppIcons.assistant,
              color: AppColors.white,
              size: size * 0.42,
            ),
          ),
        ),
      ),
    );
  }
}
