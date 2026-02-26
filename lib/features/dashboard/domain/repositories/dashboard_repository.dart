import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats.dart';

/// Dashboard repository interface
abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();
}

