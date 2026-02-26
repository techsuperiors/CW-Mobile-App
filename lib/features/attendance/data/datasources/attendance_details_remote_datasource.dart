import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../models/attendance_details_model.dart';
import 'package:dio/dio.dart';

/// Attendance Details remote data source interface
abstract class AttendanceDetailsRemoteDataSource {
  Future<AttendanceDetailsModel> getAttendanceDetails();
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
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
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
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        'Failed to get attendance details: ${e.toString()}',
      );
    }
  }
}

