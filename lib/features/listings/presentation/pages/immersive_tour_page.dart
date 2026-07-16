import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_room.dart';
import '../widgets/panorama_room_view.dart';
import '../widgets/room_360_viewer.dart';

/// A full-screen, cinematic 3D tour — the signature experience of the app.
///
/// It combines a video "walkthrough" chapter with a per-room 360° orbit viewer,
/// switchable from a bottom chapter strip, the way Matterport / Zillow 3D Home
/// let you move between a guided tour and free-look room views.
class ImmersiveTourPage extends StatefulWidget {
  const ImmersiveTourPage({super.key, required this.property});

  final Property property;

  /// Opens the tour with a cinematic fade+scale transition.
  static Future<void> open(BuildContext context, Property property) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => ImmersiveTourPage(property: property),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.06, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ImmersiveTourPage> createState() => _ImmersiveTourPageState();
}

class _ImmersiveTourPageState extends State<ImmersiveTourPage> {
  late final List<_Chapter> _chapters;
  int _selected = 0;

  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final p = widget.property;
    final rooms = p.rooms.where((r) => r.images.isNotEmpty).toList();
    _chapters = [
      if (p.tour3dUrl != null)
        _Chapter.video(thumb: p.coverImage, label: 'Walkthrough'),
      for (final r in rooms)
        _Chapter.room(room: r, thumb: r.images.first, label: r.name),
    ];

    if (p.tour3dUrl != null) _initVideo(p.tour3dUrl!);
  }

  Future<void> _initVideo(String url) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _videoReady = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _select(int i) {
    if (i == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = i);
    final isVideo = _chapters[i].isVideo;
    if (isVideo) {
      _controller?.play();
    } else {
      _controller?.pause();
    }
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _chapters.isEmpty ? null : _chapters[_selected];
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (chapter == null)
            const Center(
              child: Icon(
                Icons.view_in_ar_rounded,
                color: AppColors.white,
                size: 44,
              ),
            )
          else if (chapter.isVideo)
            _VideoStage(
              controller: _controller,
              ready: _videoReady,
              onTap: _togglePlay,
            )
          else if (chapter.room!.hasPanorama)
            PanoramaRoomView(imageUrl: chapter.room!.panoramaUrl!)
          else
            Room360Viewer(images: chapter.room!.images),

          // Top bar.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _TopBar(
              title: widget.property.title,
              subtitle: chapter?.label ?? '',
              showMute: chapter?.isVideo ?? false,
              muted: _muted,
              onClose: () => Navigator.of(context).pop(),
              onToggleMute: _toggleMute,
            ),
          ),

          // Bottom: scrubber (video only) + chapter strip.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomDock(
              chapters: _chapters,
              selected: _selected,
              onSelect: _select,
              scrubber: (chapter?.isVideo ?? false) && _videoReady
                  ? _controller
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Chapter {
  const _Chapter._({
    required this.isVideo,
    required this.thumb,
    required this.label,
    this.room,
  });

  factory _Chapter.video({required String thumb, required String label}) =>
      _Chapter._(isVideo: true, thumb: thumb, label: label);

  factory _Chapter.room({
    required PropertyRoom room,
    required String thumb,
    required String label,
  }) => _Chapter._(isVideo: false, thumb: thumb, label: label, room: room);

  final bool isVideo;
  final String thumb;
  final String label;
  final PropertyRoom? room;
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({
    required this.controller,
    required this.ready,
    required this.onTap,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!ready || controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 2.5,
        ),
      );
    }
    final playing = controller!.value.isPlaying;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          ),
          AnimatedOpacity(
            opacity: playing ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.28),
              child: const Center(
                child: _GlassCircle(
                  size: 74,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.showMute,
    required this.muted,
    required this.onClose,
    required this.onToggleMute,
  });

  final String title;
  final String subtitle;
  final bool showMute;
  final bool muted;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose,
          child: const _GlassCircle(
            size: 40,
            child: Icon(Icons.close_rounded, color: AppColors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (showMute)
          GestureDetector(
            onTap: onToggleMute,
            child: _GlassCircle(
              size: 40,
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.chapters,
    required this.selected,
    required this.onSelect,
    required this.scrubber,
  });

  final List<_Chapter> chapters;
  final int selected;
  final ValueChanged<int> onSelect;
  final VideoPlayerController? scrubber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xB3000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scrubber != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: VideoProgressIndicator(
                  scrubber!,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: VideoProgressColors(
                    playedColor: AppColors.white,
                    bufferedColor: AppColors.white.withValues(alpha: 0.3),
                    backgroundColor: AppColors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chapters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _ChapterThumb(
                chapter: chapters[i],
                active: i == selected,
                onTap: () => onSelect(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterThumb extends StatelessWidget {
  const _ChapterThumb({
    required this.chapter,
    required this.active,
    required this.onTap,
  });

  final _Chapter chapter;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Container(
                width: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.25),
                    width: active ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(chapter.thumb, fit: BoxFit.cover),
                      if (chapter.isVideo)
                        Container(
                          color: AppColors.black.withValues(alpha: 0.25),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: AppColors.white,
                              size: 26,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              chapter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.size, required this.child});
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
      ),
      child: Center(child: child),
    );
  }
}
