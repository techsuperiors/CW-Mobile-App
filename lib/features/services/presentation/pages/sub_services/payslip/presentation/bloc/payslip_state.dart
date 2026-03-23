import 'package:equatable/equatable.dart';
import '../../domain/models/payslip_model.dart';

abstract class PayslipState extends Equatable {
  const PayslipState();

  @override
  List<Object> get props => [];
}

class PayslipInitial extends PayslipState {}

class PayslipLoading extends PayslipState {}

class PayslipLoaded extends PayslipState {
  final List<PayslipModel> payslips;

  const PayslipLoaded({required this.payslips});

  @override
  List<Object> get props => [payslips];
}

class PayslipError extends PayslipState {
  final String message;

  const PayslipError({required this.message});

  @override
  List<Object> get props => [message];
}
