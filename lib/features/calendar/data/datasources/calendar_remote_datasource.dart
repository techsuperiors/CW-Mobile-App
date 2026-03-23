import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/calendar_day_model.dart';

/// Abstract interface for calendar remote data operations.
abstract class CalendarRemoteDataSource {
  /// Fetch attendance calendar data for the given [month] and [year].
  Future<List<CalendarDayModel>> getCalendarData(int month, int year);
}

/// Implementation that calls the attendance range API.
class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final ApiClient apiClient;

  CalendarRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CalendarDayModel>> getCalendarData(int month, int year) async {
    try {
      final firstDayLocal = DateTime(year, month, 1);
      final lastDayLocal = DateTime(
        year,
        month + 1,
        1,
      ).subtract(const Duration(milliseconds: 1));

      // Convert local month boundaries to UTC ISO strings as the API expects
      final startDateIso =
          firstDayLocal
              .subtract(const Duration(hours: 5, minutes: 30))
              .toUtc()
              .toIso8601String();
      final endDateIso =
          lastDayLocal
              .subtract(const Duration(hours: 5, minutes: 30))
              .toUtc()
              .toIso8601String();

      // Build the payload matching the API contract
      final payload = {
        'start_date': startDateIso,
        'end_date': endDateIso,
        'month': month,
        'year': year,
      };
      final encodedPayload = encodeData(payload);

      final url = '${AppUrls.attendanceRange}?payload=$encodedPayload';
      final response = await apiClient.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ??
              'Failed to load attendance calendar data',
        );
      }

      final List<dynamic> daysList = data['data'] as List<dynamic>? ?? [];

      return daysList
          .map(
            (item) => CalendarDayModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to load attendance calendar data: ${e.toString()}',
      );
    }
  }
}
