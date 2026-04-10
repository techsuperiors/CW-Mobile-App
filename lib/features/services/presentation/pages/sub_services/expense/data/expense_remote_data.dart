import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../core/error/exceptions.dart';
import '../../../../../../../core/network/api_client.dart';
import '../../../../../../../core/utils/data_encoder.dart';
import 'models/expense_detail_model.dart';
import 'models/expense_item_model.dart';

class ExpenseApprovalListPage {
  final List<ExpenseItemModel> items;
  final int totalCount;

  const ExpenseApprovalListPage({
    required this.items,
    required this.totalCount,
  });
}

class ExpensePolicySelection {
  final int id;
  final String policyName;
  final String currency;
  final List<String> expenseTypes;

  const ExpensePolicySelection({
    required this.id,
    required this.policyName,
    required this.currency,
    required this.expenseTypes,
  });
}

class ExpenseTripOption {
  final int id;
  final String tripName;
  final String? travelType;

  const ExpenseTripOption({
    required this.id,
    required this.tripName,
    required this.travelType,
  });
}

class ExpenseRemoteData {
  final ApiClient apiClient;

  ExpenseRemoteData({required this.apiClient});

  Future<ExpensePolicySelection> getUserExpensePolicy() async {
    try {
      final response = await apiClient.get(
        AppUrls.expenseUserPolicy,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to load expense policy',
        );
      }

      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final policy = data['ExpensePolicy'] as Map<String, dynamic>? ?? const {};
      final expenseTypes =
          (data['expense_types'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList();

      return ExpensePolicySelection(
        id: (policy['id'] as num?)?.toInt() ?? 0,
        policyName: policy['policy_name']?.toString() ?? '',
        currency: policy['currency']?.toString() ?? 'INR',
        expenseTypes: expenseTypes,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load expense policy: $e');
    }
  }

  Future<List<ExpenseTripOption>> getUserTrips({required int userId}) async {
    try {
      final encodedPayload = encodeData({'user_id': userId});
      final response = await apiClient.get(
        '${AppUrls.userTripList}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to load user trips',
        );
      }

      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(
            (trip) => ExpenseTripOption(
              id: (trip['id'] as num?)?.toInt() ?? 0,
              tripName: trip['trip_name']?.toString() ?? '',
              travelType: trip['travel_type']?.toString(),
            ),
          )
          .where((trip) => trip.id > 0 && trip.tripName.trim().isNotEmpty)
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load user trips: $e');
    }
  }

  Future<List<ExpenseItemModel>> getReimbursements({
    required int userId,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'expense_names': <String>[],
        'expense_between': <String>[],
        'expense_type': <String>[],
        'status': <String>[],
      };
      final encodedPayload = encodeData(payload);

      final response = await apiClient.get(
        '${AppUrls.expenseList}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;

      print(body);
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to load reimbursements',
        );
      }

      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ExpenseItemModel.fromJson)
          .toList()
        ..sort((a, b) => b.fromDate.compareTo(a.fromDate));
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load reimbursements: $e');
    }
  }

  Future<ExpenseApprovalListPage> getExpenseApprovals({
    required RequestAudienceScope scope,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final payload = {
        'employeeID': <String>[],
        'date': <String>[],
        'approved_date': <String>[],
        'approver_status': <String>[],
        'request_type': [scope.attendanceRequestType],
        'page': page,
        'limit': limit,
      };
      final encodedPayload = encodeData(payload);

      final response = await apiClient.get(
        '${AppUrls.expenseApprovalList}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to load expense approvals',
        );
      }

      final data = body['data'] as List<dynamic>? ?? const [];
      final items =
          data
              .whereType<Map<String, dynamic>>()
              .map(ExpenseItemModel.fromJson)
              .toList()
            ..sort((a, b) => b.fromDate.compareTo(a.fromDate));

      return ExpenseApprovalListPage(
        items: items,
        totalCount:
            (body['totalExpenseCount'] as num?)?.toInt() ?? items.length,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load expense approvals: $e');
    }
  }

  Future<ExpenseDetailModel> getExpenseDetails({required int expenseId}) async {
    try {
      final encodedPayload = encodeData({'expense_id': expenseId});
      final response = await apiClient.get(
        '${AppUrls.expenseDetails}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to load expense details',
        );
      }

      return ExpenseDetailModel.fromJson(body);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load expense details: $e');
    }
  }

  Future<String> updateExpenseComments({
    required int expenseId,
    required List<Map<String, dynamic>> comments,
  }) async {
    try {
      final encodedPayload = encodeData({
        'expense_id': expenseId,
        'comments': comments,
      });

      final response = await apiClient.put(
        AppUrls.expenseComments,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to update expense comments',
        );
      }

      return body['message']?.toString() ?? 'Comment updated successfully';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update expense comments: $e');
    }
  }

  Future<String> withdrawExpense({required int expenseId}) async {
    try {
      final encodedPayload = encodeData({
        'expense_id': expenseId,
        'approval_status': 'Withdrawn',
      });
      debugPrint('payload:- $encodedPayload');

      final response = await apiClient.post(
        AppUrls.expenseWithdraw,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      debugPrint('Response:- ${response.data}');
      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to withdraw expense request',
        );
      }

      return body['message']?.toString() ??
          'Expense request successfully withdrawn';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to withdraw expense request: $e');
    }
  }

  Future<String> updateExpenseApprovalStatus({
    required int expenseId,
    required int expenseApprovalId,
    required int approverId,
    required String approvalStatus,
  }) async {
    try {
      final encodedPayload = encodeData({
        'expenseList': [
          {
            'expense_id': expenseId,
            'expense_approval_id': expenseApprovalId,
            'approver_id': approverId,
            'approval_status': approvalStatus,
          },
        ],
      });

      final response = await apiClient.put(
        AppUrls.expenseBulkStatusUpdate,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ??
              'Failed to update expense request status',
        );
      }

      return body['message']?.toString() ??
          'Expense request updated successfully.';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update expense request status: $e');
    }
  }

  Future<String> updateExpense({
    required int expenseId,
    required String expenseType,
    required String expenseName,
    required String amount,
    required DateTime fromDate,
    required DateTime toDate,
    required int expensePolicyId,
    required String currency,
    int? tripId,
    String? tripType,
    required List<ExpenseDocument> existingFiles,
    required List<File> newFiles,
    String? invoiceNumber,
    String? description,
  }) async {
    try {
      final payload = <String, dynamic>{
        'duration_type':
            fromDate.year == toDate.year &&
                    fromDate.month == toDate.month &&
                    fromDate.day == toDate.day
                ? 'single'
                : 'multiple',
        'expense_type': expenseType,
        'expense_name': expenseName,
        'amount': amount,
        'from': fromDate.toUtc().toIso8601String(),
        'to': toDate.toUtc().toIso8601String(),
        'no_of_days': toDate.difference(fromDate).inDays + 1,
        'files':
            existingFiles
                .map(
                  (file) => {'id': file.id, 'url': file.url, 'name': file.name},
                )
                .toList(),
        'currency': currency,
        'expense_policy_id': expensePolicyId,
        'expense_id': expenseId,
      };

      if (tripId != null) {
        payload['trip_id'] = tripId;
      }
      if ((tripType ?? '').trim().isNotEmpty) {
        payload['trip_type'] = tripType!.trim().toLowerCase();
      }
      if ((invoiceNumber ?? '').trim().isNotEmpty) {
        payload['invoice_number'] = invoiceNumber!.trim();
      }
      if ((description ?? '').trim().isNotEmpty) {
        payload['description'] = description!.trim();
      }

      final encodedPayload = encodeData(payload);
      final formData = FormData.fromMap({'payload': encodedPayload});

      if (newFiles.isNotEmpty) {
        final fileEntries = await Future.wait(
          newFiles.map((file) async {
            final fileName = p.basename(file.path);
            return MapEntry(
              'uploads',
              await MultipartFile.fromFile(file.path, filename: fileName),
            );
          }),
        );
        for (final entry in fileEntries) {
          formData.files.add(entry);
        }
      }

      final response = await apiClient.post(
        AppUrls.expenseUpdate,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to update expense',
        );
      }

      return body['message']?.toString() ?? 'Expense updated successfully.';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update expense: $e');
    }
  }

  Future<String> createExpense({
    required int userId,
    required String expenseType,
    required String expenseName,
    required String amount,
    required DateTime fromDate,
    required DateTime toDate,
    required int expensePolicyId,
    required String currency,
    int? tripId,
    String? tripType,
    required List<File> newFiles,
    String? invoiceNumber,
    String? description,
  }) async {
    try {
      final payload = <String, dynamic>{
        'duration_type':
            fromDate.year == toDate.year &&
                    fromDate.month == toDate.month &&
                    fromDate.day == toDate.day
                ? 'single'
                : 'multiple',
        'expense_name': expenseName,
        'expense_type': expenseType,
        'amount': amount,
        'from': fromDate.toUtc().toIso8601String(),
        'to': toDate.toUtc().toIso8601String(),
        'no_of_days': toDate.difference(fromDate).inDays + 1,
        'currency': currency,
        'expense_policy_id': expensePolicyId,
        'user_id': userId,
      };

      if (tripId != null) {
        payload['trip_id'] = tripId;
      }
      if ((tripType ?? '').trim().isNotEmpty) {
        payload['trip_type'] = tripType!.trim().toLowerCase();
      }
      if ((invoiceNumber ?? '').trim().isNotEmpty) {
        payload['invoice_number'] = invoiceNumber!.trim();
      }
      if ((description ?? '').trim().isNotEmpty) {
        payload['description'] = description!.trim();
      }

      final encodedPayload = encodeData(payload);
      final formData = FormData.fromMap({'payload': encodedPayload});

      if (newFiles.isNotEmpty) {
        final fileEntries = await Future.wait(
          newFiles.map((file) async {
            final fileName = p.basename(file.path);
            return MapEntry(
              'uploads',
              await MultipartFile.fromFile(file.path, filename: fileName),
            );
          }),
        );
        for (final entry in fileEntries) {
          formData.files.add(entry);
        }
      }

      final response = await apiClient.post(
        AppUrls.expenseCreate,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to create expense',
        );
      }

      return body['message']?.toString() ?? 'Expense request created successfully.';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create expense: $e');
    }
  }

  Future<String> deleteExpenseFile({
    required String fileId,
    required int expenseId,
  }) async {
    try {
      final encodedPayload = encodeData({
        'file_id': fileId,
        'expense_id': expenseId,
      });

      final response = await apiClient.post(
        AppUrls.expenseFileDelete,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw ServerException(
          body['message']?.toString() ?? 'Failed to delete expense file',
        );
      }

      return body['message']?.toString() ?? 'Expense file deleted successfully.';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete expense file: $e');
    }
  }
}
