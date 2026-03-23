import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/upcoming_event.dart';
import '../../domain/repositories/upcoming_events_repository.dart';
import '../datasources/upcoming_events_remote_datasource.dart';
import '../models/upcoming_event_model.dart';

/// Upcoming Events repository implementation
class UpcomingEventsRepositoryImpl implements UpcomingEventsRepository {
  final UpcomingEventsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UpcomingEventsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<UpcomingEvent>>> getUpcomingEvents() async {
    if (await networkInfo.isConnected) {
      try {
        final eventModels = await remoteDataSource.getUpcomingEvents();
        
        // Convert models to entities
        final events = eventModels.map((model) => _mapModelToEntity(model)).toList();
        
        return Right(events);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  UpcomingEvent _mapModelToEntity(UpcomingEventModel model) {
    // Map icon name to IconData
    String iconName = model.iconName;
    
    return UpcomingEvent(
      id: model.id,
      eventType: model.eventType ?? model.title ?? 'Event',
      personName: model.personName ?? 'Unknown',
      date: model.date ?? model.eventDate ?? model.startDate ?? '',
      formattedDate: model.formattedDate,
      iconName: iconName,
      imageUrl: model.imageUrl,           // add
      profileColor: model.profileColor,   // add
    );
  }
}

