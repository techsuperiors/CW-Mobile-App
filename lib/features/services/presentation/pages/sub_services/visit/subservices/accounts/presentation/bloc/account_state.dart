import 'package:equatable/equatable.dart';

import '../../domain/models/account_model.dart';

const _sentinel = Object();

class AccountState extends Equatable {
  final bool isCustomersLoading;
  final bool isAddressesLoading;
  final bool isCreatingAddress;
  final bool isCreatingCustomer;
  final bool isCustomerDetailLoading;
  final bool isAddressDetailLoading;
  final List<AccountCustomerModel> customers;
  final List<AccountAddressModel> addresses;
  final AccountCustomerDetailModel? customerDetail;
  final AccountAddressDetailModel? addressDetail;
  final String? customersError;
  final String? addressesError;
  final String? customerDetailError;
  final String? addressDetailError;
  final String? actionError;
  final String? successMessage;

  const AccountState({
    this.isCustomersLoading = false,
    this.isAddressesLoading = false,
    this.isCreatingAddress = false,
    this.isCreatingCustomer = false,
    this.isCustomerDetailLoading = false,
    this.isAddressDetailLoading = false,
    this.customers = const [],
    this.addresses = const [],
    this.customerDetail,
    this.addressDetail,
    this.customersError,
    this.addressesError,
    this.customerDetailError,
    this.addressDetailError,
    this.actionError,
    this.successMessage,
  });

  AccountState copyWith({
    bool? isCustomersLoading,
    bool? isAddressesLoading,
    bool? isCreatingAddress,
    bool? isCreatingCustomer,
    bool? isCustomerDetailLoading,
    bool? isAddressDetailLoading,
    List<AccountCustomerModel>? customers,
    List<AccountAddressModel>? addresses,
    Object? customerDetail = _sentinel,
    Object? addressDetail = _sentinel,
    Object? customersError = _sentinel,
    Object? addressesError = _sentinel,
    Object? customerDetailError = _sentinel,
    Object? addressDetailError = _sentinel,
    Object? actionError = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return AccountState(
      isCustomersLoading: isCustomersLoading ?? this.isCustomersLoading,
      isAddressesLoading: isAddressesLoading ?? this.isAddressesLoading,
      isCreatingAddress: isCreatingAddress ?? this.isCreatingAddress,
      isCreatingCustomer: isCreatingCustomer ?? this.isCreatingCustomer,
      isCustomerDetailLoading:
          isCustomerDetailLoading ?? this.isCustomerDetailLoading,
      isAddressDetailLoading:
          isAddressDetailLoading ?? this.isAddressDetailLoading,
      customers: customers ?? this.customers,
      addresses: addresses ?? this.addresses,
      customerDetail:
          identical(customerDetail, _sentinel)
              ? this.customerDetail
              : customerDetail as AccountCustomerDetailModel?,
      addressDetail:
          identical(addressDetail, _sentinel)
              ? this.addressDetail
              : addressDetail as AccountAddressDetailModel?,
      customersError:
          identical(customersError, _sentinel)
              ? this.customersError
              : customersError as String?,
      addressesError:
          identical(addressesError, _sentinel)
              ? this.addressesError
              : addressesError as String?,
      customerDetailError:
          identical(customerDetailError, _sentinel)
              ? this.customerDetailError
              : customerDetailError as String?,
      addressDetailError:
          identical(addressDetailError, _sentinel)
              ? this.addressDetailError
              : addressDetailError as String?,
      actionError:
          identical(actionError, _sentinel)
              ? this.actionError
              : actionError as String?,
      successMessage:
          identical(successMessage, _sentinel)
              ? this.successMessage
              : successMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    isCustomersLoading,
    isAddressesLoading,
    isCreatingAddress,
    isCreatingCustomer,
    isCustomerDetailLoading,
    isAddressDetailLoading,
    customers,
    addresses,
    customerDetail,
    addressDetail,
    customersError,
    addressesError,
    customerDetailError,
    addressDetailError,
    actionError,
    successMessage,
  ];
}
