import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../../domain/entities/create_post_audience_entity.dart';
import '../models/announcement_model.dart';
import '../models/create_post_audience_model.dart';

abstract class PostRemoteDataSource {
  Future<AnnouncementModel> getAnnouncementDetails({
    required int announcementId,
  });

  Future<AnnouncementResponseModel> getAnnouncements({
    required String postName,
    required String searchParam,
  });

  Future<CreatePostAudienceDepartmentsResponseModel>
  getCreatePostAudienceDepartments();

  Future<CreatePostAudienceUsersResponseModel> getCreatePostAudienceUsers();

  Future<String> generateAnnouncementContent({required String content});

  Future<String> createAnnouncement({
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

  Future<bool> submitPollAnswer({
    required int announcementId,
    required int userId,
    required String selectedOption,
  });

  Future<bool> bookmarkAnnouncement({required int announcementId});

  Future<bool> removeBookmark({required int announcementId});

  Future<bool> deleteAnnouncement({required int announcementId});

  Future<bool> reportAnnouncement({
    required int announcementId,
    required String reason,
  });

  Future<bool> markAnnouncementAdminRemark({
    required int announcementId,
    required String adminRemark,
  });

  Future<bool> updateAnnouncement({
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

  Future<bool> repostAnnouncement({
    required int announcementId,
    String? repostThought,
  });

  Future<bool> removeRepost({required int announcementId});

  Future<CommentModel> addComment({
    required int announcementId,
    required String comment,
  });

  Future<bool> reactToComment({
    required int announcementId,
    required int commentId,
    required String reaction,
  });

  Future<bool> updateComment({
    required int commentId,
    required String comment,
    required bool isEdited,
  });

  Future<bool> deleteComment({required int commentId});

  Future<bool> likeAnnouncement({required int id, required String reaction});

  Future<bool> removeLike({required int likeId, required int announcementId});
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final ApiClient apiClient;

  PostRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AnnouncementModel> getAnnouncementDetails({
    required int announcementId,
  }) async {
    final payload = encodeData({'announcement_id': announcementId});

    try {
      final response = await apiClient.get(
        AppUrls.announcementDetails,
        queryParameters: {'payload': payload},
      );

      final data = response.data as Map<String, dynamic>;
      final responseData = data['data'] as Map<String, dynamic>?;
      if (responseData == null) {
        throw const ServerException('Invalid announcement details response');
      }

      return AnnouncementModel.fromJson(responseData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to fetch announcement details: ${e.toString()}',
      );
    }
  }

  @override
  Future<AnnouncementResponseModel> getAnnouncements({
    required String postName,
    required String searchParam,
  }) async {
    final payload = {'postName': postName, 'searchParam': searchParam};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.get(
        AppUrls.announcementList,
        queryParameters: {'payload': encodedData},
      );

      final announcementResponse = AnnouncementResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      return announcementResponse;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch announcements: ${e.toString()}');
    }
  }

  @override
  Future<CreatePostAudienceDepartmentsResponseModel>
  getCreatePostAudienceDepartments() async {
    try {
      final response = await apiClient.get(
        AppUrls.announcementAudienceDepartments,
      );
      return CreatePostAudienceDepartmentsResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to fetch audience departments: ${e.toString()}',
      );
    }
  }

  @override
  Future<CreatePostAudienceUsersResponseModel>
  getCreatePostAudienceUsers() async {
    final payload = encodeData(<String, dynamic>{});

    try {
      final response = await apiClient.get(
        AppUrls.announcementAudienceUsers,
        queryParameters: {'payload': payload},
      );

      return CreatePostAudienceUsersResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch audience users: ${e.toString()}');
    }
  }

  @override
  Future<String> generateAnnouncementContent({required String content}) async {
    final payload = encodeData({'content': content.trim()});

    try {
      final response = await apiClient.post(
        AppUrls.announcementGenerateContent,
        data: {'payload': payload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to rewrite content',
        );
      }

      final generatedContent = data['data']?.toString().trim() ?? '';
      if (generatedContent.isEmpty) {
        throw const ServerException('Generated content is empty');
      }

      return generatedContent;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to rewrite content: ${e.toString()}');
    }
  }

  @override
  Future<String> createAnnouncement({
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
    final payload = <String, dynamic>{
      'announcement_id': null,
      'select_audience': {
        'projects': <dynamic>[],
        'departments': selectedDepartments
            .map((department) => {'id': department.id, 'name': department.name})
            .toList(growable: false),
        'individuals': selectedIndividuals
            .map(
              (user) => {
                'id': user.id,
                'firstName': user.firstName,
                'lastName': user.lastName,
                'email': user.email,
                'image_url': user.imageUrl,
                'profile_color': user.profileColor,
              },
            )
            .toList(growable: false),
      },
      'notification_level': notificationLevel.trim(),
      'schedule_announcement': scheduleAnnouncement,
      'subject': subject.trim().isEmpty ? null : subject.trim(),
      'selected_users': selectedUsers
          .map((user) => {'id': user.id, 'name': user.fullName})
          .toList(growable: false),
      'type': type.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'options': options,
      'question': question,
      'status': status.trim(),
      'mentioned_users': mentionedUserIds,
      'post_configuration': {
        'likesEnabled': likesEnabled,
        'commentsEnabled': commentsEnabled,
        'repostEnabled': repostEnabled,
        'shareEnabled': shareEnabled,
      },
      'praised_to': praisedToUserId,
      'created_by': createdBy,
    };
    final encodedData = encodeData(payload);

    try {
      final formData = FormData.fromMap({'payload': encodedData});
      final normalizedAttachmentPaths =
          attachmentFilePaths
              ?.map((path) => path.trim())
              .where((path) => path.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];

      for (final path in normalizedAttachmentPaths) {
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(path, filename: p.basename(path)),
          ),
        );
      }

      final response = await apiClient.post(
        AppUrls.announcementUpdate,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to create post',
        );
      }

      return data['message'] as String? ?? 'Post created successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create post: ${e.toString()}');
    }
  }

  @override
  Future<bool> submitPollAnswer({
    required int announcementId,
    required int userId,
    required String selectedOption,
  }) async {
    final payload = encodeData({
      'announcement_id': announcementId,
      'user_id': userId,
      'selectedOption': selectedOption.trim(),
    });

    try {
      final response = await apiClient.post(
        AppUrls.announcementAnswerResponse,
        data: {'payload': payload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to submit poll answer: ${e.toString()}');
    }
  }

  @override
  Future<bool> likeAnnouncement({
    required int id,
    required String reaction,
  }) async {
    final payload = {'announcement_id': id, 'reaction_name': reaction};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementLike,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to like announcement: ${e.toString()}');
    }
  }

  @override
  Future<bool> bookmarkAnnouncement({required int announcementId}) async {
    final payload = {'announcement_id': announcementId};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.put(
        AppUrls.announcementBookmark,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update bookmark: ${e.toString()}');
    }
  }

  @override
  Future<bool> removeBookmark({required int announcementId}) async {
    final payload = {'announcement_id': announcementId};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.put(
        AppUrls.announcementRemoveBookmark,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to remove bookmark: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteAnnouncement({required int announcementId}) async {
    final payload = {'announcement_id': announcementId};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementDelete,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete announcement: ${e.toString()}');
    }
  }

  @override
  Future<bool> reportAnnouncement({
    required int announcementId,
    required String reason,
  }) async {
    final payload = {
      'announcement_id': announcementId,
      'reason': reason.trim(),
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementReport,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to report announcement: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAnnouncementAdminRemark({
    required int announcementId,
    required String adminRemark,
  }) async {
    final payload = {
      'announcement_id': announcementId,
      'admin_remark': adminRemark.trim(),
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementAdminReportMark,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to update announcement review status: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> updateAnnouncement({
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
    final normalizedSubject = subject.trim();
    final normalizedDescription = description.trim();
    final normalizedQuestion = question?.trim();
    final normalizedRepostThought = repostThought?.trim();
    final normalizedOptions =
        options
            ?.map((option) => option.trim())
            .where((option) => option.isNotEmpty)
            .toList(growable: false);

    final payload = <String, dynamic>{
      'announcement_id': announcementId,
      'schedule_announcement': scheduleAnnouncement,
      'subject': normalizedSubject.isEmpty ? null : normalizedSubject,
      'type': type.trim(),
      'description':
          normalizedDescription.isEmpty ? null : normalizedDescription,
      'options': normalizedOptions,
      'question':
          normalizedQuestion == null || normalizedQuestion.isEmpty
              ? null
              : normalizedQuestion,
      'status': status,
      'repost_thought':
          normalizedRepostThought == null || normalizedRepostThought.isEmpty
              ? null
              : normalizedRepostThought,
      'is_edited': isEdited,
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.put(
        AppUrls.announcementUpdate,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update announcement: ${e.toString()}');
    }
  }

  @override
  Future<bool> repostAnnouncement({
    required int announcementId,
    String? repostThought,
  }) async {
    final payload = <String, dynamic>{
      'announcement_id': announcementId,
      if (repostThought != null && repostThought.trim().isNotEmpty)
        'repost_thought': repostThought.trim(),
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementRepost,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to repost announcement: ${e.toString()}');
    }
  }

  @override
  Future<bool> removeRepost({required int announcementId}) async {
    final payload = {'announcement_id': announcementId};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementDelete,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to remove repost: ${e.toString()}');
    }
  }

  @override
  Future<bool> removeLike({
    required int likeId,
    required int announcementId,
  }) async {
    final payload = {'id': likeId, 'announcement_id': announcementId};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementRemoveLike,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to remove like: ${e.toString()}');
    }
  }

  @override
  Future<CommentModel> addComment({
    required int announcementId,
    required String comment,
  }) async {
    final payload = {
      'announcement_id': announcementId,
      'comment': comment.trim(),
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementComment,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      final responseData = data['data'] as Map<String, dynamic>?;
      if (responseData == null) {
        throw const ServerException('Invalid comment response');
      }
      return CommentModel.fromJson(responseData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to add comment: ${e.toString()}');
    }
  }

  @override
  Future<bool> reactToComment({
    required int announcementId,
    required int commentId,
    required String reaction,
  }) async {
    final payload = {
      'announcement_id': announcementId,
      'comment_id': commentId,
      'reactions': reaction,
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementCommentLike,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['flag'] as bool? ?? data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to react to comment: ${e.toString()}');
    }
  }

  @override
  Future<bool> updateComment({
    required int commentId,
    required String comment,
    required bool isEdited,
  }) async {
    final payload = {
      'comment_id': commentId,
      'comment': comment.trim(),
      'is_edited': isEdited,
    };
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementCommentUpdate,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update comment: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteComment({required int commentId}) async {
    final payload = {'comment_id': commentId};
    final encodedData = encodeData(payload);

    try {
      final response = await apiClient.post(
        AppUrls.announcementCommentDelete,
        data: {'payload': encodedData},
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete comment: ${e.toString()}');
    }
  }
}
