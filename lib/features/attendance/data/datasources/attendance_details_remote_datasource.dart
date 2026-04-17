import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/attendance_day_detail_model.dart';
import '../models/attendance_details_model.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

/// Attendance Details remote data source interface
abstract class AttendanceDetailsRemoteDataSource {
  Future<AttendanceDetailsModel> getAttendanceDetails();
  Future<AttendanceDayDetailModel> getAttendanceDayDetail({
    required int userId,
    required String date,
  });
  Future<List<AttendanceDayLogModel>> getAttendanceActivity({
    required int userId,
    required String date,
  });
}

/// Attendance Details remote data source implementation
class AttendanceDetailsRemoteDataSourceImpl
    implements AttendanceDetailsRemoteDataSource {
  final ApiClient apiClient;

  AttendanceDetailsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AttendanceDetailsModel> getAttendanceDetails() async {
    try {
      final response = await apiClient.get(
        AppUrls.attendanceDetails,
      );
      developer.log(
        'Attendance details response: ${response.data}',
        name: 'AttendanceDetailsAPI',
      );

      final apiResponse = AttendanceDetailsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to get attendance details',
        );
      }

      if (apiResponse.data == null) {
        throw ServerException('Attendance details data not found');
      }

      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to get attendance details',
      );
    }
  }

  @override
  Future<AttendanceDayDetailModel> getAttendanceDayDetail({
    required int userId,
    required String date,
  }) async {
    try {
      final encodedPayload = encodeData({'user_id': userId, 'date': date});
      developer.log(
        'GET ${AppUrls.attendanceUserDetail}?payload=$encodedPayload',
        name: 'AttendanceDayDetailAPI',
      );
      final response = await apiClient.get(
        '${AppUrls.attendanceUserDetail}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ServerException('Invalid attendance day detail response');
      }
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to get attendance day detail',
        );
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ServerException('Attendance day detail data not found');
      }
      return AttendanceDayDetailModel.fromJson(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to get attendance day detail: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AttendanceDayLogModel>> getAttendanceActivity({
    required int userId,
    required String date,
  }) async {
    try {
      final encodedPayload = encodeData({'date': date, 'user_id': userId});
      developer.log(
        'GET ${AppUrls.attendanceActivity}?payload=$encodedPayload',
        name: 'AttendanceActivityAPI',
      );
      final response = await apiClient.get(
        '${AppUrls.attendanceActivity}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ServerException('Invalid attendance activity response');
      }
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to get attendance activity',
        );
      }
      final data = body['data'];
      if (data is! List) {
        return const <AttendanceDayLogModel>[];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => AttendanceDayLogModel.fromActivityJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to get attendance activity: ${e.toString()}',
      );
    }
  }
}
