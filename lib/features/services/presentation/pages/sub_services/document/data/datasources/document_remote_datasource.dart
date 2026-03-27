import 'package:dio/dio.dart';

import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../models/document_remote_models.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentDirectoryRemoteModel>> getUserDirectories();
  Future<DocumentDirectoryDetailsRemoteModel> getDirectoryDetails(
    int directoryId,
  );
  Future<List<AgreementDocumentRemoteModel>> getEmployeeAgreementDocuments();
  Future<void> deleteDocument({
    required int directoryId,
    required int documentId,
  });
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final ApiClient apiClient;

  DocumentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<DocumentDirectoryRemoteModel>> getUserDirectories() async {
    try {
      final response = await apiClient.get(
        AppUrls.documentUserDirectory,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final json = response.data as Map<String, dynamic>;
      if (json['success'] != true) {
        throw ServerException(
          (json['message'] as String?) ?? 'Failed to load document folders',
        );
      }

      final data = json['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(DocumentDirectoryRemoteModel.fromJson)
          .toList();
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to load document folders: $e');
    }
  }

  @override
  Future<DocumentDirectoryDetailsRemoteModel> getDirectoryDetails(
    int directoryId,
  ) async {
    try {
      final payload = encodeData({'directory_id': directoryId});
      final response = await apiClient.get(
        '${AppUrls.documentDirectoryDetails}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final json = response.data as Map<String, dynamic>;
      if (json['success'] != true) {
        throw ServerException(
          (json['message'] as String?) ?? 'Failed to load directory details',
        );
      }

      return DocumentDirectoryDetailsRemoteModel.fromJson(json);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to load directory details: $e');
    }
  }

  @override
  Future<List<AgreementDocumentRemoteModel>> getEmployeeAgreementDocuments() async {
    try {
      final userId = _resolveUserId();
      final payload = encodeData({'user_id': userId});
      final response = await apiClient.get(
        '${AppUrls.agreementList}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final json = response.data as Map<String, dynamic>;
      if (json['success'] != true) {
        throw ServerException(
          (json['message'] as String?) ??
              'Failed to load employee agreement documents',
        );
      }

      final data = json['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(AgreementDocumentRemoteModel.fromJson)
          .toList();
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to load employee agreement documents: $e');
    }
  }

  @override
  Future<void> deleteDocument({
    required int directoryId,
    required int documentId,
  }) async {
    try {
      final response = await apiClient.delete(
        AppUrls.documents,
        data: {
          'payload': encodeData({
            'directory_id': directoryId,
            'document_id': documentId,
          }),
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final json = response.data as Map<String, dynamic>;
      if (json['success'] != true) {
        throw ServerException(
          (json['message'] as String?) ?? 'Failed to delete document',
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to delete document: $e');
    }
  }

  int _resolveUserId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ServerException('User token missing');
    }
    final decoded = decodeData<Map<String, dynamic>>(token);
    final userId = decoded?['user_id'];
    if (userId is int) {
      return userId;
    }
    if (userId is String) {
      final parsed = int.tryParse(userId);
      if (parsed != null) {
        return parsed;
      }
    }
    throw const ServerException('Unable to resolve user id');
  }
}
