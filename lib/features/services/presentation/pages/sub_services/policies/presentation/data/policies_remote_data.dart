import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../domain/models/policy_model.dart';

class PoliciesRemoteData {
  PoliciesRemoteData._();

  static Future<List<PolicyModel>> getPolicies({int pageSize = 15}) async {
    final clientId = _resolveClientId();
    if (clientId <= 0) {
      throw const ServerException('Unable to resolve client id');
    }

    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final allPolicies = <PolicyModel>[];
    final seenPolicyIds = <int>{};
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final payload = encodeData({
        'client_id': clientId,
        'created_by': [],
        'created_at': [],
        'department_name': [],
        'policy_name': [],
        'policy_status': 'ALL',
        'page': page,
        'limit': pageSize,
      });

      final response = await apiClient.get(
        '${AppUrls.employeePoliciesList}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load policies',
        );
      }

      final rawList = data['data'] as List<dynamic>? ?? const [];
      final pagePolicies =
          rawList
              .whereType<Map<String, dynamic>>()
              .map(PolicyModel.fromJson)
              .toList();

      final newPolicies =
          pagePolicies.where((policy) => seenPolicyIds.add(policy.id)).toList();
      allPolicies.addAll(newPolicies);

      hasMore = rawList.length >= pageSize && newPolicies.isNotEmpty;
      page += 1;
    }

    return allPolicies;
  }

  static Future<PolicyModel> getPolicyDetail(int policyId) async {
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final payload = encodeData({'policies_id': policyId});

    final response = await apiClient.get(
      '${AppUrls.employeePolicyDetail}?payload=$payload',
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid server response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to load policy details',
      );
    }

    final detail = data['data'] as Map<String, dynamic>?;
    if (detail == null) {
      throw const ServerException('Policy details not found');
    }

    return PolicyModel.fromJson(detail);
  }

  static Future<String> uploadSignature(Uint8List signatureBytes) async {
    final clientId = _resolveClientId();
    if (clientId <= 0) {
      throw const ServerException('Unable to resolve client id');
    }

    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final normalizedSignatureBytes = await _normalizeSignatureImage(
      signatureBytes,
    );

    debugPrint(
      'Policy signature upload started. Original bytes: ${signatureBytes.length}, normalized bytes: ${normalizedSignatureBytes.length}',
    );

    final formData = FormData.fromMap({
      'signature': MultipartFile.fromBytes(
        normalizedSignatureBytes,
        filename: 'signature.png',
        contentType: DioMediaType.parse('image/png'),
      ),
      'payload': encodeData({'client_id': clientId}),
    });

    final response = await apiClient.post(
      AppUrls.clientFileUpload,
      data: formData,
    );

    debugPrint('Policy signature upload raw response: ${response.data}');

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid upload response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to upload signature',
      );
    }

    final fileUrl = data['file_url'] as String?;
    if (fileUrl == null || fileUrl.isEmpty) {
      throw const ServerException('Signature URL missing in upload response');
    }

    debugPrint('Policy signature uploaded successfully. File URL: $fileUrl');

    return fileUrl;
  }

  static Future<Uint8List> _normalizeSignatureImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return bytes;
      }

      final width = image.width;
      final height = image.height;
      final rgba = byteData.buffer.asUint8List();

      int minX = width;
      int minY = height;
      int maxX = -1;
      int maxY = -1;

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final index = (y * width + x) * 4;
          final r = rgba[index];
          final g = rgba[index + 1];
          final b = rgba[index + 2];
          final a = rgba[index + 3];

          final isVisibleStroke =
              a > 10 && !(r > 245 && g > 245 && b > 245);

          if (isVisibleStroke) {
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }

      if (maxX < minX || maxY < minY) {
        return bytes;
      }

      const displayWidth = 220.0;
      const displayHeight = 90.0;
      const resolutionMultiplier = 4.0;
      final outputWidth = displayWidth * resolutionMultiplier;
      final outputHeight = displayHeight * resolutionMultiplier;
      final horizontalPadding = 12.0 * resolutionMultiplier;
      final verticalPadding = 10.0 * resolutionMultiplier;

      final sourceRect = ui.Rect.fromLTWH(
        minX.toDouble(),
        minY.toDouble(),
        (maxX - minX + 1).toDouble(),
        (maxY - minY + 1).toDouble(),
      );

      final availableWidth = outputWidth - (horizontalPadding * 2);
      final availableHeight = outputHeight - (verticalPadding * 2);
      final scale = [
        availableWidth / sourceRect.width,
        availableHeight / sourceRect.height,
      ].reduce((a, b) => a < b ? a : b);

      final drawWidth = sourceRect.width * scale;
      final drawHeight = sourceRect.height * scale;
      final destRect = ui.Rect.fromLTWH(
        (outputWidth - drawWidth) / 2,
        (outputHeight - drawHeight) / 2,
        drawWidth,
        drawHeight,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint =
          ui.Paint()
            ..isAntiAlias = true
            ..filterQuality = ui.FilterQuality.high;

      canvas.drawImageRect(image, sourceRect, destRect, paint);

      final picture = recorder.endRecording();
      final normalizedImage = await picture.toImage(
        outputWidth.toInt(),
        outputHeight.toInt(),
      );
      final pngBytes = await normalizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return pngBytes?.buffer.asUint8List() ?? bytes;
    } catch (error) {
      debugPrint('Policy signature normalization failed: $error');
      return bytes;
    }
  }

  static Future<String> uploadSignedPdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final clientId = _resolveClientId();
    if (clientId <= 0) {
      throw const ServerException('Unable to resolve client id');
    }

    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    debugPrint(
      'Policy signed PDF upload started. Bytes length: ${pdfBytes.length}, fileName: $fileName',
    );

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        pdfBytes,
        filename: fileName,
        contentType: DioMediaType.parse('application/pdf'),
      ),
      'payload': encodeData({'client_id': clientId}),
    });

    final response = await apiClient.post(
      AppUrls.clientFileUpload,
      data: formData,
    );

    debugPrint('Policy signed PDF upload raw response: ${response.data}');

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid PDF upload response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to upload signed agreement',
      );
    }

    final fileUrl = data['file_url'] as String?;
    if (fileUrl == null || fileUrl.isEmpty) {
      throw const ServerException('Signed agreement URL missing in upload response');
    }

    debugPrint('Policy signed PDF uploaded successfully. File URL: $fileUrl');

    return fileUrl;
  }

  static Future<void> submitPolicyAcknowledgment({
    required int policyId,
    required int userId,
    required bool eConsentRequired,
    required String signatureUrl,
  }) async {
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );

    final payload = encodeData({
      'policy_id': policyId,
      'user_id': userId,
      'acknowledged': true,
      'econsent_required': eConsentRequired,
      'signature_url': signatureUrl,
      'status': 'Acknowledged',
    });

    final response = await apiClient.post(
      AppUrls.employeePolicyMapperUpdate,
      data: {'payload': payload},
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const ServerException('Invalid acknowledgment response');
    }
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to acknowledge policy',
      );
    }
  }

  static int _resolveClientId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  static int resolveUserId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final userId = decoded?['user_id'];
    if (userId is int) return userId;
    if (userId is String) return int.tryParse(userId) ?? 0;
    return 0;
  }
}
