import 'package:equatable/equatable.dart';

import 'announcement_entity.dart';

class PostMenuOverviewEntity extends Equatable {
  final int likedPostsCount;
  final int repostedPostsCount;
  final int reportedPostsCount;
  final int pendingApprovalPostsCount;
  final List<AnnouncementEntity> likedAnnouncements;
  final List<AnnouncementEntity> repostedAnnouncements;
  final List<AnnouncementEntity> reportedAnnouncements;
  final List<AnnouncementEntity> pendingApprovalAnnouncements;

  const PostMenuOverviewEntity({
    required this.likedPostsCount,
    required this.repostedPostsCount,
    required this.reportedPostsCount,
    required this.pendingApprovalPostsCount,
    required this.likedAnnouncements,
    required this.repostedAnnouncements,
    required this.reportedAnnouncements,
    required this.pendingApprovalAnnouncements,
  });

  @override
  List<Object?> get props => [
    likedPostsCount,
    repostedPostsCount,
    reportedPostsCount,
    pendingApprovalPostsCount,
    likedAnnouncements,
    repostedAnnouncements,
    reportedAnnouncements,
    pendingApprovalAnnouncements,
  ];
}
