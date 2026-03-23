import 'package:dio/dio.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../models/wfh_request_model.dart';

abstract class WfhRemoteDataSource {
  Future<List<WfhRequestModel>> getWfhRequests();
  Future<List<WfhRequestModel>> getTeamWfhRequests({
    int page = 1,
    int limit = 50,
    String requestType = 'All',
  });
  Future<void> updateWfhStatus({
    required int requestId,
    required String status,
  });
}

class WfhRemoteDataSourceImpl implements WfhRemoteDataSource {
  final ApiClient apiClient;

  WfhRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<WfhRequestModel>> getWfhRequests() async {
    try {
      final response = await apiClient.get(
        AppUrls.wfhRequests,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw const ServerException('Invalid server response');
      }

      if (responseData['success'] != true) {
        throw ServerException(
          responseData['message'] as String? ?? 'Failed to load WFH requests',
        );
      }

      final requestsList = responseData['data'];
      if (requestsList is! List) {
        return [];
      }

      return requestsList
          .whereType<Map>()
          .map(
            (item) => WfhRequestModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(AppStrings.connectionTimeout);
      }
      if (e.type == DioExceptionType.cancel) {
        throw const NetworkException(AppStrings.requestCancelled);
      }
      if (e.response?.statusCode == 401) {
        throw const AuthException(AppStrings.unauthorized);
      }
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          data['message'] as String? ?? AppStrings.serverError,
        );
      }
      throw const NetworkException(AppStrings.networkError);
    } on TypeError {
      throw const ServerException('Invalid server response');
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<List<WfhRequestModel>> getTeamWfhRequests({
    int page = 1,
    int limit = 50,
    String requestType = 'All',
  }) async {
    try {
      final encodedData = encodeData({
        'request_type': requestType,
        'page': page,
        'limit': limit,
      });

      final response = await apiClient.get(
        '${AppUrls.wfhTeamRequests}?payload=$encodedData',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw const ServerException('Invalid server response');
      }

      if (responseData['success'] != true) {
        throw ServerException(
          responseData['message'] as String? ??
              'Failed to load team WFH requests',
        );
      }

      final requestsList = responseData['data'];
      if (requestsList is! List) {
        return [];
      }

      return requestsList
          .whereType<Map>()
          .map(
            (item) => WfhRequestModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(AppStrings.connectionTimeout);
      }
      if (e.type == DioExceptionType.cancel) {
        throw const NetworkException(AppStrings.requestCancelled);
      }
      if (e.response?.statusCode == 401) {
        throw const AuthException(AppStrings.unauthorized);
      }
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          data['message'] as String? ?? AppStrings.serverError,
        );
      }
      throw const NetworkException(AppStrings.networkError);
    } on TypeError {
      throw const ServerException('Invalid server response');
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<void> updateWfhStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      final payload = {'request_id': requestId, 'status': status};
      final encodedData = encodeData(payload);

      final response = await apiClient.post(
        AppUrls.wfhRequestStatus,
        data: {'payload': encodedData},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw ServerException(
          responseData['message'] as String? ?? 'Failed to update WFH status',
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(AppStrings.connectionTimeout);
      }
      if (e.type == DioExceptionType.cancel) {
        throw const NetworkException(AppStrings.requestCancelled);
      }
      if (e.response?.statusCode == 401) {
        throw const AuthException(AppStrings.unauthorized);
      }
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          data['message'] as String? ?? 'Failed to update WFH status',
        );
      }
      throw const NetworkException(AppStrings.networkError);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }
}
