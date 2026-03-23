import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/comp_off_repository.dart';

class UploadCompOffFileUseCase {
  final CompOffRepository repository;

  UploadCompOffFileUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int compOffId,
    required String filePath,
  }) {
    return repository.uploadCompOffFile(compOffId: compOffId, filePath: filePath);
  }
}
