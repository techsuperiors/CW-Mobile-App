import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/upcoming_event.dart';
import '../repositories/upcoming_events_repository.dart';

/// Use case for getting upcoming events
class GetUpcomingEventsUseCase {
  final UpcomingEventsRepository repository;

  GetUpcomingEventsUseCase(this.repository);

  Future<Either<Failure, List<UpcomingEvent>>> call() {
    return repository.getUpcomingEvents();
  }
}

