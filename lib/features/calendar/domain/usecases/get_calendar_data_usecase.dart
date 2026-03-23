import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/calendar_day_entity.dart';
import '../repository/calendar_repository.dart';

/// Use case to fetch attendance calendar data for a specific month and year.
///
/// Single responsibility: orchestrate the call to the repository.
class GetCalendarDataUseCase {
  final CalendarRepository repository;

  GetCalendarDataUseCase(this.repository);

  /// Execute the use case.
  ///
  /// [month] 1–12, [year] e.g. 2026
  Future<Either<Failure, List<CalendarDayEntity>>> call(int month, int year) {
    return repository.getCalendarData(month, year);
  }
}
