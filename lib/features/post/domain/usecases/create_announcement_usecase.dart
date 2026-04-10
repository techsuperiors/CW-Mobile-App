import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/create_post_audience_entity.dart';
import '../repositories/post_repository.dart';

class CreateAnnouncementUseCase {
  final PostRepository repository;

  CreateAnnouncementUseCase(this.repository);

  Future<Either<Failure, String>> call(CreateAnnouncementParams params) {
    return repository.createAnnouncement(
      selectedDepartments: params.selectedDepartments,
      selectedIndividuals: params.selectedIndividuals,
      selectedUsers: params.selectedUsers,
      notificationLevel: params.notificationLevel,
      scheduleAnnouncement: params.scheduleAnnouncement,
      subject: params.subject,
      type: params.type,
      description: params.description,
      options: params.options,
      question: params.question,
      status: params.status,
      mentionedUserIds: params.mentionedUserIds,
      likesEnabled: params.likesEnabled,
      commentsEnabled: params.commentsEnabled,
      repostEnabled: params.repostEnabled,
      shareEnabled: params.shareEnabled,
      attachmentFilePaths: params.attachmentFilePaths,
      praisedToUserId: params.praisedToUserId,
      createdBy: params.createdBy,
    );
  }
}

class CreateAnnouncementParams {
  final List<CreatePostAudienceDepartmentEntity> selectedDepartments;
  final List<CreatePostAudienceUserEntity> selectedIndividuals;
  final List<CreatePostAudienceUserEntity> selectedUsers;
  final String notificationLevel;
  final String scheduleAnnouncement;
  final String subject;
  final String type;
  final String description;
  final List<String>? options;
  final String? question;
  final String status;
  final List<int> mentionedUserIds;
  final bool likesEnabled;
  final bool commentsEnabled;
  final bool repostEnabled;
  final bool shareEnabled;
  final List<String>? attachmentFilePaths;
  final int? praisedToUserId;
  final int createdBy;

  CreateAnnouncementParams({
    required this.selectedDepartments,
    required this.selectedIndividuals,
    required this.selectedUsers,
    required this.notificationLevel,
    required this.scheduleAnnouncement,
    required this.subject,
    required this.type,
    required this.description,
    this.options,
    this.question,
    required this.status,
    required this.mentionedUserIds,
    required this.likesEnabled,
    required this.commentsEnabled,
    required this.repostEnabled,
    required this.shareEnabled,
    this.attachmentFilePaths,
    this.praisedToUserId,
    required this.createdBy,
  });
}
