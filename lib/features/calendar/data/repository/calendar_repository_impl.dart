import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/calendar_day_entity.dart';
import '../../domain/repository/calendar_repository.dart';
import '../datasources/calendar_remote_datasource.dart';

/// Concrete implementation of [CalendarRepository].
///
/// Orchestrates network check → remote data source call → error wrapping.
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CalendarRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CalendarDayEntity>>> getCalendarData(
    int month,
    int year,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final calendarDays = await remoteDataSource.getCalendarData(month, year);
      return Right(calendarDays);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
