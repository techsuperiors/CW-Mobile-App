import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/calendar_day_entity.dart';

/// Abstract contract for calendar data operations.
///
/// The domain layer defines WHAT data is needed,
/// the data layer decides HOW to fetch it.
abstract class CalendarRepository {
  /// Fetch attendance calendar data for the given [month] and [year].
  Future<Either<Failure, List<CalendarDayEntity>>> getCalendarData(
    int month,
    int year,
  );
}
