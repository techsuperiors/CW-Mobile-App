import 'package:equatable/equatable.dart';

/// Agreement events
abstract class AgreementEvent extends Equatable {
  const AgreementEvent();

  @override
  List<Object> get props => [];
}

/// Load agreement list event
class LoadAgreementList extends AgreementEvent {
  final int userId;

  const LoadAgreementList(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Refresh agreement list event
class RefreshAgreementList extends AgreementEvent {
  final int userId;

  const RefreshAgreementList(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Submit agreement consent event
class SubmitAgreementConsent extends AgreementEvent {
  final int agreementId;
  final bool agreementAcknowledged;
  final String signatureFilePath;

  const SubmitAgreementConsent({
    required this.agreementId,
    required this.agreementAcknowledged,
    required this.signatureFilePath,
  });

  @override
  List<Object> get props => [agreementId, agreementAcknowledged, signatureFilePath];
}