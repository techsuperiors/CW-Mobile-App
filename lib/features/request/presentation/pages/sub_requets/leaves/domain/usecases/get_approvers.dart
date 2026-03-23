import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/usecase/usecase.dart';
import '../repositories/approvers_repository.dart';

class GetApprovers extends UseCase<Map<String, dynamic>, GetApproversParams> {
  final ApproversRepository repository;

  GetApprovers(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetApproversParams params,
  ) async {
    return await repository.getApprovers(params.endpoint, params.payload);
  }
}

class GetApproversParams {
  final String endpoint;
  final Map<String, dynamic> payload;

  GetApproversParams({required this.endpoint, required this.payload});
}
