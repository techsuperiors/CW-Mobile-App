import 'package:equatable/equatable.dart';

abstract class ApplyOvertimeEvent extends Equatable {
  const ApplyOvertimeEvent();

  @override
  List<Object?> get props => [];
}

class CreateOvertime extends ApplyOvertimeEvent {
  final String requestDate;
  final String checkIn;
  final String checkOut;
  final String subject;
  final String description;
  final int userId;

  const CreateOvertime({
    required this.requestDate,
    required this.checkIn,
    required this.checkOut,
    required this.subject,
    required this.description,
    required this.userId,
  });

  @override
  List<Object?> get props => [
        requestDate,
        checkIn,
        checkOut,
        subject,
        description,
        userId,
      ];
}

class UpdateOvertime extends ApplyOvertimeEvent {
  final int requestId;
  final String requestDate;
  final String checkIn;
  final String checkOut;
  final int userId;
  final String description;

  const UpdateOvertime({
    required this.requestId,
    required this.requestDate,
    required this.checkIn,
    required this.checkOut,
    required this.userId,
    required this.description,
  });

  @override
  List<Object?> get props => [
        requestId,
        requestDate,
        checkIn,
        checkOut,
        userId,
        description,
      ];
}
