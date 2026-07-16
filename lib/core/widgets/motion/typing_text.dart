import 'package:flutter/material.dart';

/// A soft "typewriter" text reveal. Characters appear one by one on a gentle
/// cadence with a slow blinking caret — warm and human, never mechanical. Set
/// [startDelay] to let a screen settle before the line begins to type.
class TypingText extends StatefulWidget {
  const TypingText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.speed = const Duration(milliseconds: 42),
    this.startDelay = Duration.zero,
    this.showCaret = true,
    this.onComplete,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration speed;
  final Duration startDelay;
  final bool showCaret;
  final VoidCallback? onComplete;

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  bool _typing = true;
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.startDelay, _tick);
  }

  @override
  void didUpdateWidget(covariant TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      // Restart the reveal cleanly when the line changes.
      _count = 0;
      _typing = true;
      _tick();
    }
  }

  Future<void> _tick() async {
    if (!mounted) return;
    if (_count >= widget.text.length) {
      setState(() => _typing = false);
      widget.onComplete?.call();
      return;
    }
    setState(() => _count++);
    // Linger a touch longer on sentence breaks for a natural rhythm.
    final ch = widget.text[_count - 1];
    final pause = (ch == '.' || ch == ',' || ch == '\n')
        ? widget.speed * 6
        : widget.speed;
    await Future<void>.delayed(pause);
    _tick();
  }

  @override
  void dispose() {
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final shown = widget.text.substring(0, _count);
    return RichText(
      textAlign: widget.textAlign ?? TextAlign.start,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: shown),
          if (widget.showCaret && _typing)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: FadeTransition(
                opacity: _caret,
                child: Container(
                  width: (style.fontSize ?? 16) * 0.09 + 1.5,
                  height: (style.fontSize ?? 16) * 0.95,
                  margin: const EdgeInsets.only(left: 2),
                  color: style.color ?? Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
