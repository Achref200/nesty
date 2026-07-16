import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'neu_surface.dart';

/// A Material [TextField] wrapped in a soft recessed surface. Keeps the Nestly
/// look while giving the native Material cursor, selection handles and an
/// optional clear button.
class NeuField extends StatefulWidget {
  const NeuField({
    super.key,
    required this.placeholder,
    this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final String placeholder;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<NeuField> createState() => _NeuFieldState();
}

class _NeuFieldState extends State<NeuField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      pressed: true,
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        cursorColor: AppColors.accent,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          hintText: widget.placeholder,
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon, color: AppColors.textSecondary, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: widget.obscureText
              ? IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                )
              : null,
        ),
      ),
    );
  }
}
