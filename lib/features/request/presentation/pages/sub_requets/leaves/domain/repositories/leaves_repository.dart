import 'package:dartz/dartz.dart';
import 'package:collectivWork/core/error/failures.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../entities/leave_entity.dart';
import '../entities/apply_leave_entity.dart';
import '../entities/leave_history_entity.dart';
import '../entities/team_leave_requests_page_entity.dart';

/// Interface for the Leaves Repository
abstract class LeavesRepository {
  /// Fetches a list of leave requests
  Future<Either<Failure, List<LeaveEntity>>> getLeaves();

  /// Fetches team leave requests for approval screens
  Future<Either<Failure, TeamLeaveRequestsPageEntity>> getTeamLeaveRequests({
    required int clientId,
    RequestAudienceScope scope = RequestAudienceScope.allUsers,
    int page = 1,
    int limit = 50,
  });

  /// Submits an application for a new leave
  Future<Either<Failure, ApplyLeaveResponseEntity>> applyLeave(
    ApplyLeaveRequestEntity request,
  );

  /// Fetches leave history entries for a given leave type
  Future<Either<Failure, List<LeaveHistoryEntity>>> getLeaveHistory(
    String leaveType,
  );
}
