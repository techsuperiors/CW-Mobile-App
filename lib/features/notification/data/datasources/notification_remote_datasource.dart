import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<int> getNotificationCount();
  Future<void> viewNotifications();
  Future<void> readNotification(int notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final payload = {'isPagination': false, 'module_name': 'hrms'};

      final encodedPayload = encodeData(payload);

      final response = await apiClient.get(
        '${AppUrls.notificationList}?payload=$encodedPayload',
      );
      final responseModel = NotificationResponseModel.fromJson(response.data);
      if (responseModel.success) {
        return responseModel.allData.isNotEmpty
            ? responseModel.allData
            : responseModel.paginationData;
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  @override
  Future<int> getNotificationCount() async {
    try {
      final response = await apiClient.get(AppUrls.notificationCount);
      if (response.data['success'] == true) {
        return response.data['count'] as int;
      } else {
        throw Exception('Failed to load notification count');
      }
    } catch (e) {
      throw Exception('Failed to load notification count: $e');
    }
  }

  @override
  Future<void> viewNotifications() async {
    try {
      final response = await apiClient.post(AppUrls.notificationView, data: {});
      if (response.data['success'] != true) {
        throw Exception('Failed to view notifications');
      }
    } catch (e) {
      throw Exception('Failed to view notifications: $e');
    }
  }

  @override
  Future<void> readNotification(int notificationId) async {
    try {
      final payload = {'notification_id': notificationId};
      final encodedPayload = encodeData(payload);

      final response = await apiClient.post(
        AppUrls.notificationRead,
        data: {'payload': encodedPayload},
      );
      if (response.data['success'] != true) {
        throw Exception('Failed to read notification');
      }
    } catch (e) {
      throw Exception('Failed to read notification: $e');
    }
  }
}
