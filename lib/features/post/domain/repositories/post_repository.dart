import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../entities/create_post_audience_entity.dart';
import '../entities/post_feed_result_entity.dart';
import '../entities/post_menu_overview_entity.dart';

abstract class PostRepository {
  Future<Either<Failure, AnnouncementEntity>> getAnnouncementDetails({
    required int announcementId,
  });

  Future<Either<Failure, PostFeedResultEntity>> getAnnouncements({
    required String postName,
    required String searchParam,
  });

  Future<Either<Failure, List<AnnouncementEntity>>> getBookmarkedAnnouncements({
    required int currentUserId,
    required String searchParam,
  });

  Future<Either<Failure, PostMenuOverviewEntity>> getPostMenuOverview({
    required int currentUserId,
    required String searchParam,
  });

  Future<Either<Failure, List<CreatePostAudienceDepartmentEntity>>>
  getCreatePostAudienceDepartments();

  Future<Either<Failure, List<CreatePostAudienceUserEntity>>>
  getCreatePostAudienceUsers();

  Future<Either<Failure, String>> generateAnnouncementContent({
    required String content,
  });

  Future<Either<Failure, String>> createAnnouncement({
    required List<CreatePostAudienceDepartmentEntity> selectedDepartments,
    required List<CreatePostAudienceUserEntity> selectedIndividuals,
    required List<CreatePostAudienceUserEntity> selectedUsers,
    required String notificationLevel,
    required String scheduleAnnouncement,
    required String subject,
    required String type,
    required String description,
    List<String>? options,
    String? question,
    required String status,
    required List<int> mentionedUserIds,
    required bool likesEnabled,
    required bool commentsEnabled,
    required bool repostEnabled,
    required bool shareEnabled,
    List<String>? attachmentFilePaths,
    int? praisedToUserId,
    required int createdBy,
  });

  Future<Either<Failure, bool>> submitPollAnswer({
    required int announcementId,
    required int userId,
    required String selectedOption,
  });

  Future<Either<Failure, bool>> likeAnnouncement({
    required int id,
    required String reaction,
  });

  Future<Either<Failure, bool>> removeLike({
    required int likeId,
    required int announcementId,
  });

  Future<Either<Failure, bool>> bookmarkAnnouncement({
    required int announcementId,
  });

  Future<Either<Failure, bool>> removeBookmark({
    required int announcementId,
  });

  Future<Either<Failure, bool>> deleteAnnouncement({
    required int announcementId,
  });

  Future<Either<Failure, bool>> reportAnnouncement({
    required int announcementId,
    required String reason,
  });

  Future<Either<Failure, bool>> markAnnouncementAdminRemark({
    required int announcementId,
    required String adminRemark,
  });

  Future<Either<Failure, bool>> updateAnnouncement({
    required int announcementId,
    required String scheduleAnnouncement,
    required String subject,
    required String type,
    required String description,
    List<String>? options,
    String? question,
    required String status,
    String? repostThought,
    required bool isEdited,
  });

  Future<Either<Failure, bool>> repostAnnouncement({
    required int announcementId,
    String? repostThought,
  });

  Future<Either<Failure, bool>> removeRepost({required int announcementId});

  Future<Either<Failure, CommentEntity>> addComment({
    required int announcementId,
    required String comment,
  });

  Future<Either<Failure, bool>> reactToComment({
    required int announcementId,
    required int commentId,
    required String reaction,
  });

  Future<Either<Failure, bool>> updateComment({
    required int commentId,
    required String comment,
    required bool isEdited,
  });

  Future<Either<Failure, bool>> deleteComment({required int commentId});
}
