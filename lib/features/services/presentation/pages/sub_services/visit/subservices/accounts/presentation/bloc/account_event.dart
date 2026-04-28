import 'package:equatable/equatable.dart';

import '../../domain/models/account_model.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccountCustomers extends AccountEvent {
  final bool forceRefresh;

  const LoadAccountCustomers({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadAccountAddresses extends AccountEvent {
  final bool forceRefresh;

  const LoadAccountAddresses({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadAccountCustomerDetails extends AccountEvent {
  final int customerId;
  final bool forceRefresh;

  const LoadAccountCustomerDetails(this.customerId, {this.forceRefresh = false});

  @override
  List<Object?> get props => [customerId, forceRefresh];
}

class LoadAccountAddressDetails extends AccountEvent {
  final int addressId;
  final bool forceRefresh;

  const LoadAccountAddressDetails(this.addressId, {this.forceRefresh = false});

  @override
  List<Object?> get props => [addressId, forceRefresh];
}

class CreateAccountAddressRequested extends AccountEvent {
  final CreateVisitAddressParams params;

  const CreateAccountAddressRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class CreateAccountCustomerRequested extends AccountEvent {
  final CreateAccountCustomerParams params;

  const CreateAccountCustomerRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class ClearAccountFeedback extends AccountEvent {
  const ClearAccountFeedback();
}
