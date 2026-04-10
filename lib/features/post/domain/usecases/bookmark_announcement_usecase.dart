import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class BookmarkAnnouncementUseCase {
  final PostRepository repository;

  BookmarkAnnouncementUseCase(this.repository);

  Future<Either<Failure, bool>> call(BookmarkAnnouncementParams params) {
    return repository.bookmarkAnnouncement(
      announcementId: params.announcementId,
    );
  }
}

class BookmarkAnnouncementParams {
  final int announcementId;

  BookmarkAnnouncementParams({
    required this.announcementId,
  });
}
