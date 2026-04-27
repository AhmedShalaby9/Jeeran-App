import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/news.dart';

class NewsDetailsPage extends StatefulWidget {
  final News news;
  const NewsDetailsPage({super.key, required this.news});

  @override
  State<NewsDetailsPage> createState() => _NewsDetailsPageState();
}

class _NewsDetailsPageState extends State<NewsDetailsPage> {
  double _opacity = 0.0;
  final ScrollController _scrollController = ScrollController();
  final PageController _imageCarouselController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollControllerListener);
  }

  static bool _isVideoUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  static bool _isValidUrl(String url) {
    return url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  List<String> get _imageUrls => widget.news.media
      .where((url) => _isValidUrl(url) && !_isVideoUrl(url))
      .toList();

  @override
  void dispose() {
    _scrollController.dispose();
    _imageCarouselController.dispose();
    super.dispose();
  }

  void _scrollControllerListener() {
    if (mounted) {
      setState(() {
        if (_scrollController.offset < 50.0) {
          _opacity = 0.0;
        } else if (_scrollController.offset > 50.0 &&
            _scrollController.offset < 100.0) {
          _opacity = 0.4;
        } else if (_scrollController.offset > 100.0 &&
            _scrollController.offset < 150.0) {
          _opacity = 0.8;
        } else if (_scrollController.offset > 190.0) {
          _opacity = 1.0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.background.withValues(alpha: _opacity),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainMedia(),
                  _buildTitle(),
                  Row(
                    children: [
                      _buildPublishedDate(),
                      const Spacer(),
                      _buildPublishedBy(),
                    ],
                  ),
                  _buildContent(),
                  if (widget.news.media.isNotEmpty) _buildMediaGallery(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            _buildTopBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: AppColors.background.withValues(alpha: _opacity),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _opacity < 0.5
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: _opacity < 0.5 ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          if (_opacity > 0.5)
            Expanded(
              child: Text(
                widget.news.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainMedia() {
    final images = _imageUrls;

    if (images.isEmpty) {
      return SizedBox(
        height: 300,
        width: double.infinity,
        child: _buildAppIconFallback(),
      );
    }

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imageCarouselController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(images[index]),
                child: AppImage.network(
                  images[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppIconFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.article_outlined,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 20, right: 20),
      child: Text(
        widget.news.title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPublishedDate() {
    if (widget.news.publishedAt.isEmpty) {
      return Container();
    }

    final formattedDate = widget.news.publishedAt.length >= 10
        ? widget.news.publishedAt.substring(0, 10)
        : widget.news.publishedAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            size: 16,
            color: AppColors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedBy() {
    if (widget.news.publishedBy.isEmpty) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        widget.news.publishedBy,
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.news.content.isEmpty) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        widget.news.content,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
          height: 2,
        ),
      ),
    );
  }

  Widget _buildMediaGallery() {
    final allMedia =
        widget.news.media.where((url) => _isValidUrl(url)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text(
            'news.gallery'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
            ),
            itemCount: allMedia.length,
            itemBuilder: (context, index) {
              final url = allMedia[index];
              if (_isVideoUrl(url)) {
                return _buildVideoGalleryThumbnail(url);
              }
              return _buildImageGalleryThumbnail(url);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoGalleryThumbnail(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenVideo(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black87),
            Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGalleryThumbnail(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AppImage.network(
          url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: AppImage.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenVideo(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenVideoPage(url: url),
      ),
    );
  }
}

class _FullScreenVideoPage extends StatefulWidget {
  final String url;
  const _FullScreenVideoPage({required this.url});

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  late VideoPlayerController _controller;
  late Future<void> _initFuture;
  bool _showControls = true;
  bool _isMuted = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initFuture = _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.play();
      if (mounted) {
        setState(() {});
        _startHideTimer();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTapScreen() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
    _startHideTimer();
  }

  void _rewind() {
    final newPos = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
    _startHideTimer();
  }

  void _forward() {
    final newPos = _controller.value.position + const Duration(seconds: 10);
    final duration = _controller.value.duration;
    _controller.seekTo(newPos > duration ? duration : newPos);
    _startHideTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
    _startHideTimer();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTapScreen,
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Column(
                      children: [
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (_, value, _) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CtrlBtn(
                                icon: Icons.replay_10,
                                size: 36,
                                onTap: _rewind,
                              ),
                              const SizedBox(width: 32),
                              _CtrlBtn(
                                icon: value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                onTap: _togglePlay,
                              ),
                              const SizedBox(width: 32),
                              _CtrlBtn(
                                icon: Icons.forward_10,
                                size: 36,
                                onTap: _forward,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _controller,
                              builder: (_, value, _) {
                                final pos = value.position;
                                final dur = value.duration;
                                final maxMs = dur.inMilliseconds.toDouble();
                                final curMs = pos.inMilliseconds
                                    .toDouble()
                                    .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 6),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 12),
                                        trackHeight: 3,
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white38,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.white24,
                                      ),
                                      child: Slider(
                                        value: curMs,
                                        min: 0,
                                        max: maxMs > 0 ? maxMs : 1.0,
                                        onChangeStart: (_) =>
                                            _hideTimer?.cancel(),
                                        onChanged: (v) {
                                          _controller.seekTo(
                                            Duration(milliseconds: v.toInt()),
                                          );
                                        },
                                        onChangeEnd: (_) => _startHideTimer(),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            _fmt(pos),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _fmt(dur),
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: _toggleMute,
                                            child: Icon(
                                              _isMuted
                                                  ? Icons.volume_off
                                                  : Icons.volume_up,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _CtrlBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
