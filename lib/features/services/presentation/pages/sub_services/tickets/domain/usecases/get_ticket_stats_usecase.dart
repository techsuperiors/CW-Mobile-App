import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../repositories/ticket_repository.dart';

/// Use case for getting ticket stats
class GetTicketStatsUseCase {
  final TicketRepository repository;

  GetTicketStatsUseCase(this.repository);

  Future<Either<Failure, TicketStats>> call() {
    return repository.getTicketStats();
  }
}
