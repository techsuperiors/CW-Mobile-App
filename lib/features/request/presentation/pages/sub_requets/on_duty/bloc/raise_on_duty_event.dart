import 'package:equatable/equatable.dart';

abstract class RaiseOnDutyRequestEvent extends Equatable {
  const RaiseOnDutyRequestEvent();

  @override
  List<Object> get props => [];
}

class SubmitOnDutyRequest extends RaiseOnDutyRequestEvent {
  final String subject;
  final String requestType;
  final String description;
  final String startDate;
  final String endDate;
  final String startHalf;
  final String endHalf;
  final int userId;

  const SubmitOnDutyRequest({
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
