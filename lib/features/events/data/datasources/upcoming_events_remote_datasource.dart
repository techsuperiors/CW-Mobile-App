import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../models/upcoming_event_model.dart';
import 'package:dio/dio.dart';

/// Upcoming Events remote data source interface
abstract class UpcomingEventsRemoteDataSource {
  Future<List<UpcomingEventModel>> getUpcomingEvents();
}

/// Upcoming Events remote data source implementation
class UpcomingEventsRemoteDataSourceImpl implements UpcomingEventsRemoteDataSource {
  final ApiClient apiClient;

  UpcomingEventsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<UpcomingEventModel>> getUpcomingEvents() async {
    try {
      final response = await apiClient.get(
        AppUrls.upcomingEvents,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final eventsResponse = UpcomingEventsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!eventsResponse.success) {
        throw ServerException(
          eventsResponse.message ?? 'Failed to get upcoming events',
        );
      }

      return eventsResponse.data ?? [];
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to get upcoming events: ${e.toString()}');
    }
  }
}

