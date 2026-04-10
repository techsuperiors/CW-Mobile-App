import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/entities/create_post_audience_entity.dart';
import '../../domain/entities/post_feed_result_entity.dart';
import '../../domain/entities/post_menu_overview_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PostRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AnnouncementEntity>> getAnnouncementDetails({
    required int announcementId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final announcement = await remoteDataSource.getAnnouncementDetails(
          announcementId: announcementId,
        );
        return Right(announcement);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, PostFeedResultEntity>> getAnnouncements({
    required String postName,
    required String searchParam,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getAnnouncements(
          postName: postName,
          searchParam: searchParam,
        );

        if (response.success) {
          return Right(
            PostFeedResultEntity(
              announcements: response.data,
              allPostsCount: response.allAnnouncementCount,
              myPostsCount: response.myAnnouncementCount,
              praisePostsCount: response.pariseAnnouncementCount,
            ),
          );
        } else {
          return Left(ServerFailure('Failed to fetch announcements'));
        }
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, List<AnnouncementEntity>>> getBookmarkedAnnouncements({
    required int currentUserId,
    required String searchParam,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getAnnouncements(
          postName: 'all',
          searchParam: searchParam,
        );

        if (!response.success) {
          return Left(
            ServerFailure('Failed to fetch bookmarked announcements'),
          );
        }

        final bookmarkedPosts =
            response.data
                .where(
                  (announcement) =>
                      announcement.bookmarkedByUserIds?.contains(
                        currentUserId,
                      ) ??
                      false,
                )
                .toList();

        return Right(bookmarkedPosts);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, PostMenuOverviewEntity>> getPostMenuOverview({
    required int currentUserId,
    required String searchParam,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getAnnouncements(
          postName: 'all',
          searchParam: searchParam,
        );

        if (!response.success) {
          return Left(ServerFailure('Failed to fetch post menu overview'));
        }

        final announcements = response.data;

        final likedAnnouncements =
            announcements
                .where((announcement) => announcement.isLiked)
                .toList();
        final repostedAnnouncements =
            announcements
                .where(
                  (announcement) =>
                      announcement.repostedBy == currentUserId ||
                      announcement.repostedByUser?.id == currentUserId,
                )
                .toList();
        final reportedAnnouncements =
            announcements
                .where(
                  (announcement) =>
                      announcement.reportedByUserIds.contains(currentUserId),
                )
                .toList();
        final pendingApprovalAnnouncements =
            announcements
                .where(
                  (announcement) =>
                      announcement.createdByUser?.id == currentUserId &&
                      _isPendingApproval(announcement.adminRemark),
                )
                .toList();

        return Right(
          PostMenuOverviewEntity(
            likedPostsCount: response.likedAnnouncementCount,
            repostedPostsCount: response.totalRepostCount,
            reportedPostsCount: response.reportedAnnouncementCount,
            pendingApprovalPostsCount: response.pendingApprovalCount,
            likedAnnouncements: likedAnnouncements,
            repostedAnnouncements: repostedAnnouncements,
            reportedAnnouncements: reportedAnnouncements,
            pendingApprovalAnnouncements: pendingApprovalAnnouncements,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  bool _isPendingApproval(String? adminRemark) {
    final normalizedRemark = adminRemark?.trim().toLowerCase() ?? '';
    return normalizedRemark.contains('pending');
  }

  @override
  Future<Either<Failure, List<CreatePostAudienceDepartmentEntity>>>
  getCreatePostAudienceDepartments() async {
    if (await networkInfo.isConnected) {
      try {
        final response =
            await remoteDataSource.getCreatePostAudienceDepartments();

        if (!response.success) {
          return const Left(
            ServerFailure('Failed to fetch audience departments'),
          );
        }

        return Right(response.data);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, List<CreatePostAudienceUserEntity>>>
  getCreatePostAudienceUsers() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCreatePostAudienceUsers();

        if (!response.success) {
          return const Left(ServerFailure('Failed to fetch audience users'));
        }

        return Right(response.data);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, String>> generateAnnouncementContent({
    required String content,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final generatedContent = await remoteDataSource
            .generateAnnouncementContent(content: content);
        return Right(generatedContent);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.createAnnouncement(
          selectedDepartments: selectedDepartments,
          selectedIndividuals: selectedIndividuals,
          selectedUsers: selectedUsers,
          notificationLevel: notificationLevel,
          scheduleAnnouncement: scheduleAnnouncement,
          subject: subject,
          type: type,
          description: description,
          options: options,
          question: question,
          status: status,
          mentionedUserIds: mentionedUserIds,
          likesEnabled: likesEnabled,
          commentsEnabled: commentsEnabled,
          repostEnabled: repostEnabled,
          shareEnabled: shareEnabled,
          attachmentFilePaths: attachmentFilePaths,
          praisedToUserId: praisedToUserId,
          createdBy: createdBy,
        );
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> submitPollAnswer({
    required int announcementId,
    required int userId,
    required String selectedOption,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.submitPollAnswer(
          announcementId: announcementId,
          userId: userId,
          selectedOption: selectedOption,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> likeAnnouncement({
    required int id,
    required String reaction,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.likeAnnouncement(
          id: id,
          reaction: reaction,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> removeLike({
    required int likeId,
    required int announcementId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.removeLike(
          likeId: likeId,
          announcementId: announcementId,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> bookmarkAnnouncement({
    required int announcementId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.bookmarkAnnouncement(
          announcementId: announcementId,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> removeBookmark({
    required int announcementId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.removeBookmark(
          announcementId: announcementId,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAnnouncement({
    required int announcementId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteAnnouncement(
          announcementId: announcementId,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> reportAnnouncement({
    required int announcementId,
    required String reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.reportAnnouncement(
          announcementId: announcementId,
          reason: reason,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> markAnnouncementAdminRemark({
    required int announcementId,
    required String adminRemark,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.markAnnouncementAdminRemark(
          announcementId: announcementId,
          adminRemark: adminRemark,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updateAnnouncement(
          announcementId: announcementId,
          scheduleAnnouncement: scheduleAnnouncement,
          subject: subject,
          type: type,
          description: description,
          options: options,
          question: question,
          status: status,
          repostThought: repostThought,
          isEdited: isEdited,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> repostAnnouncement({
    required int announcementId,
    String? repostThought,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.repostAnnouncement(
          announcementId: announcementId,
          repostThought: repostThought,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> removeRepost({
    required int announcementId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.removeRepost(
          announcementId: announcementId,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required int announcementId,
    required String comment,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final commentModel = await remoteDataSource.addComment(
          announcementId: announcementId,
          comment: comment,
        );
        return Right(commentModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> reactToComment({
    required int announcementId,
    required int commentId,
    required String reaction,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isActive = await remoteDataSource.reactToComment(
          announcementId: announcementId,
          commentId: commentId,
          reaction: reaction,
        );
        return Right(isActive);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> updateComment({
    required int commentId,
    required String comment,
    required bool isEdited,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.updateComment(
          commentId: commentId,
          comment: comment,
          isEdited: isEdited,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteComment({required int commentId}) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteComment(
          commentId: commentId,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }
}
