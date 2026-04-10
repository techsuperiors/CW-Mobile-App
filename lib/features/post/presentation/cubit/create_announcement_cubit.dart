import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_post_audience_entity.dart';
import '../../domain/usecases/create_announcement_usecase.dart';

enum CreateAnnouncementStatus { initial, submitting, success, error }

class CreateAnnouncementState extends Equatable {
  final CreateAnnouncementStatus status;
  final String message;

  const CreateAnnouncementState({
    this.status = CreateAnnouncementStatus.initial,
    this.message = '',
  });

  CreateAnnouncementState copyWith({
    CreateAnnouncementStatus? status,
    String? message,
  }) {
    return CreateAnnouncementState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, message];
}

class CreateAnnouncementCubit extends Cubit<CreateAnnouncementState> {
  final CreateAnnouncementUseCase createAnnouncementUseCase;

  CreateAnnouncementCubit({required this.createAnnouncementUseCase})
    : super(const CreateAnnouncementState());

  Future<void> createGeneralAnnouncement({
    required List<CreatePostAudienceDepartmentEntity> selectedDepartments,
    required List<CreatePostAudienceUserEntity> selectedIndividuals,
    required List<CreatePostAudienceUserEntity> selectedUsers,
    required String scheduleAnnouncement,
    required String subject,
    required String description,
    required bool likesEnabled,
    required bool commentsEnabled,
    required bool repostEnabled,
    required bool shareEnabled,
    List<String>? attachmentFilePaths,
    required int createdBy,
  }) async {
    await _createAnnouncement(
      params: CreateAnnouncementParams(
        selectedDepartments: selectedDepartments,
        selectedIndividuals: selectedIndividuals,
        selectedUsers: selectedUsers,
        notificationLevel: 'selection',
        scheduleAnnouncement: scheduleAnnouncement,
        subject: subject.trim(),
        type: 'general',
        description: description.trim(),
        options: null,
        question: null,
        status: 'Active',
        mentionedUserIds: const [],
        likesEnabled: likesEnabled,
        commentsEnabled: commentsEnabled,
        repostEnabled: repostEnabled,
        shareEnabled: shareEnabled,
        attachmentFilePaths: attachmentFilePaths,
        praisedToUserId: null,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> createPraiseAnnouncement({
    required List<CreatePostAudienceDepartmentEntity> selectedDepartments,
    required List<CreatePostAudienceUserEntity> selectedIndividuals,
    required List<CreatePostAudienceUserEntity> selectedUsers,
    required String scheduleAnnouncement,
    required String subject,
    required String description,
    required bool likesEnabled,
    required bool commentsEnabled,
    required bool repostEnabled,
    required bool shareEnabled,
    List<String>? attachmentFilePaths,
    required int praisedToUserId,
    required int createdBy,
  }) async {
    await _createAnnouncement(
      params: CreateAnnouncementParams(
        selectedDepartments: selectedDepartments,
        selectedIndividuals: selectedIndividuals,
        selectedUsers: selectedUsers,
        notificationLevel: 'selection',
        scheduleAnnouncement: scheduleAnnouncement,
        subject: subject.trim(),
        type: 'praise',
        description: description.trim(),
        options: null,
        question: null,
        status: 'Active',
        mentionedUserIds: const [],
        likesEnabled: likesEnabled,
        commentsEnabled: commentsEnabled,
        repostEnabled: repostEnabled,
        shareEnabled: shareEnabled,
        attachmentFilePaths: attachmentFilePaths,
        praisedToUserId: praisedToUserId,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> createPollAnnouncement({
    required List<CreatePostAudienceDepartmentEntity> selectedDepartments,
    required List<CreatePostAudienceUserEntity> selectedIndividuals,
    required List<CreatePostAudienceUserEntity> selectedUsers,
    required String scheduleAnnouncement,
    required String question,
    required List<String> options,
    required bool likesEnabled,
    required bool commentsEnabled,
    required bool repostEnabled,
    required bool shareEnabled,
    required int createdBy,
  }) async {
    await _createAnnouncement(
      params: CreateAnnouncementParams(
        selectedDepartments: selectedDepartments,
        selectedIndividuals: selectedIndividuals,
        selectedUsers: selectedUsers,
        notificationLevel: 'selection',
        scheduleAnnouncement: scheduleAnnouncement,
        subject: '',
        type: 'poll',
        description: '',
        options: options.map((option) => option.trim()).toList(growable: false),
        question: question.trim(),
        status: 'Active',
        mentionedUserIds: const [],
        likesEnabled: likesEnabled,
        commentsEnabled: commentsEnabled,
        repostEnabled: repostEnabled,
        shareEnabled: shareEnabled,
        attachmentFilePaths: null,
        praisedToUserId: null,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> _createAnnouncement({
    required CreateAnnouncementParams params,
  }) async {
    emit(
      state.copyWith(status: CreateAnnouncementStatus.submitting, message: ''),
    );

    final result = await createAnnouncementUseCase(params);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreateAnnouncementStatus.error,
          message: failure.message,
        ),
      ),
      (message) => emit(
        state.copyWith(
          status: CreateAnnouncementStatus.success,
          message: message,
        ),
      ),
    );
  }
}
