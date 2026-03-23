import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, int>> getNotificationCount();
  Future<Either<Failure, void>> viewNotifications();
  Future<Either<Failure, void>> readNotification(int notificationId);
}
