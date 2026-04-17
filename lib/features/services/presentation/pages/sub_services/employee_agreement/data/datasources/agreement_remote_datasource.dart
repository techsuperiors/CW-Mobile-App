import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../models/agreement_model.dart';
import 'package:dio/dio.dart';

/// Agreement remote data source interface
abstract class AgreementRemoteDataSource {
  Future<List<AgreementModel>> getAgreementList(int userId);

  Future<AgreementConsentResponse> submitAgreementConsent(
    AgreementConsentRequest request,
    String signedPdfFilePath,
  );
}

/// Agreement remote data source implementation
class AgreementRemoteDataSourceImpl implements AgreementRemoteDataSource {
  final ApiClient apiClient;

  AgreementRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<AgreementModel>> getAgreementList(int userId) async {
    try {
      // Encode the payload with user_id
      final payload = {'user_id': userId};
      final encodedPayload = encodeData(payload);

      // Build the URL with encoded payload as query parameter
      final url = '${AppUrls.agreementList}?payload=$encodedPayload';

      final response = await apiClient.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final apiResponse = AgreementListApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to get agreement list',
        );
      }

      if (apiResponse.data == null) {
        return [];
      }

      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to get agreement list: ${e.toString()}');
    }
  }

  @override
  Future<AgreementConsentResponse> submitAgreementConsent(
    AgreementConsentRequest request,
    String signedPdfFilePath,
  ) async {
    try {
      // Encode the payload
      final encodedPayload = encodeData(request.toJson());

      // Create FormData for multipart/form-data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(signedPdfFilePath),
        'payload': encodedPayload,
      });

      final response = await apiClient.post(
        AppUrls.agreementConsent,
        data: formData,
      );

      final apiResponse = AgreementConsentResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to submit agreement consent',
        );
      }

      return apiResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        'Failed to submit agreement consent: ${e.toString()}',
      );
    }
  }
}
