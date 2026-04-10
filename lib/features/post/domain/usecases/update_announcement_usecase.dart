import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class UpdateAnnouncementUseCase {
  final PostRepository repository;

  UpdateAnnouncementUseCase(this.repository);

  Future<Either<Failure, bool>> call(UpdateAnnouncementParams params) {
    return repository.updateAnnouncement(
      announcementId: params.announcementId,
      scheduleAnnouncement: params.scheduleAnnouncement,
      subject: params.subject,
      type: params.type,
      description: params.description,
      options: params.options,
      question: params.question,
      status: params.status,
      repostThought: params.repostThought,
      isEdited: params.isEdited,
    );
  }
}

class UpdateAnnouncementParams {
  final int announcementId;
  final String scheduleAnnouncement;
  final String subject;
  final String type;
  final String description;
  final List<String>? options;
  final String? question;
  final String status;
  final String? repostThought;
  final bool isEdited;

  UpdateAnnouncementParams({
    required this.announcementId,
    required this.scheduleAnnouncement,
    required this.subject,
    required this.type,
    required this.description,
    this.options,
    this.question,
    required this.status,
    this.repostThought,
    required this.isEdited,
  });
}
