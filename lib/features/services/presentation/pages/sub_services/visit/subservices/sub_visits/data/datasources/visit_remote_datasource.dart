import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../../../core/utils/token_storage.dart';
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

  Future<VisitDetailRemoteModel> getVisitDetails(int visitId);

  Future<VisitActivityDetailRemoteModel> getVisitActivityDetails(int activityId);

  Future<String> createVisitActivity(CreateVisitActivityParams params);

  Future<String> updateVisitActivity(UpdateVisitActivityParams params);

  Future<String> startVisitActivity(StartVisitActivityParams params);

  Future<String> completeVisitActivity(CompleteVisitActivityParams params);

  Future<String> deleteVisitActivity(int activityId);
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
  Future<VisitDetailRemoteModel> getVisitDetails(int visitId) async {
    final payload = encodeData({'visit_id': visitId});

    try {
      final response = await apiClient.get(
        AppUrls.visitDetails,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load visit details',
        );
      }

      final detailJson =
          data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : null;
      if (detailJson == null) {
        throw const ServerException('Visit details not found');
      }

      return VisitDetailRemoteModel.fromJson(detailJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load visit details: ${e.toString()}');
    }
  }

  @override
  Future<VisitActivityDetailRemoteModel> getVisitActivityDetails(
    int activityId,
  ) async {
    final payload = encodeData({'activity_id': activityId});

    try {
      final response = await apiClient.get(
        AppUrls.visitActivityDetails,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load visit activity details',
        );
      }

      final detailJson =
          data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : null;
      if (detailJson == null) {
        throw const ServerException('Visit activity details not found');
      }

      return VisitActivityDetailRemoteModel.fromJson(detailJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to load visit activity details: ${e.toString()}',
      );
    }
  }

  @override
  Future<String> createVisitActivity(CreateVisitActivityParams params) async {
    final payload = encodeData({
      'visit_id': params.visitId,
      'user_id': params.userId,
      'activity_type': params.activityType.trim(),
      'customer_id': params.customerId,
      'customer_details': params.customerDetails?.toJson(),
      'customer_address': params.customerAddress?.toJson(),
      'address_id': params.addressId,
      'area_id': params.areaId,
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

  @override
  Future<String> updateVisitActivity(UpdateVisitActivityParams params) async {
    final payload = encodeData(params.toJson());

    try {
      final response = await apiClient.post(
        AppUrls.visitActivityUpdate,
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
        if (responseData['success'] == false) {
          throw ServerException(
            responseData['message'] as String? ??
                'Failed to update visit activity',
          );
        }
        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      return 'Visit activity updated successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update visit activity: ${e.toString()}');
    }
  }

  @override
  Future<String> startVisitActivity(StartVisitActivityParams params) async {
    try {
      final selfieUrl = await _uploadVisitActivityImage(
        params.activityCheckinSelfiePath,
      );
      final payload = encodeData({
        'activity_id': params.activityId,
        'activity_start_lat': params.activityStartLat,
        'activity_start_lng': params.activityStartLng,
        'activity_checkin_selfie': selfieUrl,
      });

      final response = await apiClient.post(
        AppUrls.visitActivityStart,
        data: {'payload': payload},
        options: Options(
          headers: const {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to start visit activity',
        );
      }

      final message = data['message']?.toString().trim();
      return (message != null && message.isNotEmpty)
          ? message
          : 'Visit activity started successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to start visit activity: ${e.toString()}');
    }
  }

  @override
  Future<String> completeVisitActivity(CompleteVisitActivityParams params) async {
    try {
      final selfieUrl = await _uploadVisitActivityImage(
        params.activityCheckoutSelfiePath,
      );
      final payload = encodeData({
        'activity_id': params.activityId,
        'activity_end_lat': params.activityEndLat,
        'activity_end_lng': params.activityEndLng,
        'activity_checkout_selfie': selfieUrl,
        'activaty_end_lat': params.activityEndLat,
        'activaty_end_lng': params.activityEndLng,
        'activaty_checkout_selfie': selfieUrl,
      });

      final response = await apiClient.post(
        AppUrls.visitActivityEnd,
        data: {'payload': payload},
        options: Options(
          headers: const {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to complete visit activity',
        );
      }

      final message = data['message']?.toString().trim();
      return (message != null && message.isNotEmpty)
          ? message
          : 'Visit activity completed successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to complete visit activity: ${e.toString()}',
      );
    }
  }

  @override
  Future<String> deleteVisitActivity(int activityId) async {
    final payload = encodeData({'activity_id': activityId});

    try {
      final response = await apiClient.delete(
        AppUrls.visitActivityDelete,
        queryParameters: {'payload': payload},
        options: Options(
          headers: const {
            'accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to delete visit activity',
        );
      }

      final message = data['message']?.toString().trim();
      return (message != null && message.isNotEmpty)
          ? message
          : 'Activity deleted';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete visit activity: ${e.toString()}');
    }
  }

  Future<String> _uploadVisitActivityImage(String filePath) async {
    final clientId = _resolveClientId();
    if (clientId <= 0) {
      throw const ServerException('Unable to resolve client id');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
      ),
      'payload': encodeData({'client_id': clientId}),
    });

    final response = await apiClient.post(
      AppUrls.clientFileUpload,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid upload response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to upload activity selfie',
      );
    }

    final fileUrl = data['file_url']?.toString().trim();
    if (fileUrl == null || fileUrl.isEmpty) {
      throw const ServerException('Uploaded selfie URL missing in response');
    }

    return fileUrl;
  }
}

int _resolveClientId() {
  final token = TokenStorage.getToken();
  if (token == null || token.isEmpty) {
    return 0;
  }
  final decoded = decodeData<Map<String, dynamic>>(token);
  final clientId = decoded?['client_id'];
  if (clientId is int) {
    return clientId;
  }
  if (clientId is String) {
    return int.tryParse(clientId.trim()) ?? 0;
  }
  if (clientId is num) {
    return clientId.toInt();
  }
  return 0;
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}
