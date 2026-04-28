import 'package:dio/dio.dart';

import '../../../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../../../core/utils/data_encoder.dart';
import '../../domain/models/account_model.dart';
import '../models/account_remote_models.dart';

abstract class AccountRemoteDataSource {
  Future<List<AccountCustomerRemoteModel>> getCustomers();

  Future<List<AccountAddressRemoteModel>> getAddresses();

  Future<AccountCustomerDetailRemoteModel> getCustomerDetails(int customerId);

  Future<AccountAddressDetailRemoteModel> getAddressDetails(int addressId);

  Future<String> createAddress(CreateVisitAddressParams params);

  Future<String> createCustomer(CreateAccountCustomerParams params);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final ApiClient apiClient;

  AccountRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AccountCustomerRemoteModel>> getCustomers() async {
    final payload = encodeData(<String, dynamic>{});

    try {
      final response = await apiClient.get(
        AppUrls.visitCustomerList,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load customers',
        );
      }

      return (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AccountCustomerRemoteModel.fromJson)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load customers: ${e.toString()}');
    }
  }

  @override
  Future<List<AccountAddressRemoteModel>> getAddresses() async {
    final payload = encodeData(<String, dynamic>{'page': 1, 'limit': 5});

    try {
      final response = await apiClient.get(
        AppUrls.visitAddressList,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load addresses',
        );
      }

      return (data['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AccountAddressRemoteModel.fromJson)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load addresses: ${e.toString()}');
    }
  }

  @override
  Future<AccountCustomerDetailRemoteModel> getCustomerDetails(
    int customerId,
  ) async {
    final payload = encodeData(<String, dynamic>{'customer_id': customerId});

    try {
      final response = await apiClient.get(
        AppUrls.visitCustomerDetails,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load customer details',
        );
      }

      final detailJson =
          data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : null;
      if (detailJson == null) {
        throw const ServerException('Customer detail payload is invalid');
      }

      return AccountCustomerDetailRemoteModel.fromJson(detailJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load customer details: ${e.toString()}');
    }
  }

  @override
  Future<AccountAddressDetailRemoteModel> getAddressDetails(
    int addressId,
  ) async {
    final payload = encodeData(<String, dynamic>{'address_id': addressId});

    try {
      final response = await apiClient.get(
        AppUrls.visitAddressDetails,
        queryParameters: {'payload': payload},
        options: Options(headers: const {'accept': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load address details',
        );
      }

      final detailJson =
          data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : null;
      if (detailJson == null) {
        throw const ServerException('Address detail payload is invalid');
      }

      return AccountAddressDetailRemoteModel.fromJson(detailJson);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load address details: ${e.toString()}');
    }
  }

  @override
  Future<String> createAddress(CreateVisitAddressParams params) async {
    final payload = encodeData({
      'address_name': params.addressName.trim(),
      'address_type': params.addressType.trim(),
      'pincode': params.pincode.trim(),
      'city': params.city.trim(),
      'state': params.state.trim(),
      'country': params.country.trim(),
      'latitude': params.latitude.trim(),
      'longitude': params.longitude.trim(),
      'polygon':
          params.polygon.isEmpty
              ? null
              : params.polygon
                  .map(
                    (point) => {
                      'latitude': point.latitude,
                      'longitude': point.longitude,
                    },
                  )
                  .toList(growable: false),
    });

    try {
      final response = await apiClient.post(
        AppUrls.visitAddressCreate,
        data: {'payload': payload},
        options: Options(
          headers: const {'accept': '*/*', 'Content-Type': 'application/json'},
        ),
      );

      final responseData = response.data;
      if (responseData is String) {
        return responseData;
      }

      if (responseData is Map<String, dynamic>) {
        if (responseData['success'] == false) {
          throw ServerException(
            responseData['message'] as String? ??
                'Failed to create visit address',
          );
        }

        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      return 'Visit address created successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create address: ${e.toString()}');
    }
  }

  @override
  Future<String> createCustomer(CreateAccountCustomerParams params) async {
    final payload = encodeData({
      'customer_name': params.customerName.trim(),
      if (params.customerCode.trim().isNotEmpty)
        'customer_code': params.customerCode.trim(),
      'business_domian': params.businessDomain.trim(),
      'customer_type': params.customerType.trim(),
      if (params.description.trim().isNotEmpty)
        'description': params.description.trim(),
      'addresses': params.addresses
          .map(
            (address) => {
              if (address.label.trim().isNotEmpty) 'label': address.label.trim(),
              if (address.type.trim().isNotEmpty) 'type': address.type.trim(),
              if (address.address.trim().isNotEmpty)
                'address': address.address.trim(),
              if (address.city.trim().isNotEmpty) 'city': address.city.trim(),
              if (address.state.trim().isNotEmpty) 'state': address.state.trim(),
              if (address.country.trim().isNotEmpty)
                'country': address.country.trim(),
              if (address.pincode.trim().isNotEmpty)
                'pincode': address.pincode.trim(),
              if (address.latitude.trim().isNotEmpty)
                'latitude': address.latitude.trim(),
              if (address.longitude.trim().isNotEmpty)
                'longitude': address.longitude.trim(),
              'contacts': address.contacts
                  .map(
                    (contact) => {
                      if (contact.name.trim().isNotEmpty)
                        'name': contact.name.trim(),
                      if (contact.designation.trim().isNotEmpty)
                        'designation': contact.designation.trim(),
                      if (contact.phone.trim().isNotEmpty)
                        'phone': contact.phone.trim(),
                      if (contact.email.trim().isNotEmpty)
                        'email': contact.email.trim(),
                      'is_primary': contact.isPrimary,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    });

    try {
      final response = await apiClient.post(
        AppUrls.visitCustomerCreate,
        data: {'payload': payload},
        options: Options(
          headers: const {'accept': '*/*', 'Content-Type': 'application/json'},
        ),
      );

      final responseData = response.data;
      if (responseData is String) {
        return responseData;
      }

      if (responseData is Map<String, dynamic>) {
        if (responseData['success'] == false) {
          throw ServerException(
            responseData['message'] as String? ??
                'Failed to create customer profile',
          );
        }

        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      return 'Customer profile created successfully';
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create customer: ${e.toString()}');
    }
  }
}
