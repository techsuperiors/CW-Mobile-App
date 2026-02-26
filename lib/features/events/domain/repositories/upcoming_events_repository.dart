import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/upcoming_event.dart';

/// Upcoming Events repository interface
abstract class UpcomingEventsRepository {
  Future<Either<Failure, List<UpcomingEvent>>> getUpcomingEvents();
}

