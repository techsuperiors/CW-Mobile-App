import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/employee_directory_model.dart';

abstract class EmployeeDirectoryRepository {
  Future<Either<Failure, EmployeeDirectoryPageModel>> getEmployees({
    required int clientId,
    required int page,
    required int limit,
  });

  Future<Either<Failure, EmployeeDirectoryDetailModel>> getEmployeeDetails({
    required int userId,
  });
}
