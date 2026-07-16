import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// An Airbnb-style animated headline word: the live word sits in ink with a
/// soft offset shadow in a warm brick red behind it (a duotone), and the words
/// swap on a gentle cadence with a rise-and-fade. Elegant, playful, alive.
class ShadowWords extends StatefulWidget {
  const ShadowWords({
    super.key,
    required this.words,
    required this.style,
    this.shadowColor = AppColors.danger,
    this.interval = const Duration(milliseconds: 2200),
  });

  final List<String> words;
  final TextStyle style;
  final Color shadowColor;
  final Duration interval;

  @override
  State<ShadowWords> createState() => _ShadowWordsState();
}

class _ShadowWordsState extends State<ShadowWords> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.words.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(anim);
        return ClipRect(
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
      child: _Duotone(
        key: ValueKey(_index),
        word: widget.words[_index],
        style: widget.style,
        shadow: widget.shadowColor,
      ),
    );
  }
}

class _Duotone extends StatelessWidget {
  const _Duotone({
    super.key,
    required this.word,
    required this.style,
    required this.shadow,
  });

  final String word;
  final TextStyle style;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(2.5, 3),
          child: Text(word, style: style.copyWith(color: shadow)),
        ),
        Text(word, style: style.copyWith(color: AppColors.ink)),
      ],
    );
  }
}
