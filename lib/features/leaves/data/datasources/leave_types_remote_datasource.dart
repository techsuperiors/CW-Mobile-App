import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../models/leave_type_model.dart';
import 'package:dio/dio.dart';

/// Leave Types remote data source interface
abstract class LeaveTypesRemoteDataSource {
  Future<LeaveTypesResponseModel> getLeaveTypes();
}

/// Leave Types remote data source implementation
class LeaveTypesRemoteDataSourceImpl implements LeaveTypesRemoteDataSource {
  final ApiClient apiClient;

  LeaveTypesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LeaveTypesResponseModel> getLeaveTypes() async {
    try {
      final response = await apiClient.get(
        AppUrls.leaveTypesList,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final apiResponse = LeaveTypesApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to get leave types',
        );
      }

      if (apiResponse.data == null) {
        throw ServerException('Leave types data not found');
      }

      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to get leave types: ${e.toString()}');
    }
  }
}

