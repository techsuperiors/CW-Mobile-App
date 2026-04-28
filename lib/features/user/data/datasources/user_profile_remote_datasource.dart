import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/user_profile_model.dart';
import 'package:dio/dio.dart';

/// User Profile response model
class UserProfileResponse {
  final bool success;
  final String? message;
  final UserProfileModel? data;

  UserProfileResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? UserProfileModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// User Profile remote data source interface
abstract class UserProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<UserProfileExtendedFlagsModel> getExtendedProfileFlags({
    required int userId,
  });
}

/// User Profile remote data source implementation
class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final ApiClient apiClient;

  UserProfileRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserProfileModel> getUserProfile() async {
    try {
      final response = await apiClient.get(
        AppUrls.getUserProfile,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final profileResponse = UserProfileResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!profileResponse.success) {
        throw ServerException(
          profileResponse.message ?? 'Failed to get user profile',
        );
      }

      if (profileResponse.data == null) {
        throw ServerException('User profile data not found');
      }

      return profileResponse.data!;
    } on ServerException
    {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<UserProfileExtendedFlagsModel> getExtendedProfileFlags({
    required int userId,
  }) async {
    try {
      final payload = encodeData({'user_id': userId});
      final response = await apiClient.get(
        '${AppUrls.getUserProfileExtended}?payload=$payload',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw ServerException(
          responseData['message'] as String? ?? 'Failed to get user profile',
        );
      }

      final data = responseData['data'] as Map<String, dynamic>?;
      final userAttendancePolicy =
          data?['userAttendancePolicy'] as Map<String, dynamic>? ?? const {};
      final workFromHome =
          userAttendancePolicy['work_from_home'] as Map<String, dynamic>? ??
              const {};

      return UserProfileExtendedFlagsModel(
        allowAllUsers: data?['allow_all_users'] as bool? ?? false,
        enabledWorkFromHome:
            userAttendancePolicy['enabled_work_from_home'] as bool? ?? false,
        halfDayWfhEnabled:
            workFromHome['half_day_wfh_enabled'] as bool? ?? false,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        'Failed to get extended profile flags: ${e.toString()}',
      );
    }
  }
}
