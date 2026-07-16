import 'package:flutter/material.dart';

/// Scroll-driven parallax for an image inside a scrolling list. As the item
/// travels up the viewport, the image drifts in the opposite direction at a
/// fraction of the speed, giving depth. Based on the Flutter parallax recipe.
///
/// Place [ParallaxImage] as the background of a fixed-height clip; the [child]
/// should be a [BoxFit.cover] image sized larger than the visible frame.
class ParallaxImage extends StatelessWidget {
  const ParallaxImage({
    super.key,
    required this.child,
    required this.itemKey,
    this.intensity = 0.30,
  });

  final Widget child;

  /// A key attached to the visible item, used to compute its scroll position.
  final GlobalKey itemKey;

  /// 0 = no movement, 1 = image moves as much as the viewport. Keep it subtle.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    // During a Hero flight (or anywhere outside a scroll view) there is no
    // Scrollable ancestor — fall back to the plain child so we never crash.
    final scrollable = Scrollable.maybeOf(context);
    final itemContext = itemKey.currentContext;
    if (scrollable == null || itemContext == null) {
      return child;
    }
    return Flow(
      clipBehavior: Clip.hardEdge,
      delegate: _ParallaxFlowDelegate(
        scrollable: scrollable,
        itemContext: itemContext,
        intensity: intensity,
      ),
      children: [child],
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.intensity,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final double intensity;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    // Let the background image be taller than the frame so it can slide.
    return BoxConstraints.tightFor(width: constraints.maxWidth);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox?;
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    if (scrollableBox == null || itemBox == null) {
      context.paintChild(0);
      return;
    }

    final itemOffset = itemBox.localToGlobal(
      itemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    final viewportHeight = scrollableBox.size.height;
    final scrollFraction = (itemOffset.dy / viewportHeight).clamp(0.0, 1.0);

    final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);

    final childSize = context.getChildSize(0)!;
    final listItemSize = context.size;
    final childRect = verticalAlignment.inscribe(
      childSize,
      Offset.zero & listItemSize,
    );

    context.paintChild(
      0,
      transform: Transform.translate(
        offset: Offset(0.0, childRect.top * intensity),
      ).transform,
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        itemContext != oldDelegate.itemContext ||
        intensity != oldDelegate.intensity;
  }
}
