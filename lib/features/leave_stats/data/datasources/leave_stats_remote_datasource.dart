import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../models/leave_stats_model.dart';

/// Abstract interface for leave stats remote data operations.
abstract class LeaveStatsRemoteDataSource {
  Future<LeaveStatsModel> getLeaveStats();
}

/// Implementation that calls the leave stats API.
class LeaveStatsRemoteDataSourceImpl implements LeaveStatsRemoteDataSource {
  final ApiClient apiClient;

  LeaveStatsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LeaveStatsModel> getLeaveStats() async {
    try {
      final response = await apiClient.get(
        AppUrls.leaveStats,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;

      debugPrint("Data:- $data");
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
