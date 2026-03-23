import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payslip_repository.dart';
import 'payslip_event.dart';
import 'payslip_state.dart';

class PayslipBloc extends Bloc<PayslipEvent, PayslipState> {
  final PayslipRepository repository;

  PayslipBloc({required this.repository}) : super(PayslipInitial()) {
    on<FetchPayslipsEvent>((event, emit) async {
      emit(PayslipLoading());

      final result = await repository.getPayslips(event.year);

      result.fold(
        (failure) => emit(PayslipError(message: failure.message)),
        (payslips) => emit(PayslipLoaded(payslips: payslips)),
      );
    });
  }
}
