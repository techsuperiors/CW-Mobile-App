import 'package:dartz/dartz.dart';

import '../../../../../../../../../../core/error/failures.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';

class GetAccountCustomersUseCase {
  final AccountRepository repository;

  GetAccountCustomersUseCase(this.repository);

  Future<Either<Failure, List<AccountCustomerModel>>> call() {
    return repository.getCustomers();
  }
}

class GetAccountAddressesUseCase {
  final AccountRepository repository;

  GetAccountAddressesUseCase(this.repository);

  Future<Either<Failure, List<AccountAddressModel>>> call() {
    return repository.getAddresses();
  }
}

class CreateAccountCustomerUseCase {
  final AccountRepository repository;

  CreateAccountCustomerUseCase(this.repository);

  Future<Either<Failure, String>> call(CreateAccountCustomerParams params) {
    return repository.createCustomer(params);
  }
}

class GetAccountCustomerDetailsUseCase {
  final AccountRepository repository;

  GetAccountCustomerDetailsUseCase(this.repository);

  Future<Either<Failure, AccountCustomerDetailModel>> call(int customerId) {
    return repository.getCustomerDetails(customerId);
  }
}

class GetAccountAddressDetailsUseCase {
  final AccountRepository repository;

  GetAccountAddressDetailsUseCase(this.repository);

  Future<Either<Failure, AccountAddressDetailModel>> call(int addressId) {
    return repository.getAddressDetails(addressId);
  }
}

class CreateAccountAddressUseCase {
  final AccountRepository repository;

  CreateAccountAddressUseCase(this.repository);

  Future<Either<Failure, String>> call(CreateVisitAddressParams params) {
    return repository.createAddress(params);
  }
}
