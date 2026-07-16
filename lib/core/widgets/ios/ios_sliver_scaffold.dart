import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A [Scaffold] whose body is a [CustomScrollView] fronted by a Material
/// large-title [SliverAppBar]. The title starts large and collapses on scroll,
/// giving screens a modern Material header with an optional refresh and a
/// trailing action.
class IosSliverScaffold extends StatelessWidget {
  const IosSliverScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
    this.onRefresh,
    this.backgroundColor,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.background;

    Widget scrollView = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar.large(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          pinned: true,
          stretch: true,
          actions: trailing == null
              ? null
              : [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: trailing!,
                  ),
                ],
          title: Text(title),
        ),
        ...slivers,
      ],
    );

    if (onRefresh != null) {
      scrollView = RefreshIndicator(
        color: AppColors.accent,
        onRefresh: onRefresh!,
        child: scrollView,
      );
    }

    return Scaffold(backgroundColor: bg, body: scrollView);
  }
}
