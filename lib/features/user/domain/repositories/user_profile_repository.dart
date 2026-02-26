import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// User Profile repository interface
abstract class UserProfileRepository {
  Future<Either<Failure, UserProfile>> getUserProfile();
}

