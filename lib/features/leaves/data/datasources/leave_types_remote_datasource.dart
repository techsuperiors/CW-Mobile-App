import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/leave_type_model.dart';
import '../models/leave_apply_model.dart';
import '../models/leave_policy_model.dart';
import 'package:dio/dio.dart';

/// Leave Types remote data source interface
abstract class LeaveTypesRemoteDataSource {
  Future<LeaveTypesResponseModel> getLeaveTypes(int userId);
  Future<List<LeavePolicyModel>> getLeavePolicies(int userId);
  Future<WorkingHoursModel> getWorkingHours({
    required int userId,
    required String date,
  });
  Future<LeaveApplyResponse> applyLeave(LeaveApplyRequest request);
  Future<LeaveApplyResponse> updateLeave(UpdateLeaveRequest request);
  Future<LeaveFileUploadResponse> uploadLeaveFiles({
    required int leaveId,
    required List<File> files,
  });
  Future<String> deleteLeaveFile({
    required int leaveFileId,
    required String fileId,
  });
}

/// Leave Types remote data source implementation
class LeaveTypesRemoteDataSourceImpl implements LeaveTypesRemoteDataSource {
  final ApiClient apiClient;

  LeaveTypesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LeaveTypesResponseModel> getLeaveTypes(int userId) async {
    developer.log('Loading leave types for user_id=$userId', name: 'LeaveTypesAPI');
    try {
      final payload = {'user_id': userId};
      final encodedPayload = encodeData(payload);
      final url = '${AppUrls.leaveTypesList}?payload=$encodedPayload';

      final response = await apiClient.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final apiResponse = LeaveTypesApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(apiResponse.message ?? 'Failed to get leave types');
      }
      if (apiResponse.data == null) {
        throw ServerException('Leave types data not found');
      }
      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get leave types: ${e.toString()}');
    }
  }

  @override
  Future<List<LeavePolicyModel>> getLeavePolicies(int userId) async {
    developer.log(
      'Loading leave policy for user_id=$userId',
      name: 'LeavePolicyAPI',
    );
    try {
      final payload = {'user_id': userId};
      final encodedPayload = encodeData(payload);
      final url = '${AppUrls.leaveUserPolicy}?payload=$encodedPayload';

      final response = await apiClient.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap['success'] != true) {
        throw ServerException(
          responseMap['message']?.toString() ?? 'Failed to get leave policy',
        );
      }

      final data = responseMap['data'] as Map<String, dynamic>? ?? const {};
      final leaveConfig = data['leave_config'] as List<dynamic>? ?? const [];
      return leaveConfig
          .whereType<Map<String, dynamic>>()
          .map(LeavePolicyModel.fromJson)
          .where((policy) => policy.leaveTypeName.trim().isNotEmpty)
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get leave policy: ${e.toString()}');
    }
  }

  @override
  Future<WorkingHoursModel> getWorkingHours({
    required int userId,
    required String date,
  }) async {
    developer.log(
      'Loading working hours for user_id=$userId date=$date',
      name: 'LeaveWorkingHoursAPI',
    );
    try {
      final payload = {'user_id': userId, 'date': date};
      final encodedPayload = encodeData(payload);
      final url = '${AppUrls.attendanceUserWorkingHours}?payload=$encodedPayload';

      final response = await apiClient.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap['success'] != true) {
        throw ServerException(
          responseMap['message']?.toString() ??
              'Failed to get working hours',
        );
      }

      return WorkingHoursModel.fromJson(responseMap);
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get working hours: ${e.toString()}');
    }
  }

  @override
  Future<LeaveApplyResponse> applyLeave(LeaveApplyRequest request) async {
    // Always URL-encode the JSON payload (same format as the curl)
    final encodedPayload = encodeData(request.toJson());
    debugPrint('Encoded leave apply payload: $encodedPayload');

    try {
      late Response response;

      if (request.attachmentFiles.isNotEmpty) {
        // ── Multipart request (with files) ─────────────────────────
        // The API accepts multiple 'file' fields with the same key name
        final fileEntries = await Future.wait(
          request.attachmentFiles.map((file) async {
            final fileName = p.basename(file.path);
            return MapEntry(
              'file',
              await MultipartFile.fromFile(file.path, filename: fileName),
            );
          }),
        );

        final formData = FormData.fromMap({
          'payload': encodedPayload,
        });
        // Add each file as a separate 'file' entry
        for (final entry in fileEntries) {
          formData.files.add(entry);
        }

        response = await apiClient.post(
          AppUrls.applyLeave,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );
      } else {
        // ── JSON-only request (no files) ───────────────────────────
        response = await apiClient.post(
          AppUrls.applyLeave,
          data: {'payload': encodedPayload},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      }

      // Log full response
      final formattedJson = JsonEncoder.withIndent('  ').convert(response.data);
      developer.log('═══════════════ Leave Apply Response ════════════════', name: 'LeaveApplyAPI');
      developer.log(formattedJson, name: 'LeaveApplyAPI');
      developer.log('═════════════════════════════════════════════════════', name: 'LeaveApplyAPI');

      final leaveApplyResponse = LeaveApplyResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!leaveApplyResponse.success) {
        throw ServerException(leaveApplyResponse.message ?? 'Leave application failed');
      }
      return leaveApplyResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Leave application failed: ${e.toString()}');
    }
  }

  @override
  Future<LeaveApplyResponse> updateLeave(UpdateLeaveRequest request) async {
    final encodedPayload = encodeData(request.toJson());
    debugPrint('Encoded leave update payload: $encodedPayload');

    try {
      final response = await apiClient.put(
        AppUrls.applyLeave,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final formattedJson = JsonEncoder.withIndent('  ').convert(response.data);
      developer.log(
        '═══════════════ Leave Update Response ════════════════',
        name: 'LeaveUpdateAPI',
      );
      developer.log(formattedJson, name: 'LeaveUpdateAPI');
      developer.log(
        '══════════════════════════════════════════════════════',
        name: 'LeaveUpdateAPI',
      );

      final leaveUpdateResponse = LeaveApplyResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!leaveUpdateResponse.success) {
        throw ServerException(
          leaveUpdateResponse.message ?? 'Leave update failed',
        );
      }

      return leaveUpdateResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Leave update failed: ${e.toString()}');
    }
  }

  @override
  Future<LeaveFileUploadResponse> uploadLeaveFiles({
    required int leaveId,
    required List<File> files,
  }) async {
    final encodedPayload = encodeData({'leave_id': leaveId});

    try {
      final formData = FormData.fromMap({
        'payload': encodedPayload,
      });

      for (final file in files) {
        final fileName = p.basename(file.path);
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await apiClient.post(
        AppUrls.leaveFileUpload,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final uploadResponse = LeaveFileUploadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!uploadResponse.success) {
        throw ServerException(uploadResponse.message ?? 'Leave file upload failed');
      }

      return uploadResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Leave file upload failed: ${e.toString()}');
    }
  }

  @override
  Future<String> deleteLeaveFile({
    required int leaveFileId,
    required String fileId,
  }) async {
    try {
      final payload = LeaveFileDeleteRequest(
        leaveFileId: leaveFileId,
        fileId: fileId,
      );
      final encodedPayload = encodeData(payload.toJson());

      final response = await apiClient.put(
        AppUrls.leaveFileDelete,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final deleteResponse = LeaveFileDeleteResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!deleteResponse.success) {
        throw ServerException(
          deleteResponse.message ?? 'Failed to delete leave file',
        );
      }

      return deleteResponse.message ?? 'File document deleted successfully';
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to delete leave file: ${e.toString()}');
    }
  }
}
