import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_route_observer.dart';

class PostNetworkVideoPlayer extends StatefulWidget {
  final String url;

  const PostNetworkVideoPlayer({super.key, required this.url});

  @override
  State<PostNetworkVideoPlayer> createState() => _PostNetworkVideoPlayerState();
}

class _PostNetworkVideoPlayerState extends State<PostNetworkVideoPlayer>
    with WidgetsBindingObserver, RouteAware {
  VideoPlayerController? _controller;
  late final Future<void> _initializeVideoFuture;
  bool _showControls = true;
  bool _hasError = false;
  ModalRoute<dynamic>? _route;
  bool _isTickerModeEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final parsedUri = Uri.tryParse(widget.url.trim());
    if (parsedUri == null ||
        (!parsedUri.hasScheme && !widget.url.startsWith('/'))) {
      _hasError = true;
      _initializeVideoFuture = Future.value();
      return;
    }

    final controller = VideoPlayerController.networkUrl(parsedUri);
    _controller = controller;
    _initializeVideoFuture = controller
        .initialize()
        .then((_) async {
          await controller.setLooping(false);
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
          });
        });

    controller.addListener(_handleVideoStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerModeEnabled = TickerMode.of(context);
    if (_isTickerModeEnabled && !tickerModeEnabled) {
      _pausePlayback();
    }
    _isTickerModeEnabled = tickerModeEnabled;

    final route = ModalRoute.of(context);
    if (route == null || route == _route) {
      return;
    }

    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }

    _route = route;
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _pausePlayback();
    _controller
      ?..removeListener(_handleVideoStateChanged)
      ..dispose();
    super.dispose();
  }

  void _handleVideoStateChanged() {
    final controller = _controller;
    if (controller == null) return;
    if (!mounted) return;
    if (controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void didPushNext() {
    _pausePlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _pausePlayback();
    }
  }

  void _pausePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {
      _showControls = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        color: Colors.black,
        child: FutureBuilder<void>(
          future: _initializeVideoFuture,
          builder: (context, snapshot) {
            final controller = _controller;
            if (_hasError || snapshot.hasError || controller == null) {
              return _buildErrorState(context);
            }

            if (snapshot.connectionState != ConnectionState.done ||
                !controller.value.isInitialized) {
              return _buildLoadingState();
            }

            final aspectRatio =
                controller.value.aspectRatio > 0
                    ? controller.value.aspectRatio
                    : (16 / 9);

            return AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                    child: VideoPlayer(controller),
                  ),
                  if (_showControls || !controller.value.isPlaying)
                    Container(
                      color: Colors.black.withValues(alpha: 0.18),
                      alignment: Alignment.center,
                      child: IconButton(
                        onPressed: _togglePlayback,
                        iconSize: AppSpacing.xxl + AppSpacing.xl,
                        color: Colors.white,
                        icon: Icon(
                          controller.value.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primaryDark,
                        bufferedColor: Color(0x66FFFFFF),
                        backgroundColor: Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_library_outlined,
                color: Colors.white70,
                size: AppSpacing.xxl + AppSpacing.md,
              ),
              AppSpacing.vSm,
              Text(
                AppStrings.unableToLoadVideo,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
