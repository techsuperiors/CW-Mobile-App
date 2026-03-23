import 'package:flutter/cupertino.dart';

import '../../../../../../../../core/network/api_service.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/error/exceptions.dart';

abstract class ApproversRemoteDataSource {
  Future<Map<String, dynamic>> getApprovers(
    String endpoint,
    Map<String, dynamic> payload,
  );
}

class ApproversRemoteDataSourceImpl implements ApproversRemoteDataSource {
  final ApiService apiService;

  ApproversRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Map<String, dynamic>> getApprovers(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final encodedPayload = encodeData(payload);
    final url = '$endpoint?payload=$encodedPayload';

    final response = await apiService.getNew<Map<String, dynamic>>(
      url,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (response.error != null || response.data == null) {
      throw ServerException(
        response.error?.message ?? 'Failed to fetch approvers',
      );
    }

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid response format');
    }

    return data;
  }
}
