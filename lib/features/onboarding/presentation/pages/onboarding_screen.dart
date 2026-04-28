import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<VideoPlayerController> _videoControllers;
  late List<Future<void>> _initializeVideoFutures;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      videoUrl:
          'https://ik.imagekit.io/0ws5wi9ww/videos/WhatsApp%20Video%202026-01-25%20at%2023.17.33.mp4',
      title: 'onboarding.welcome_title',
      description:
          'onboarding.welcome_desc',
    ),
    _OnboardingPageData(
      videoUrl:
          'https://ik.imagekit.io/0ws5wi9ww/videos/WhatsApp%20Video%202026-01-25%20at%2023.18.19.mp4',
      title: 'onboarding.find_home_title',
      description:
          'onboarding.find_home_desc',
    ),
    _OnboardingPageData(
      videoUrl:
          'https://ik.imagekit.io/0ws5wi9ww/videos/WhatsApp%20Video%202026-01-25%20at%2023.18.49.mp4',
      title: 'onboarding.search_title',
      description:
          'onboarding.search_desc',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  void _initializeVideos() {
    _videoControllers = _pages.map((page) {
      return VideoPlayerController.networkUrl(Uri.parse(page.videoUrl));
    }).toList();

    _initializeVideoFutures = _videoControllers.map((controller) {
      return controller.initialize().then((_) {
        controller.setLooping(true);
        controller.setVolume(0);
      });
    }).toList();

    _initializeVideoFutures[0].then((_) {
      if (mounted) _videoControllers[0].play();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      for (final controller in _videoControllers) {
        controller.pause();
      }
      _videoControllers[page].play();
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await AppStorage.setFirstTimeUser(false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _OnboardingPage(
                data: _pages[index],
                videoController: _videoControllers[index],
                initializeFuture: _initializeVideoFutures[index],
              );
            },
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'onboarding.skip'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 30 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'onboarding.get_started'.tr()
                            : 'onboarding.next'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final VideoPlayerController videoController;
  final Future<void> initializeFuture;

  const _OnboardingPage({
    required this.data,
    required this.videoController,
    required this.initializeFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder(
          future: initializeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: videoController.value.size.width,
                  height: videoController.value.size.height,
                  child: VideoPlayer(videoController),
                ),
              );
            }
            return const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          },
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.3, 0.6, 1.0],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  data.title.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  data.description.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  final String videoUrl;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.videoUrl,
    required this.title,
    required this.description,
  });
}
