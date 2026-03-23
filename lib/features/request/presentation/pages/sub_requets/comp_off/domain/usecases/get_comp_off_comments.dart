import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../repositories/comp_off_repository.dart';

class GetCompOffCommentsUseCase {
  final CompOffRepository repository;

  GetCompOffCommentsUseCase(this.repository);

  Future<Either<Failure, List<AttendanceRequestComment>>> call({
    required int compOffId,
  }) {
    return repository.getComments(compOffId: compOffId);
  }
}
