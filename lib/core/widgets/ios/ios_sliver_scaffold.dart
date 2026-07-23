import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

import '../../branding/nestly_logo.dart';
import '../../theme/app_colors.dart';
import '../motion/nesty_loader.dart';

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
    this.leading,
    this.onRefresh,
    this.backgroundColor,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Widget? leading;
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
          leading: leading,
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
      scrollView = CustomMaterialIndicator(
        onRefresh: onRefresh!,
        backgroundColor: AppColors.background,
        elevation: 2,
        indicatorBuilder: (context, controller) {
          final loading = controller.isLoading ||
              controller.isComplete ||
              controller.isFinalizing;
          return SizedBox.square(
            dimension: 30,
            child: loading
                ? const NestyLoader(size: 30)
                : NestlyLogo(
                    size: 30,
                    color: AppColors.ink,
                    progress: controller.value.clamp(0.0, 1.0),
                  ),
          );
        },
        child: scrollView,
      );
    }

    return Scaffold(backgroundColor: bg, body: scrollView);
  }
}
