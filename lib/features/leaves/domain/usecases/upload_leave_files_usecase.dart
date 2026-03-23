import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_uploaded_file.dart';
import '../repositories/leave_types_repository.dart';

class UploadLeaveFilesUseCase {
  final LeaveTypesRepository repository;

  UploadLeaveFilesUseCase(this.repository);

  Future<Either<Failure, List<LeaveUploadedFile>>> call({
    required int leaveId,
    required List<File> files,
  }) async {
    return repository.uploadLeaveFiles(leaveId: leaveId, files: files);
  }
}
