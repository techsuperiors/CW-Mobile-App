import 'package:dartz/dartz.dart';
import '../../../../../../../../../../core/error/failures.dart';
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

class GetVisitActivityDetailsUseCase {
  final VisitRepository repository;

  GetVisitActivityDetailsUseCase(this.repository);

  Future<Either<Failure, VisitActivityDetailModel>> call(int activityId) {
    return repository.getVisitActivityDetails(activityId);
  }
}

class CreateVisitActivityUseCase {
  final VisitRepository repository;

  CreateVisitActivityUseCase(this.repository);

  Future<Either<Failure, String>> call(CreateVisitActivityParams params) {
    return repository.createVisitActivity(params);
  }
}

class UpdateVisitActivityUseCase {
  final VisitRepository repository;

  UpdateVisitActivityUseCase(this.repository);

  Future<Either<Failure, String>> call(UpdateVisitActivityParams params) {
    return repository.updateVisitActivity(params);
  }
}

class StartVisitActivityUseCase {
  final VisitRepository repository;

  StartVisitActivityUseCase(this.repository);

  Future<Either<Failure, String>> call(StartVisitActivityParams params) {
    return repository.startVisitActivity(params);
  }
}

class CompleteVisitActivityUseCase {
  final VisitRepository repository;

  CompleteVisitActivityUseCase(this.repository);

  Future<Either<Failure, String>> call(CompleteVisitActivityParams params) {
    return repository.completeVisitActivity(params);
  }
}

class DeleteVisitActivityUseCase {
  final VisitRepository repository;

  DeleteVisitActivityUseCase(this.repository);

  Future<Either<Failure, String>> call(int activityId) {
    return repository.deleteVisitActivity(activityId);
  }
}
