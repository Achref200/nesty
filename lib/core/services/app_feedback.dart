import 'package:flutter/material.dart';

import '../branding/app_icons.dart';
import '../theme/app_colors.dart';

/// One place for lightweight user feedback — floating snackbars for success,
/// error and info. Keeps messaging consistent across the whole app.
abstract final class AppFeedback {
  /// App-wide messenger so snackbars survive navigation (e.g. a login success
  /// that immediately redirects away from the auth page still shows).
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const Color _successGreen = Color(0xFF1E8E5A);
  static const Color _errorRed = Color(0xFFB23A34);

  static void success(BuildContext context, String message) =>
      _show(context, message, AppIcons.check);

  static void error(BuildContext context, String message) =>
      _show(context, message, Icons.error_outline_rounded, danger: true);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppIcons.bell);

    static void comingSoon(BuildContext context) =>
      info(context, 'Coming soon.');

  /// A vivid green success snackbar — for moments worth celebrating (sign-in).
  static void successToast(BuildContext context, String message) => _show(
        context,
        message,
        AppIcons.check,
        background: _successGreen,
      );

  /// A vivid red error snackbar — for clear failures (sign-in failed).
  static void errorToast(BuildContext context, String message) => _show(
        context,
        message,
        Icons.error_outline_rounded,
        background: _errorRed,
      );

  static void _show(
    BuildContext context,
    String message,
    IconData icon, {
    bool danger = false,
    Color? background,
  }) {
    final messenger =
        messengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final iconColor = background != null
        ? AppColors.onAccent
        : (danger ? const Color(0xFFF08A84) : AppColors.onAccent);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
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
        backgroundColor: background ?? AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
