import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';

class AiAdGuidePage extends StatefulWidget {
  final String videoUrl;
  const AiAdGuidePage({super.key, required this.videoUrl});

  static Future<void> push(BuildContext context, String videoUrl) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AiAdGuidePage(videoUrl: videoUrl)),
    );
  }

  @override
  State<AiAdGuidePage> createState() => _AiAdGuidePageState();
}

class _AiAdGuidePageState extends State<AiAdGuidePage> {
  late final VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _ctrl.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await AppStorage.setAiAdGuideViewed(true);
    if (mounted) Navigator.pop(context);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video or state placeholder ──────────────────────────
              Center(
                child: _hasError
                    ? const Text(
                        'Could not load video.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      )
                    : !_initialized
                        ? const CircularProgressIndicator(color: Colors.white)
                        : AspectRatio(
                            aspectRatio: _ctrl.value.aspectRatio,
                            child: VideoPlayer(_ctrl),
                          ),
              ),

              // ── Skip button ─────────────────────────────────────────
              Positioned(
                top: 12,
                right: 16,
                child: TextButton(
                  onPressed: _done,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Skip', style: TextStyle(fontSize: 14)),
                ),
              ),

              // ── Controls bar (only when initialized) ────────────────
              if (_initialized)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _ctrl,
                    builder: (_, value, __) {
                      final position = value.position;
                      final duration = value.duration;
                      final finished = duration > Duration.zero &&
                          position >= duration;
                      final maxMs = duration.inMilliseconds
                          .toDouble()
                          .clamp(1.0, double.infinity);
                      final posMs = position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, maxMs);

                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // "Got it" button when finished
                            if (finished) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                                child: ElevatedButton(
                                  onPressed: _done,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Got it — Let's Create My Ad",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],

                            // Progress row: [play/pause] [time] [slider] [duration]
                            Row(
                              children: [
                                // Play / Pause
                                IconButton(
                                  icon: Icon(
                                    finished
                                        ? Icons.replay_rounded
                                        : value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    if (finished) {
                                      _ctrl.seekTo(Duration.zero);
                                      _ctrl.play();
                                    } else {
                                      value.isPlaying
                                          ? _ctrl.pause()
                                          : _ctrl.play();
                                    }
                                  },
                                ),

                                // Current position
                                Text(
                                  _fmt(position),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),

                                // Seek slider
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor:
                                          Colors.white30,
                                      thumbColor: Colors.white,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                              enabledThumbRadius: 6),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 12),
                                      trackHeight: 3,
                                    ),
                                    child: Slider(
                                      value: posMs,
                                      min: 0,
                                      max: maxMs,
                                      onChanged: (v) => _ctrl.seekTo(
                                          Duration(
                                              milliseconds: v.toInt())),
                                    ),
                                  ),
                                ),

                                // Total duration
                                Text(
                                  _fmt(duration),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),

                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
