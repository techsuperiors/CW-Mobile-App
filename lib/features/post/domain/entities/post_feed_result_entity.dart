import 'package:equatable/equatable.dart';

import 'announcement_entity.dart';

class PostFeedResultEntity extends Equatable {
  final List<AnnouncementEntity> announcements;
  final int allPostsCount;
  final int myPostsCount;
  final int praisePostsCount;

  const PostFeedResultEntity({
    required this.announcements,
    this.allPostsCount = 0,
    this.myPostsCount = 0,
    this.praisePostsCount = 0,
  });

  @override
  List<Object?> get props => [
    announcements,
    allPostsCount,
    myPostsCount,
    praisePostsCount,
  ];
}
