import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for getting ticket details
class GetTicketDetailsUseCase {
  final TicketRepository repository;

  GetTicketDetailsUseCase(this.repository);

  Future<Either<Failure, TicketDetails>> call(int ticketId) {
    return repository.getTicketDetails(ticketId);
  }
}
