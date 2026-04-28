import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/employee_directory_model.dart';
import '../repositories/employee_directory_repository.dart';

class GetEmployeeDirectoryUseCase {
  final EmployeeDirectoryRepository repository;

  GetEmployeeDirectoryUseCase(this.repository);

  Future<Either<Failure, EmployeeDirectoryPageModel>> call({
    required int clientId,
    required int page,
    required int limit,
  }) {
    return repository.getEmployees(
      clientId: clientId,
      page: page,
      limit: limit,
    );
  }
}

class GetEmployeeDirectoryDetailUseCase {
  final EmployeeDirectoryRepository repository;

  GetEmployeeDirectoryDetailUseCase(this.repository);

  Future<Either<Failure, EmployeeDirectoryDetailModel>> call({
    required int userId,
  }) {
    return repository.getEmployeeDetails(userId: userId);
  }
}
