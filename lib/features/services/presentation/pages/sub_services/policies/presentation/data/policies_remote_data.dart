import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../domain/models/policy_model.dart';

class PoliciesRemoteData {
  PoliciesRemoteData._();

  static Future<List<PolicyModel>> getPolicies() async {
    final clientId = _resolveClientId();
    if (clientId <= 0) {
      throw const ServerException('Unable to resolve client id');
    }

    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final payload = encodeData({
      'client_id': clientId,
      'created_by': [],
      'created_at': [],
      'department_name': [],
      'policy_name': [],
      'policy_status': 'ALL',
      'page': 1,
      'limit': 15,
    });

    final response = await apiClient.get(
      '${AppUrls.employeePoliciesList}?payload=$payload',
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid server response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to load policies',
      );
    }

    final rawList = data['data'] as List<dynamic>? ?? const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PolicyModel.fromJson)
        .toList();
  }

  static Future<PolicyModel> getPolicyDetail(int policyId) async {
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final payload = encodeData({'policies_id': policyId});

    final response = await apiClient.get(
      '${AppUrls.employeePolicyDetail}?payload=$payload',
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid server response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to load policy details',
      );
    }

    final detail = data['data'] as Map<String, dynamic>?;
    if (detail == null) {
      throw const ServerException('Policy details not found');
    }

    return PolicyModel.fromJson(detail);
  }

  static Future<String> uploadSignature(Uint8List signatureBytes) async {
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        signatureBytes,
        filename: 'policy_signature.png',
        contentType: DioMediaType.parse('image/png'),
      ),
    });

    final response = await apiClient.post(
      AppUrls.clientFileUpload,
      data: formData,
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid upload response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to upload signature',
      );
    }

    final fileUrl = data['file_url'] as String?;
    if (fileUrl == null || fileUrl.isEmpty) {
      throw const ServerException('Signature URL missing in upload response');
    }

    return fileUrl;
  }

  static Future<void> submitPolicyAcknowledgment({
    required int policyId,
    required int userId,
    required bool eConsentRequired,
    required String signatureUrl,
  }) async {
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final payload = encodeData({
      'policy_id': policyId,
      'user_id': userId,
      'acknowledged': true,
      'econsent_required': eConsentRequired,
      'signature_url': signatureUrl,
      'status': 'Acknowledged',
    });

    final response = await apiClient.post(
      AppUrls.employeePolicyMapperUpdate,
      data: {'payload': payload},
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid acknowledgment response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to acknowledge policy',
      );
    }
  }

  static int _resolveClientId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  static int resolveUserId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final userId = decoded?['user_id'];
    if (userId is int) return userId;
    if (userId is String) return int.tryParse(userId) ?? 0;
    return 0;
  }
}
