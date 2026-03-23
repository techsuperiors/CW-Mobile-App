import 'package:equatable/equatable.dart';

abstract class ApplyCompOffEvent extends Equatable {
  const ApplyCompOffEvent();
  @override
  List<Object?> get props => [];
}

class CreateCompOffEvent extends ApplyCompOffEvent {
  final String type;
  final String date;
  final String duration;
  final String reason;
  final String subject;
  final int requestTo;
  final int userId;

  const CreateCompOffEvent({
    required this.type,
    required this.date,
    required this.duration,
    required this.reason,
    required this.subject,
    required this.requestTo,
    required this.userId,
  });

  @override
  List<Object?> get props =>
      [type, date, duration, reason, subject, requestTo, userId];
}

class UpdateCompOffEvent extends ApplyCompOffEvent {
  final int compOffId;
  final String subject;
  final String date;
  final String duration;
  final String reason;

  const UpdateCompOffEvent({
    required this.compOffId,
    required this.subject,
    required this.date,
    required this.duration,
    required this.reason,
  });

  @override
  List<Object?> get props => [compOffId, subject, date, duration, reason];
}
