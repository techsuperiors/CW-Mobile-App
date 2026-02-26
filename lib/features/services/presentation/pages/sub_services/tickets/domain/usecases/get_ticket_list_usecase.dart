import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for getting ticket list
class GetTicketListUseCase {
  final TicketRepository repository;

  GetTicketListUseCase(this.repository);

  Future<Either<Failure, TicketList>> call(String requestType) {
    return repository.getTicketList(requestType);
  }
}
