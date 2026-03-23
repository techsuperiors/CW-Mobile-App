import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class ViewNotifications {
  final NotificationRepository repository;

  ViewNotifications(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.viewNotifications();
  }
}
