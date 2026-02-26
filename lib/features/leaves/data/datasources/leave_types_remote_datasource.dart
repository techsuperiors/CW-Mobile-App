import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/leave_type_model.dart';
import '../models/leave_apply_model.dart';
import 'package:dio/dio.dart';

/// Leave Types remote data source interface
abstract class LeaveTypesRemoteDataSource {
  Future<LeaveTypesResponseModel> getLeaveTypes(int userId);
  Future<LeaveApplyResponse> applyLeave(LeaveApplyRequest request);
}

/// Leave Types remote data source implementation
class LeaveTypesRemoteDataSourceImpl implements LeaveTypesRemoteDataSource {
  final ApiClient apiClient;

  LeaveTypesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LeaveTypesResponseModel> getLeaveTypes(int userId) async {
    print("User id is $userId");
    try {
      // Encode the payload with user_id
      final payload = {'user_id': userId};
      final encodedPayload = encodeData(payload);

      // Build the URL with encoded payload as query parameter
      final url = '${AppUrls.leaveTypesList}?payload=$encodedPayload';

      final response = await apiClient.get(
        url,
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

  @override
  Future<LeaveApplyResponse> applyLeave(LeaveApplyRequest request) async {
    final encodedData = encodeData(request);
    debugPrint('Encoded leave apply data: $encodedData');
    try {
      final response = await apiClient.post(
        AppUrls.applyLeave,
        data: {
          'payload': encodedData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      // Print full response data without truncation
      // Use JsonEncoder with indentation for better readability
      final encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(response.data);
      
      developer.log(
        '═══════════════════════════════════════════════════════',
        name: 'LeaveApplyAPI',
      );
      developer.log(
        'Leave apply response (full):',
        name: 'LeaveApplyAPI',
      );
      developer.log(
        formattedJson,
        name: 'LeaveApplyAPI',
      );
      developer.log(
        '═══════════════════════════════════════════════════════',
        name: 'LeaveApplyAPI',
      );
      
      final leaveApplyResponse = LeaveApplyResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!leaveApplyResponse.success) {
        throw ServerException(
          leaveApplyResponse.message ?? 'Leave application failed',
        );
      }

      return leaveApplyResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Leave application failed: ${e.toString()}');
    }
  }
}

