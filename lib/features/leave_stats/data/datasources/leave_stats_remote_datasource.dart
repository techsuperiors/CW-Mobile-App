import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/utils/data_encoder.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../models/leave_stats_model.dart';

/// Abstract interface for leave stats remote data operations.
abstract class LeaveStatsRemoteDataSource {
  Future<LeaveStatsModel> getLeaveStats({
    String? startDate,
    String? endDate,
  });
}

/// Implementation that calls the leave stats API.
class LeaveStatsRemoteDataSourceImpl implements LeaveStatsRemoteDataSource {
  final ApiClient apiClient;

  LeaveStatsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LeaveStatsModel> getLeaveStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final payload = encodeData({
        'start_date': startDate ?? '',
        'end_date': endDate ?? '',
      });
      final response = await apiClient.get(
        '${AppUrls.leaveStats}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;

      debugPrint("Dataa:- $data");
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load leave stats',
        );
      }

      final statsData = data['data'] as Map<String, dynamic>?;
      if (statsData == null) {
        throw ServerException('Leave stats data not found');
      }

      return LeaveStatsModel.fromJson(statsData);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load leave stats: ${e.toString()}');
    }
  }
}
