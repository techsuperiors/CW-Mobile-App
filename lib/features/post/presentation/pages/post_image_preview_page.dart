import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../domain/entities/announcement_entity.dart';
import '../Widgets/post_media_image_card.dart';

class PostImagePreviewPage extends StatelessWidget {
  final List<MediaItemEntity> images;
  final int initialIndex;

  const PostImagePreviewPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  List<MediaItemEntity> get _orderedImages {
    if (images.length <= 1 ||
        initialIndex < 0 ||
        initialIndex >= images.length) {
      return images;
    }

    return [
      images[initialIndex],
      ...images.where((image) => image != images[initialIndex]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orderedImages = _orderedImages;

    return Scaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size:
                    MediaQuery.of(context).size.width *
                    0.048, // 4.8% of screen width
              ),
              Flexible(
                child: Text(
                  'Back',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.imagePreview,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          itemCount: orderedImages.length,

          separatorBuilder:
              (_, __) => Divider(
            color: AppColors.border, // Light gray
            thickness: 2,
            height: 2,
          ),
          // separatorBuilder: (_, __) => AppSpacing.vMd,
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orderedImages.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      '${index + 1} / ${orderedImages.length}',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.borderLight),
                    ),
                  ),
                PostMediaImageCard(
                  imageUrl: orderedImages[index].url,
                  maxHeightFactor: 0.82,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
