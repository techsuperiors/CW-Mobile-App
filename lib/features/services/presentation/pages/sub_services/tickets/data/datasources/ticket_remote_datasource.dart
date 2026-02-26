import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../models/ticket_api_model.dart';
import 'package:dio/dio.dart';

/// Ticket remote data source interface
abstract class TicketRemoteDataSource {
  Future<List<TicketApiModel>> getTicketList(String requestType);
  Future<TicketStatsModel> getTicketStats();
  Future<TicketDetailsModel> getTicketDetails(int ticketId);
  Future<TicketStatsModel> uploadTicketFile(int clientId, int ticketId, String filePath);
}

/// Ticket remote data source implementation
class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final ApiClient apiClient;

  TicketRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TicketApiModel>> getTicketList(String requestType) async {
    try {
      // Encode the payload with request_type
      final payload = {'request_type': requestType};
      final encodedPayload = encodeData(payload);

      // Build the URL with encoded payload as query parameter
      final url = '${AppUrls.ticketList}?payload=$encodedPayload';

      final response = await apiClient.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final apiResponse = TicketListApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to get ticket list',
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
      throw ServerException('Failed to get ticket list: ${e.toString()}');
    }
  }

  @override
  Future<TicketStatsModel> getTicketStats() async {
    try {
      final response = await apiClient.get(
        AppUrls.ticketStats,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final apiResponse = TicketStatsApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to get ticket stats',
        );
      }

      if (apiResponse.data == null) {
        throw ServerException('Ticket stats data not found');
      }

      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to get ticket stats: ${e.toString()}');
    }
  }

  @override
  Future<TicketDetailsModel> getTicketDetails(int ticketId) async {
    try {
      // Encode the payload with ticket_id
      final payload = {'ticket_id': ticketId};
      final encodedPayload = encodeData(payload);

      // Build the URL with encoded payload as query parameter
      final url = '${AppUrls.ticketDetails}?query=$encodedPayload';

      final response = await apiClient.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final apiResponse = TicketDetailsApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to get ticket details',
        );
      }

      if (apiResponse.data == null) {
        throw ServerException('Ticket details data not found');
      }

      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to get ticket details: ${e.toString()}');
    }
  }

  @override
  Future<TicketStatsModel> uploadTicketFile(
    int clientId,
    int ticketId,
    String filePath,
  ) async {
    try {
      // Encode the payload
      final payload = TicketFileUploadRequest(
        clientId: clientId,
        ticketId: ticketId,
      );
      final encodedPayload = encodeData(payload.toJson());

      // Create FormData for multipart/form-data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'payload': encodedPayload,
      });

      final response = await apiClient.post(
        AppUrls.ticketFileUpload,
        data: formData,
      );

      final apiResponse = TicketFileUploadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Failed to upload ticket file',
        );
      }

      if (apiResponse.data == null) {
        throw ServerException('Ticket file upload response data not found');
      }

      return apiResponse.data!;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to upload ticket file: ${e.toString()}');
    }
  }
}
