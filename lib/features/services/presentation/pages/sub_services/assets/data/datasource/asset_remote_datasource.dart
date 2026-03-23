import 'package:flutter/material.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../model/asset_model_data.dart';
import '../model/asset_request_model.dart';
import '../model/asset_category_model.dart';

/// Remote data source contract for asset operations
abstract class AssetRemoteDataSource {
  Future<List<AssetModel>> getAssets();
  Future<List<AssetRequestModel>> getAssetRequests(int userId);
  Future<List<AssetCategoryModel>> getAssetCategories(int userId);
  Future<void> createAssetRequest({
    required int userId,
    required int assetCategoryId,
    required int assetSubCategoryId,
    required String reason,
    required String requestType,
  });
}

/// Remote data source implementation handling API calls
class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  final ApiClient apiClient;

  AssetRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<AssetModel>> getAssets() async {
    try {
      // Make GET request to fetch allocated assets
      final response = await apiClient.get(AppUrls.assetList);

      debugPrint('Asset list response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      // Validate response success flag
      if (responseData['success'] != true) {
        throw ServerException('Failed to fetch assets');
      }

      // Parse JSON array into list of AssetModel objects
      final dataList = responseData['data'] as List<dynamic>? ?? [];
      final assets =
          dataList
              .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
              .toList();

      // Return parsed asset list
      return assets;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch assets: ${e.toString()}');
    }
  }

  @override
  Future<List<AssetRequestModel>> getAssetRequests(int userId) async {
    try {
      final payload = {'user_id': userId};
      final encodedPayload = encodeData(payload);

      final response = await apiClient.get(
        '${AppUrls.assetRequestList}?query=$encodedPayload',
      );

      debugPrint('Asset request list response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw ServerException('Failed to fetch asset requests');
      }

      final dataList = responseData['data'] as List<dynamic>? ?? [];
      return dataList
          .map(
            (json) => AssetRequestModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch asset requests: ${e.toString()}');
    }
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories(int userId) async {
    try {
      final payload = {'user_id': userId};
      final encodedPayload = encodeData(payload);

      final response = await apiClient.get(
        '${AppUrls.assetCategoryList}?payload=$encodedPayload',
      );

      debugPrint('Asset categories response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw ServerException('Failed to fetch asset categories');
      }

      final dataList = responseData['data'] as List<dynamic>? ?? [];
      return dataList
          .map(
            (json) => AssetCategoryModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to fetch asset categories: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> createAssetRequest({
    required int userId,
    required int assetCategoryId,
    required int assetSubCategoryId,
    required String reason,
    required String requestType,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'asset_category_id': assetCategoryId,
        'asset_subCategory_id': assetSubCategoryId,
        'reason': reason,
        'request_type': requestType,
      };
      final encodedPayload = encodeData(payload);

      debugPrint('Create asset request payload: $payload');

      final response = await apiClient.post(
        AppUrls.createAssetRequest,
        data: {'payload': encodedPayload},
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw ServerException(
          responseData['message'] as String? ??
              'Failed to create asset request',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create asset request: ${e.toString()}');
    }
  }
}
