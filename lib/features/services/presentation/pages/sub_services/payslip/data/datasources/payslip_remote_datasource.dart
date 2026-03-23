import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../domain/models/payslip_model.dart';

abstract class PayslipRemoteDataSource {
  Future<List<PayslipModel>> getPayslips(String year);
}

class PayslipRemoteDataSourceImpl implements PayslipRemoteDataSource {
  final ApiClient apiClient;

  PayslipRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PayslipModel>> getPayslips(String year) async {
    final base64Payload = encodeData({'year': year});

    final response = await apiClient.get(
      AppUrls.payslipRun,
      queryParameters: {
        'payload': base64Payload,
      },
    );

    if (response.data != null && response.data['success'] == true) {
      final rawData = response.data['data'];
      final data =
          rawData is List
              ? rawData
              : rawData is Map<String, dynamic>
              ? (rawData['data'] ??
                  rawData['items'] ??
                  rawData['records'] ??
                  rawData['rows'])
              : null;

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PayslipModel.fromJson)
            .toList();
      }
    }
    return [];
  }
}
