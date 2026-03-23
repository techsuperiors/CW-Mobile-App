import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class ReadNotification {
  final NotificationRepository repository;

  ReadNotification(this.repository);

  Future<Either<Failure, void>> call(int notificationId) async {
    return await repository.readNotification(notificationId);
  }
}
