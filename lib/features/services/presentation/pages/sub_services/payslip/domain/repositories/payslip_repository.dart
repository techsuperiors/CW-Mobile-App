import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../models/payslip_model.dart';

abstract class PayslipRepository {
  Future<Either<Failure, List<PayslipModel>>> getPayslips(String year);
}
