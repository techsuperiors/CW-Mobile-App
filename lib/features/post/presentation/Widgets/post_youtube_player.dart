import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/constants/app_text_styles.dart';
import 'package:collectivWork/core/theme/app_theme.dart';
import 'package:collectivWork/core/utils/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostYoutubePlayer extends StatefulWidget {
  final String url;
  final String videoId;

  const PostYoutubePlayer({
    super.key,
    required this.url,
    required this.videoId,
  });

  @override
  State<PostYoutubePlayer> createState() => _PostYoutubePlayerState();
}

class _PostYoutubePlayerState extends State<PostYoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        enableCaption: true,
        forceHD: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openYoutubeLink() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _showOpenLinkError();
      return;
    }

    final openedExternally = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedExternally) return;

    final openedInBrowser = await launchUrl(uri);
    if (openedInBrowser) return;

    _showOpenLinkError();
  }

  void _showOpenLinkError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open this YouTube link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openYoutubeLink,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              widget.url,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        AppSpacing.vMd,
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppTheme.primaryColor,
            progressColors: const ProgressBarColors(
              playedColor: AppColors.primary,
              handleColor: AppColors.primary,
            ),
            bottomActions: const [
              CurrentPosition(),
              SizedBox(width: AppSpacing.sm),
              ProgressBar(isExpanded: true),
              SizedBox(width: AppSpacing.sm),
              PlaybackSpeedButton(),
              FullScreenButton(),
            ],
          ),
        ),
      ],
    );
  }
}
