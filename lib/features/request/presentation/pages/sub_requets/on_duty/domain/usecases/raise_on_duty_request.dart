import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/usecase/usecase.dart';
import '../repositories/on_duty_repository.dart';

class RaiseOnDutyRequestUseCase
    implements UseCase<String, RaiseOnDutyRequestParams> {
  final OnDutyRepository repository;

  RaiseOnDutyRequestUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RaiseOnDutyRequestParams params) {
    return repository.raiseOnDutyRequest(
      subject: params.subject,
      requestType: params.requestType,
      description: params.description,
      startDate: params.startDate,
      endDate: params.endDate,
      startHalf: params.startHalf,
      endHalf: params.endHalf,
      userId: params.userId,
    );
  }
}

class RaiseOnDutyRequestParams extends Params {
  final String subject;
  final String requestType;
  final String description;
  final String startDate;
  final String endDate;
  final String startHalf;
  final String endHalf;
  final int userId;

  const RaiseOnDutyRequestParams({
    required this.subject,
    required this.requestType,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startHalf,
    required this.endHalf,
    required this.userId,
  });

  @override
  List<Object> get props => [
        subject,
        requestType,
        description,
        startDate,
        endDate,
        startHalf,
        endHalf,
        userId,
      ];
}
