import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/visit_model.dart';
import '../repositories/visit_repository.dart';

class GetVisitEmployeesUseCase {
  final VisitRepository repository;

  GetVisitEmployeesUseCase(this.repository);

  Future<Either<Failure, List<VisitEmployeeModel>>> call() {
    return repository.getEmployees();
  }
}

class GetVisitCustomersUseCase {
  final VisitRepository repository;

  GetVisitCustomersUseCase(this.repository);

  Future<Either<Failure, List<VisitCustomerModel>>> call() {
    return repository.getCustomers();
  }
}

class GetVisitAddressesUseCase {
  final VisitRepository repository;

  GetVisitAddressesUseCase(this.repository);

  Future<Either<Failure, List<VisitAddressModel>>> call() {
    return repository.getAddresses();
  }
}

class CreateVisitUseCase {
  final VisitRepository repository;

  CreateVisitUseCase(this.repository);

  Future<Either<Failure, String>> call(CreateVisitParams params) {
    return repository.createVisit(params);
  }
}

class CreateVisitActivityUseCase {
  final VisitRepository repository;

  CreateVisitActivityUseCase(this.repository);

  Future<Either<Failure, String>> call(CreateVisitActivityParams params) {
    return repository.createVisitActivity(params);
  }
}
