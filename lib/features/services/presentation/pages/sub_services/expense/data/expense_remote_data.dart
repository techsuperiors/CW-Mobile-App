import 'package:dio/dio.dart';

import '../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../core/error/exceptions.dart';
import '../../../../../../../core/network/api_client.dart';
import '../../../../../../../core/utils/data_encoder.dart';
import 'models/expense_detail_model.dart';
import 'models/expense_item_model.dart';

class ExpenseRemoteData {
  final ApiClient apiClient;

  ExpenseRemoteData({required this.apiClient});

  Future<List<ExpenseItemModel>> getReimbursements({required int userId}) async {
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
}
