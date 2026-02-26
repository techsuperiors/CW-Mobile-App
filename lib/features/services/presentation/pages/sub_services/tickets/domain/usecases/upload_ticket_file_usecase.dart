import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

/// Use case for uploading ticket file
class UploadTicketFileUseCase {
  final TicketRepository repository;

  UploadTicketFileUseCase(this.repository);

  Future<Either<Failure, TicketStats>> call(
    int clientId,
    int ticketId,
    String filePath,
  ) {
    return repository.uploadTicketFile(clientId, ticketId, filePath);
  }
}
