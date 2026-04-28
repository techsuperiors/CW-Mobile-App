import 'package:dartz/dartz.dart';

import '../../../../../../../../../../core/error/failures.dart';
import '../models/account_model.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<AccountCustomerModel>>> getCustomers();

  Future<Either<Failure, List<AccountAddressModel>>> getAddresses();

  Future<Either<Failure, AccountCustomerDetailModel>> getCustomerDetails(
    int customerId,
  );

  Future<Either<Failure, AccountAddressDetailModel>> getAddressDetails(
    int addressId,
  );

  Future<Either<Failure, String>> createAddress(
    CreateVisitAddressParams params,
  );

  Future<Either<Failure, String>> createCustomer(
    CreateAccountCustomerParams params,
  );
}
