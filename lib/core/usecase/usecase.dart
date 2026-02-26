import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Base use case interface that returns Either<Failure, Type>
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// No parameters use case that returns Either<Failure, Type>
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Base parameters class
abstract class Params extends Equatable {
  const Params();
}

/// No parameters class
class NoParams extends Params {
  const NoParams();

  @override
  List<Object> get props => [];
}

