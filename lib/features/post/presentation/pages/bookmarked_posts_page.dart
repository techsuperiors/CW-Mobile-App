import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/utils/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/app_avatar.dart';
import '../../domain/entities/announcement_entity.dart';
import '../bloc/bookmarked_posts_bloc.dart';

class BookmarkedPostsPage extends StatefulWidget {
  const BookmarkedPostsPage({super.key});

  @override
  State<BookmarkedPostsPage> createState() => _BookmarkedPostsPageState();
}

class _BookmarkedPostsPageState extends State<BookmarkedPostsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BookmarkedPostsBloc>().add(const FetchBookmarkedPostsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<BookmarkedPostsBloc>().add(
      SearchBookmarkedPostsEvent(searchParam: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar:
      AppBar(
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
                size: screenWidth * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.back,
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
          AppStrings.bookmarks,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchField(),
            AppSpacing.vSm,
            Expanded(
              child: BlocBuilder<BookmarkedPostsBloc, BookmarkedPostsState>(
                builder: (context, state) {
                  if (state is BookmarkedPostsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is BookmarkedPostsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF5D6470),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () {
                                context.read<BookmarkedPostsBloc>().add(
                                  const FetchBookmarkedPostsEvent(),
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is BookmarkedPostsLoaded) {
                    if (state.announcements.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<BookmarkedPostsBloc>().add(
                          const FetchBookmarkedPostsEvent(),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: ListView.separated(
                          itemCount: state.announcements.length,
                          separatorBuilder:
                              (_, __) => Divider(
                                color: AppColors.border, // Light gray
                                thickness: 1,
                                height: 1,
                              ),
                          itemBuilder: (context, index) {
                            return _BookmarkPostTile(
                              announcement: state.announcements[index],
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  Navigator.of(
                                    context,
                                  ).pop(state.announcements[index].id);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // 👈 curved border
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),

            prefixIcon: Icon(Icons.search, color: Color(0xFF7A7F89)),
            contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'No bookmarked posts yet.'
              : 'No bookmarked posts match your search.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5D6470),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BookmarkPostTile extends StatelessWidget {
  final AnnouncementEntity announcement;
  final VoidCallback? onTap;

  const _BookmarkPostTile({required this.announcement, this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = announcement.createdByUser;
    final title = _resolveTitle(announcement);
    final preview = _resolvePreview(announcement);
    final formattedDate = _formatDate(announcement.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: user?.imageUrl,
                name: user?.fullName,
                firstName: user?.firstName,
                lastName: user?.lastName,
                radius: 22,
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          size: 14,
                          color: Color(0xFF8B9098),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Color(0xFF8B9098),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveTitle(AnnouncementEntity announcement) {
    if (announcement.subject.trim().isNotEmpty) {
      return announcement.subject.trim();
    }
    if ((announcement.question ?? '').trim().isNotEmpty) {
      return announcement.question!.trim();
    }
    return 'Untitled post';
  }

  String _resolvePreview(AnnouncementEntity announcement) {
    if (announcement.description.trim().isNotEmpty) {
      return announcement.description.trim();
    }
    if ((announcement.question ?? '').trim().isNotEmpty &&
        announcement.question!.trim() != _resolveTitle(announcement)) {
      return announcement.question!.trim();
    }
    return 'Open this post to view more details.';
  }

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy | h:mm a').format(date);
    } catch (_) {
      return rawDate;
    }
  }
}
