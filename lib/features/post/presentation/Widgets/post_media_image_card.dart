import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_spacing.dart';

class PostMediaImageCard extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final double maxHeightFactor;

  const PostMediaImageCard({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.maxHeightFactor = 0.56,
  });

  @override
  State<PostMediaImageCard> createState() => _PostMediaImageCardState();
}

class _PostMediaImageCardState extends State<PostMediaImageCard> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant PostMediaImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _removeImageListener();
      _imageSize = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _resolveImage() {
    final imageProvider = CachedNetworkImageProvider(widget.imageUrl);
    final stream = imageProvider.resolve(const ImageConfiguration());
    _imageStream = stream;
    _imageStreamListener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      },
      onError: (_, __) {
        if (!mounted) return;
        setState(() {
          _imageSize = null;
        });
      },
    );
    stream.addListener(_imageStreamListener!);
  }

  void _removeImageListener() {
    final imageStream = _imageStream;
    final listener = _imageStreamListener;
    if (imageStream != null && listener != null) {
      imageStream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final media = _buildImage(context);
    if (widget.onTap == null) {
      return media;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: media,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final maxHeight =
        MediaQuery.of(context).size.height *
        math.max(0.4, math.min(widget.maxHeightFactor, 0.9));

    return
      LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final resolvedAspectRatio =
            _imageSize != null && _imageSize!.height > 0
                ? _imageSize!.width / _imageSize!.height
                : 1;
        final resolvedHeight = width / resolvedAspectRatio;
        final boundedHeight = math.min(resolvedHeight, maxHeight);

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            width: double.infinity,
            height: boundedHeight,
            color: const Color(0xFFF3F4F6),
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: boundedHeight,
              placeholder: (_, __) => const _PostMediaPlaceholder(),
              errorWidget: (_, __, ___) => const _PostMediaError(),
            ),
          ),
        );
      },
    );
  }
}

class _PostMediaPlaceholder extends StatelessWidget {
  const _PostMediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const SizedBox(
        width: AppSpacing.xl,
        height: AppSpacing.xl,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _PostMediaError extends StatelessWidget {
  const _PostMediaError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}
