import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../models/visit_remote_models.dart';
import '../../domain/models/visit_model.dart';

abstract class VisitRemoteDataSource {
  Future<({List<VisitRemoteModel> visits, int totalCount})> getVisits({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  });

  Future<List<VisitEmployeeRemoteModel>> getEmployees();

  Future<List<VisitCustomerRemoteModel>> getCustomers();

  Future<List<VisitAddressRemoteModel>> getAddresses();

  Future<String> createVisit(CreateVisitParams params);

  Future<String> createVisitActivity(CreateVisitActivityParams params);
}

class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  final ApiClient apiClient;

  VisitRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<({List<VisitRemoteModel> visits, int totalCount})> getVisits({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  }) async {
    final payload = <String, dynamic>{'page': page, 'limit': limit};

    if (visitType != null) {
      payload['visit_type'] = visitType.value;
    }
    if (visitStatus != null) {
      payload['visit_status'] = visitStatus.value;
    }
    if (fromDate != null) {
      payload['from_date'] = DateFormat('yyyy-MM-dd').format(fromDate);
    }
    if (toDate != null) {
      payload['to_date'] = DateFormat('yyyy-MM-dd').format(toDate);
    }
    if (createdBy != null) {
      payload['created_by'] = createdBy;
    }

    final encodedPayload = encodeData(payload);

    try {
      final response = await apiClient.get(
        AppUrls.visitList,
        queryParameters: {'payload': encodedPayload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load visits',
        );
      }

      final visits = (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VisitRemoteModel.fromJson)
          .toList(growable: false);

      return (visits: visits, totalCount: _parseInt(data['totalCount']));
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load visits: ${e.toString()}');
    }
  }

  @override
  Future<List<VisitEmployeeRemoteModel>> getEmployees() async {
    final payload = encodeData(<String, dynamic>{});

    try {
      final response = await apiClient.get(
        AppUrls.announcementAudienceUsers,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load employees',
        );
      }

      return (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VisitEmployeeRemoteModel.fromJson)
          .where((employee) => employee.id > 0)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load employees: ${e.toString()}');
    }
  }

  @override
  Future<List<VisitCustomerRemoteModel>> getCustomers() async {
    final payload = encodeData(<String, dynamic>{});

    try {
      final response = await apiClient.get(
        AppUrls.visitCustomerList,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load customers',
        );
      }

      return (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VisitCustomerRemoteModel.fromJson)
          .where((customer) => customer.id > 0)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load customers: ${e.toString()}');
    }
  }

  @override
  Future<List<VisitAddressRemoteModel>> getAddresses() async {
    final payload = encodeData(<String, dynamic>{});

    try {
      final response = await apiClient.get(
        AppUrls.visitAddressList,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load addresses',
        );
      }

      return (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VisitAddressRemoteModel.fromJson)
          .where((address) => address.id > 0)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load addresses: ${e.toString()}');
    }
  }

  @override
  Future<String> createVisit(CreateVisitParams params) async {
    final payload = encodeData({
      'visit_type': params.type.value,
      'scheduled_date': DateFormat('yyyy-MM-dd').format(params.scheduledDate),
      'visit_title': params.visitTitle.trim(),
      'description': params.description.trim(),
      if (params.startTime != null) 'start_time': params.startTime,
      if (params.endTime != null) 'end_time': params.endTime,
      'visit_status': VisitStatus.planned.value,
      'user_id': params.userId,
    });

    try {
      final response = await apiClient.post(
        AppUrls.visitCreate,
        data: {'payload': payload},
        options: Options(
          headers: const {'accept': '*/*', 'Content-Type': 'application/json'},
        ),
      );

      final responseData = response.data;
      if (responseData is String) {
        return responseData;
      }

      if (responseData is Map<String, dynamic>) {
        final success = responseData['success'];
        if (success == false) {
          throw ServerException(
            responseData['message'] as String? ?? 'Failed to create visit',
          );
        }
        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      return 'Visit created successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create visit: ${e.toString()}');
    }
  }

  @override
  Future<String> createVisitActivity(CreateVisitActivityParams params) async {
    final payload = encodeData({
      'visit_id': params.visitId,
      'user_id': params.userId,
      'activity_type': params.activityType.trim(),
      if (params.customerId != null) 'customer_id': params.customerId,
      if (params.customerDetails != null)
        'customer_details': params.customerDetails!.toJson(),
      if (params.customerAddress != null)
        'customer_address': params.customerAddress!.toJson(),
      if (params.addressId != null) 'address_id': params.addressId,
      if (params.areaId != null) 'area_id': params.areaId,
      'estimated_time': params.estimatedTime,
      'estimated_duration': params.estimatedDuration,
      'purpose': params.purpose.trim(),
    });

    try {
      final response = await apiClient.post(
        AppUrls.visitActivityCreate,
        data: {'payload': payload},
        options: Options(
          headers: const {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['success'] == false) {
          throw ServerException(
            responseData['message'] as String? ??
                'Failed to create visit activity',
          );
        }
        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      return 'Visit activity created successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create visit activity: ${e.toString()}');
    }
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}
