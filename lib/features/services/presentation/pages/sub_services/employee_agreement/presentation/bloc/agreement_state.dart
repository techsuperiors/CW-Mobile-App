import 'package:equatable/equatable.dart';
import '../../domain/entities/agreement.dart';

/// Agreement states
abstract class AgreementState extends Equatable {
  const AgreementState();

  @override
  List<Object> get props => [];
}

/// Initial state
class AgreementInitial extends AgreementState {
  const AgreementInitial();
}

/// Loading state
class AgreementLoading extends AgreementState {
  const AgreementLoading();
}

/// Loaded state
class AgreementLoaded extends AgreementState {
  final AgreementList agreementList;

  const AgreementLoaded({required this.agreementList});

  @override
  List<Object> get props => [agreementList];
}

/// Error state
class AgreementError extends AgreementState {
  final String message;

  const AgreementError(this.message);

  @override
  List<Object> get props => [message];
}

/// Consent submitting state
class AgreementConsentSubmitting extends AgreementState {
  const AgreementConsentSubmitting();
}

/// Consent submitted state
class AgreementConsentSubmitted extends AgreementState {
  final String? message;

  const AgreementConsentSubmitted({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

/// Consent error state
class AgreementConsentError extends AgreementState {
  final String message;

  const AgreementConsentError(this.message);

  @override
  List<Object> get props => [message];
}