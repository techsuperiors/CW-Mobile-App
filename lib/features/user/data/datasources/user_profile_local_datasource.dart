import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_profile_model.dart';

abstract class UserProfileLocalDataSource {
  Future<void> cacheUserProfile({
    required UserProfileModel profile,
    required String sessionToken,
  });

  Future<UserProfileModel?> getCachedUserProfile({
    required String sessionToken,
  });

  Future<void> clearCachedUserProfile();
}

class UserProfileLocalDataSourceImpl implements UserProfileLocalDataSource {
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<void> cacheUserProfile({
    required UserProfileModel profile,
    required String sessionToken,
  }) async {
    try {
      final prefs = await _prefs();
      await prefs.setString(
        AppConstants.userProfileCacheKey,
        jsonEncode(profile.toJson()),
      );
      await prefs.setString(
        AppConstants.userProfileCacheTokenKey,
        sessionToken,
      );
    } catch (_) {
      throw const CacheException(AppStrings.failedToCacheUser);
    }
  }

  @override
  Future<UserProfileModel?> getCachedUserProfile({
    required String sessionToken,
  }) async {
    try {
      final prefs = await _prefs();
      final cachedToken = prefs.getString(
        AppConstants.userProfileCacheTokenKey,
      );
      if (cachedToken == null || cachedToken != sessionToken) {
        return null;
      }

      final rawProfile = prefs.getString(AppConstants.userProfileCacheKey);
      if (rawProfile == null || rawProfile.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(rawProfile);
      if (decoded is! Map<String, dynamic>) {
        throw const CacheException(AppStrings.failedToGetCachedUser);
      }

      return UserProfileModel.fromJson(decoded);
    } on CacheException {
      rethrow;
    } catch (_) {
      throw const CacheException(AppStrings.failedToGetCachedUser);
    }
  }

  @override
  Future<void> clearCachedUserProfile() async {
    try {
      final prefs = await _prefs();
      await prefs.remove(AppConstants.userProfileCacheKey);
      await prefs.remove(AppConstants.userProfileCacheTokenKey);
    } catch (_) {
      throw const CacheException(AppStrings.failedToClearCache);
    }
  }
}
