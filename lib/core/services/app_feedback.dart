import 'package:flutter/material.dart';

import '../branding/app_icons.dart';
import '../theme/app_colors.dart';

/// One place for lightweight user feedback — monochrome floating snackbars for
/// success, error and info. Keeps messaging consistent across the whole app.
abstract final class AppFeedback {
  static void success(BuildContext context, String message) =>
      _show(context, message, AppIcons.check);

  static void error(BuildContext context, String message) =>
      _show(context, message, Icons.error_outline_rounded, danger: true);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppIcons.bell);

  static void _show(
    BuildContext context,
    String message,
    IconData icon, {
    bool danger = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: danger ? const Color(0xFFF08A84) : AppColors.onAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
