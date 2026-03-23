import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class GetNotificationCount {
  final NotificationRepository repository;

  GetNotificationCount(this.repository);

  Future<Either<Failure, int>> call() async {
    return await repository.getNotificationCount();
  }
}
