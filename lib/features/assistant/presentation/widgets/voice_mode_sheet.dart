import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/assistant_cubit.dart';
import '../cubit/assistant_state.dart';

/// Opens the immersive, hands-free "Voice Mode" — a ChatGPT-style spoken
/// conversation. It reuses the caller's [cubit], so anything said appears in the
/// same chat thread. The flow is fully hands-free: it listens, auto-sends what
/// you say when you pause, then reads the reply back aloud and listens again.
Future<void> showVoiceMode(
  BuildContext context,
  AssistantCubit cubit, {
  String languageCode = 'en',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.black.withValues(alpha: 0.5),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _VoiceMode(languageCode: languageCode),
    ),
  );
}

enum _Phase { listening, thinking, speaking, paused }

class _VoiceMode extends StatefulWidget {
  const _VoiceMode({required this.languageCode});
  final String languageCode;

  @override
  State<_VoiceMode> createState() => _VoiceModeState();
}

class _VoiceModeState extends State<_VoiceMode> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  _Phase _phase = _Phase.listening;
  bool _ready = false;
  String _transcript = '';
  String? _localeId;
  int _lastSpokenIndex = -1;
  Timer? _restartTimer;

  // Smoothed amplitude (0..1) driving the visualiser.
  double _level = 0;
  double _targetLevel = 0;

  @override
  void initState() {
    super.initState();
    // Don't re-speak a reply that was already on screen before we opened.
    _lastSpokenIndex = context.read<AssistantCubit>().state.messages.length - 1;
    _anim.addListener(_tickLevel);
    _configureTts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _anim
      ..removeListener(_tickLevel)
      ..dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  // ---- Amplitude smoothing (no setState — the visualiser repaints per frame).
  void _tickLevel() {
    _level += (_targetLevel - _level) * 0.22;
    _targetLevel *= 0.90;
  }

  // ---- Text-to-speech ------------------------------------------------------
  Future<void> _configureTts() async {
    try {
      final tag = _ttsLanguageTag(widget.languageCode);
      // Only set the language if the device actually has that voice, otherwise
      // the reply can silently fail to speak — fall back to the engine default.
      final available = await _tts.isLanguageAvailable(tag);
      if (available == true) await _tts.setLanguage(tag);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {}
    _tts.setStartHandler(_onSpeakStart);
    _tts.setCompletionHandler(_onSpeakDone);
    _tts.setCancelHandler(_onSpeakDone);
  }

  void _onSpeakStart() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    if (_phase != _Phase.speaking) setState(() => _phase = _Phase.speaking);
  }

  String _ttsLanguageTag(String code) => switch (code) {
    'fr' => 'fr-FR',
    'ar' => 'ar',
    _ => 'en-US',
  };

  Future<void> _speak(String text) async {
    if (!mounted) return;
    setState(() => _phase = _Phase.speaking);
    HapticFeedback.selectionClick();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      _onSpeakDone();
    }
  }

  void _onSpeakDone() {
    if (!mounted) return;
    // Continuous conversation: after reading the reply, listen for the follow-up.
    if (_phase == _Phase.speaking) _startListening();
  }

  // ---- Speech-to-text ------------------------------------------------------
  Future<void> _boot() async {
    try {
      _ready = await _speech.initialize(
        onStatus: _onSttStatus,
        onError: _onSttError,
      );
    } catch (_) {
      _ready = false;
    }
    if (!_ready) {
      _fail(
        'Voice input isn\u2019t available. Check the microphone permission.',
      );
      return;
    }
    _localeId = await _resolveLocale(widget.languageCode);
    _startListening();
  }

  Future<String?> _resolveLocale(String language) async {
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(language.toLowerCase())) {
          return l.localeId;
        }
      }
    } catch (_) {}
    return null;
  }

  void _startListening() {
    if (!mounted || !_ready || _phase == _Phase.paused) return;
    _transcript = '';
    _targetLevel = 0;
    _level = 0;
    setState(() => _phase = _Phase.listening);
    HapticFeedback.lightImpact();
    _speech.listen(
      onResult: _onSttResult,
      onSoundLevelChange: _onLevel,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        localeId: _localeId,
      ),
    );
  }

  void _onLevel(double level) {
    _targetLevel = math.max(_targetLevel, _normalizeLevel(level));
  }

  /// Maps the platform-specific sound level to 0..1 (iOS reports dB, Android a
  /// small positive scale).
  double _normalizeLevel(double raw) {
    final n = raw <= 0 ? (raw + 50) / 50 : raw / 10;
    return n.clamp(0.0, 1.0);
  }

  void _onSttStatus(String status) {
    if ((status == 'done' || status == 'notListening') &&
        _phase == _Phase.listening) {
      _submit();
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    if (_phase == _Phase.listening) _scheduleRestart();
  }

  void _onSttResult(SpeechRecognitionResult result) {
    setState(() => _transcript = result.recognizedWords);
    if (result.finalResult) _submit();
  }

  /// Auto-send: fired when the recogniser detects the end of speech.
  void _submit() {
    if (_phase != _Phase.listening) return;
    final text = _transcript.trim();
    _speech.stop();
    if (text.isEmpty) {
      _scheduleRestart();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.thinking;
      _targetLevel = 0;
      _level = 0;
    });
    context.read<AssistantCubit>().send(text);
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _phase == _Phase.listening) _startListening();
    });
  }

  // ---- Reacting to the assistant's replies ---------------------------------
  void _onState(AssistantState state) {
    if (state.isTyping) return;
    if (_phase == _Phase.thinking && state.hasError) {
      _startListening();
      return;
    }
    final msgs = state.messages;
    if (msgs.isEmpty) return;
    final lastIndex = msgs.length - 1;
    final last = msgs[lastIndex];
    if (last.isAssistant && lastIndex > _lastSpokenIndex) {
      _lastSpokenIndex = lastIndex;
      _speak(last.text);
    }
  }

  // ---- Controls ------------------------------------------------------------
  void _tapOrb() {
    switch (_phase) {
      case _Phase.speaking:
        _tts.stop(); // barge-in: interrupt and talk
        _startListening();
      case _Phase.listening:
        _submit();
      case _Phase.thinking:
      case _Phase.paused:
        break;
    }
  }

  void _togglePause() {
    if (_phase == _Phase.paused) {
      _startListening();
    } else {
      _restartTimer?.cancel();
      _speech.stop();
      _tts.stop();
      HapticFeedback.mediumImpact();
      setState(() => _phase = _Phase.paused);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _close() async {
    await _speech.stop();
    await _tts.stop();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssistantCubit, AssistantState>(
      listenWhen: (a, b) =>
          a.messages.length != b.messages.length ||
          a.isTyping != b.isTyping ||
          a.error != b.error,
      listener: (_, state) => _onState(state),
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final paused = _phase == _Phase.paused;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.9),
              border: const Border(
                top: BorderSide(color: AppColors.white, width: 0.8),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 52),
                        const Spacer(),
                        Text('Voice mode', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        _CircleControl(icon: AppIcons.close, onTap: _close),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _tapOrb,
                    behavior: HitTestBehavior.opaque,
                    child: _VoiceVisualizer(
                      animation: _anim,
                      levelOf: () => _level,
                      phase: _phase,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _StatusLine(phase: _phase, transcript: _transcript),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: _CircleControl(
                      icon: paused ? AppIcons.micOff : AppIcons.mic,
                      label: paused ? 'Paused — tap to talk' : 'Tap to pause',
                      filled: paused,
                      size: 60,
                      onTap: _togglePause,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The status label + the live transcription while listening.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.phase, required this.transcript});
  final _Phase phase;
  final String transcript;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (phase) {
      _Phase.listening => 'Listening\u2026',
      _Phase.thinking => 'Thinking\u2026',
      _Phase.speaking => 'Speaking\u2026',
      _Phase.paused => 'Paused',
    };
    final showTranscript =
        phase == _Phase.listening && transcript.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.secondaryLabel,
            ),
          ),
          if (showTranscript) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              transcript,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
          ],
        ],
      ),
    );
  }
}

