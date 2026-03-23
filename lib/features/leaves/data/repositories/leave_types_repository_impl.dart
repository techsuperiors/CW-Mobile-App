import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/entities/leave_apply_result.dart';
import '../../domain/entities/leave_uploaded_file.dart';
import '../../domain/repositories/leave_types_repository.dart';
import '../datasources/leave_types_remote_datasource.dart';
import '../models/leave_apply_model.dart';

/// Leave Types repository implementation
class LeaveTypesRepositoryImpl implements LeaveTypesRepository {
  final LeaveTypesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeaveTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LeaveTypes>> getLeaveTypes(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.getLeaveTypes(userId);

        // Convert models to entities
        // Include all leave types, but filter out null leave types
        // LOP might not have a status field, so we include it if status is null or active
        final leaveTypes = responseModel.leaveConfig
            .where(
              (config) =>
                  config.leaveType != null &&
                  (config.status == null ||
                      config.status?.toLowerCase() == 'active'),
            )
            .map(
              (config) => LeaveType(
                leaveType: config.leaveType!,
                count: config.displayCount,
                leaveCode: config.leaveCode ?? '',
                consumedLeaves: config.consumedLeaves,
                totalLeaves: config.totalLeaves,
                annualQuota: config.annualQuota,
                allocatedQuota: config.assignedQuota,
                allocatedLeave: config.allocatedLeave, // Accrued So Far
                remainingLeaves: config.remainingLeaves,
                currentMonthLop: config.currentMonthLop,
              ),
            )
            .toList();

        return Right(
          LeaveTypes(
            leaveTypes: leaveTypes,
            lossOffPay: responseModel.lossOffPay,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, LeaveApplyResult>> applyLeave({
    required String leaveType,
    required String clubing,
    required bool isClubbing,
    required String startDate,
    required String endDate,
    required String subject,
    required String reason,
    required String startHalf,
    required String endHalf,
    required String dayType,
    required String description,
    required String shortCode,
    required int requestTo,
    required List<String> rHDates,
    List<File> attachmentFiles = const [],
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = LeaveApplyRequest(
          leaveType: leaveType,
          clubing: clubing,
          isClubbing: isClubbing,
          startDate: startDate,
          endDate: endDate,
          subject: subject,
          reason: reason,
          startHalf: startHalf,
          endHalf: endHalf,
          dayType: dayType,
          description: description,
          shortCode: shortCode,
          requestTo: requestTo,
          rHDates: rHDates,
          attachmentFiles: attachmentFiles,
        );

        final response = await remoteDataSource.applyLeave(request);

        return Right(
          LeaveApplyResult(
            success: response.success,
            message: response.message ?? 'Leave applied successfully',
            data: response.data,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, LeaveApplyResult>> updateLeave({
    required int leaveId,
    required String leaveType,
    required List<String?> clubing,
    required bool isClubbing,
    required String startDate,
    required String? endDate,
    required String subject,
    required String reason,
    required String startHalf,
    required String endHalf,
    required String dayType,
    required String description,
    required int requestTo,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = UpdateLeaveRequest(
          leaveId: leaveId,
          leaveType: leaveType,
          clubing: clubing,
          isClubbing: isClubbing,
          startDate: startDate,
          endDate: endDate,
          subject: subject,
          reason: reason,
          startHalf: startHalf,
          endHalf: endHalf,
          dayType: dayType,
          description: description,
          requestTo: requestTo,
        );

        final response = await remoteDataSource.updateLeave(request);

        return Right(
          LeaveApplyResult(
            success: response.success,
            message: response.message ?? 'Leave updated successfully',
            data: response.data,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, List<LeaveUploadedFile>>> uploadLeaveFiles({
    required int leaveId,
    required List<File> files,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.uploadLeaveFiles(leaveId: leaveId, files: files);
        final uploadedFiles = files.map(_mapFileToUploadedFile).toList();
        return Right(uploadedFiles);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, String>> deleteLeaveFile({
    required int leaveFileId,
    required String fileId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.deleteLeaveFile(
          leaveFileId: leaveFileId,
          fileId: fileId,
        );
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  LeaveUploadedFile _mapFileToUploadedFile(File file) {
    final stat = file.statSync();
    final lastModified = stat.modified.toUtc();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : file.path;

    return LeaveUploadedFile(
      uid: 'rc-upload-$timestamp-${name.hashCode.abs()}',
      lastModified: lastModified.millisecondsSinceEpoch,
      lastModifiedDate: lastModified.toIso8601String(),
      name: name,
      size: stat.size,
      type: _mimeTypeFromName(name),
    );
  }

  String _mimeTypeFromName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
