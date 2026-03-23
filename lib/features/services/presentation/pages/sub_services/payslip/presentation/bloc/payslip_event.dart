import 'package:equatable/equatable.dart';

abstract class PayslipEvent extends Equatable {
  const PayslipEvent();

  @override
  List<Object> get props => [];
}

class FetchPayslipsEvent extends PayslipEvent {
  final String year;

  const FetchPayslipsEvent({required this.year});

  @override
  List<Object> get props => [year];
}
