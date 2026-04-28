import 'package:dio/dio.dart';

import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../models/employee_directory_remote_models.dart';

abstract class EmployeeDirectoryRemoteDataSource {
  Future<EmployeeDirectoryPageRemoteModel> getEmployees({
    required int clientId,
    required int page,
    required int limit,
  });

  Future<EmployeeDirectoryDetailRemoteModel> getEmployeeDetails({
    required int userId,
  });
}

class EmployeeDirectoryRemoteDataSourceImpl
    implements EmployeeDirectoryRemoteDataSource {
  final ApiClient apiClient;

  EmployeeDirectoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<EmployeeDirectoryPageRemoteModel> getEmployees({
    required int clientId,
    required int page,
    required int limit,
  }) async {
    final payload = encodeData({
      'client_id': clientId,
      'employeeID': const [],
      'designation': const [],
      'department': const [],
      'email': const [],
      'status': const [],
      'employment_status': const [],
      'gender': const [],
      'probation': const [],
      'legal_entity': const [],
      'business_unit': const [],
      'page': page,
      'limit': limit,
      'request_type': 'All',
    });

    try {
      final response = await apiClient.get(
        AppUrls.usersList,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load employee directory',
        );
      }

      return EmployeeDirectoryPageRemoteModel.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to load employee directory: ${e.toString()}',
      );
    }
  }

  @override
  Future<EmployeeDirectoryDetailRemoteModel> getEmployeeDetails({
    required int userId,
  }) async {
    final payload = encodeData({'user_id': userId});

    try {
      final response = await apiClient.get(
        AppUrls.userProfileBasicDetails,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load employee details',
        );
      }

      return EmployeeDirectoryDetailRemoteModel.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load employee details: ${e.toString()}');
    }
  }
}
