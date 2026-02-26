import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_agreement_list_usecase.dart';
import '../../domain/usecases/submit_agreement_consent_usecase.dart';
import 'agreement_event.dart';
import 'agreement_state.dart';

/// Agreement BLoC
class AgreementBloc extends Bloc<AgreementEvent, AgreementState> {
  final GetAgreementListUseCase getAgreementListUseCase;
  final SubmitAgreementConsentUseCase submitAgreementConsentUseCase;

  AgreementBloc({
    required this.getAgreementListUseCase,
    required this.submitAgreementConsentUseCase,
  }) : super(const AgreementInitial()) {
    on<LoadAgreementList>(_onLoadAgreementList);
    on<RefreshAgreementList>(_onRefreshAgreementList);
    on<SubmitAgreementConsent>(_onSubmitAgreementConsent);
  }

  Future<void> _onLoadAgreementList(
    LoadAgreementList event,
    Emitter<AgreementState> emit,
  ) async {
    emit(const AgreementLoading());

    final result = await getAgreementListUseCase(event.userId);

    result.fold(
      (failure) {
        emit(AgreementError(failure.message));
      },
      (agreementList) {
        emit(AgreementLoaded(agreementList: agreementList));
      },
    );
  }

  Future<void> _onRefreshAgreementList(
    RefreshAgreementList event,
    Emitter<AgreementState> emit,
  ) async {
    final result = await getAgreementListUseCase(event.userId);

    result.fold(
      (failure) {
        emit(AgreementError(failure.message));
      },
      (agreementList) {
        emit(AgreementLoaded(agreementList: agreementList));
      },
    );
  }

  Future<void> _onSubmitAgreementConsent(
    SubmitAgreementConsent event,
    Emitter<AgreementState> emit,
  ) async {
    emit(const AgreementConsentSubmitting());

    final result = await submitAgreementConsentUseCase(
      event.agreementId,
      event.agreementAcknowledged,
      event.signatureFilePath,
    );

    result.fold(
      (failure) {
        emit(AgreementConsentError(failure.message));
      },
      (consentResult) {
        emit(AgreementConsentSubmitted(message: consentResult.message));
      },
    );
  }
}
