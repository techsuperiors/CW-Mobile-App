import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/ticket_repository.dart';

class DeleteTicketFileUseCase {
  final TicketRepository repository;

  DeleteTicketFileUseCase(this.repository);

  Future<Either<Failure, String>> call(int supportDocumentId, String fileId) {
    return repository.deleteTicketFile(supportDocumentId, fileId);
  }
}
