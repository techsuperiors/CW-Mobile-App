import 'package:equatable/equatable.dart';

/// Apply regularize events
abstract class ApplyRegularizeEvent extends Equatable {
  const ApplyRegularizeEvent();

  @override
  List<Object> get props => [];
}

/// Apply regularize request event
class ApplyRegularize extends ApplyRegularizeEvent {
  final String requestDate;
  final String requestFor; // 'checkIn', 'checkOut', 'both'
  final String modeType; // 'Remote', 'Office', etc.
  final String? checkIn; // Format: 'yyyy-MM-dd HH:mm:ss+05:30'
  final String? checkOut; // Format: 'yyyy-MM-dd HH:mm:ss+05:30'
  final String reason;
  final String? otherReason;
  final String description;
  final int userId;
  final bool isOther;
  final int? statusUpdatedBy;

  const ApplyRegularize({
    required this.requestDate,
    required this.requestFor,
    required this.modeType,
    this.checkIn,
    this.checkOut,
    required this.reason,
    this.otherReason,
    required this.description,
    required this.userId,
    required this.isOther,
    this.statusUpdatedBy,
  });

  @override
  List<Object> get props => [
        requestDate,
        requestFor,
        modeType,
        checkIn ?? '',
        checkOut ?? '',
        reason,
        otherReason ?? '',
        description,
        userId,
        isOther,
        statusUpdatedBy ?? 0,
      ];
}

class UpdateRegularize extends ApplyRegularizeEvent {
  final int id;
  final String requestDate;
  final String requestFor;
  final String? checkIn;
  final String? checkOut;
  final int statusUpdatedBy;
  final String description;

  const UpdateRegularize({
    required this.id,
    required this.requestDate,
    required this.requestFor,
    required this.checkIn,
    required this.checkOut,
    required this.statusUpdatedBy,
    required this.description,
  });

  @override
  List<Object> get props => [
        id,
        requestDate,
        requestFor,
        checkIn ?? '',
        checkOut ?? '',
        statusUpdatedBy,
        description,
      ];
}