/// The audio-reactive orb: a monochrome ink core wrapped in a radial frequency
/// halo and expanding rings. It reacts to the mic amplitude while listening and
/// animates on its own while the assistant speaks.
class _VoiceVisualizer extends StatelessWidget {
  const _VoiceVisualizer({
    required this.animation,
    required this.levelOf,
    required this.phase,
  });

  final Animation<double> animation;
  final ValueGetter<double> levelOf;
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _OrbPainter(
            t: animation.value,
            level: levelOf(),
            phase: phase,
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.level, required this.phase});
  final double t; // 0..1 repeating
  final double level; // 0..1 smoothed amplitude
  final _Phase phase;

  static const double _twoPi = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Effective amplitude per phase.
    final double amp = switch (phase) {
      _Phase.listening => level,
      _Phase.thinking => 0.10 + 0.05 * math.sin(t * _twoPi * 2),
      _Phase.speaking => 0.32 + 0.30 * (0.5 + 0.5 * math.sin(t * _twoPi * 2.2)),
      _Phase.paused => 0.0,
    };

    final baseR = 46.0;
    final orbR = baseR * (1 + 0.18 * amp) + 2 * math.sin(t * _twoPi);

    // Expanding rings.
    for (var i = 0; i < 3; i++) {
      final rt = (t + i / 3) % 1.0;
      final r = orbR + rt * (118 - orbR);
      final op = ((1 - rt) * (0.10 + 0.16 * amp)).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = AppColors.ink.withValues(alpha: op),
      );
    }

    // Radial frequency bars.
    const barCount = 64;
    final innerR = orbR + 12;
    final barPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    for (var i = 0; i < barCount; i++) {
      final ang = _twoPi * i / barCount;
      final wave = 0.5 + 0.5 * math.sin(t * _twoPi * 1.6 + i * 0.5);
      final len = 6 + 36 * (0.25 + 0.75 * amp) * wave;
      final dir = Offset(math.cos(ang), math.sin(ang));
      barPaint.color = AppColors.ink.withValues(
        alpha: (0.16 + 0.55 * amp * wave).clamp(0.0, 1.0),
      );
      canvas.drawLine(
        center + dir * innerR,
        center + dir * (innerR + len),
        barPaint,
      );
    }

    // Soft ambient glow.
    canvas.drawCircle(
      center,
      orbR,
      Paint()
        ..color = AppColors.ink.withValues(
          alpha: (0.16 + 0.22 * amp).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    // The ink core.
    final orbRect = Rect.fromCircle(center: center, radius: orbR);
    canvas.drawCircle(
      center,
      orbR,
      Paint()
        ..shader = const RadialGradient(
          colors: [AppColors.inkSoft, AppColors.ink],
        ).createShader(orbRect),
    );

    // Rim highlight.
    canvas.drawCircle(
      center,
      orbR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.t != t || old.level != level || old.phase != phase;
}

/// A circular control used for close / pause, with an optional caption.
class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.icon,
    required this.onTap,
    this.label,
    this.filled = false,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: filled ? AppColors.accent : AppColors.fill,
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(color: AppColors.separator, width: 0.5),
            ),
            child: Icon(
              icon,
              color: filled ? AppColors.onAccent : AppColors.ink,
              size: size * 0.42,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(label!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
