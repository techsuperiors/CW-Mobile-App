import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';

abstract class ApproversRepository {
  Future<Either<Failure, Map<String, dynamic>>> getApprovers(
    String endpoint,
    Map<String, dynamic> payload,
  );
}
