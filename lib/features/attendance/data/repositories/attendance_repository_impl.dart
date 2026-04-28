import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/location_service.dart';
import '../../domain/entities/punch_in_result.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_offline_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/offline_attendance_action_model.dart';

/// Attendance repository implementation
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AttendanceOfflineLocalDataSource offlineLocalDataSource;
  final LocationService locationService;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.offlineLocalDataSource,
    required this.locationService,
  });

  @override
  Future<Either<Failure, PunchInResult>> punchIn({
    String? punchInLocation,
    double? latitude,
    double? longitude,
    required String punchType,
    bool needsAddressResolution = false,
  }) async {
    await _removeExpiredPendingActions();

    final action = OfflineAttendanceActionModel(
      id: _buildActionId(OfflineAttendanceActionType.punchIn),
      type: OfflineAttendanceActionType.punchIn,
      location: punchInLocation ?? '',
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      punchType: punchType,
      createdAt: DateTime.now(),
      needsAddressResolution: needsAddressResolution,
    );

    if (needsAddressResolution) {
      await offlineLocalDataSource.addPendingAction(action);
      final synced = await syncPendingActions();
      return Right(
        PunchInResult(
          success: true,
          message:
              synced
                  ? 'Punch-in successful.'
                  : '',
          data: {'queued': !synced},
        ),
      );
    }

    final hasPendingActions = await offlineLocalDataSource.hasPendingActions();
    if (hasPendingActions) {
      await offlineLocalDataSource.addPendingAction(action);
      final synced = await syncPendingActions();
      return Right(
        PunchInResult(
          success: true,
          message:
              synced
                  ? 'Punch-in successful.'
                  : 'Punch-in saved offline. It will sync automatically.',
          data: {'queued': !synced},
        ),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        final request = PunchInRequest(
          punchInLocation: punchInLocation,
          latitude: latitude,
          longitude: longitude,
          punchType: punchType,
        );
        
        final response = await remoteDataSource.punchIn(request);
        
        return Right(PunchInResult(
          success: response.success,
          message: response.message ?? 'Punch-in successful',
          data: response.data,
        ));
      } on ServerException catch (e) {
        if (_isRetryableFailure(e.message)) {
          await offlineLocalDataSource.addPendingAction(action);
          return Right(
            PunchInResult(
              success: true,
              message:
                  'Punch-in saved offline. It will sync automatically when possible.',
              data: const {'queued': true},
            ),
          );
        }
        return Left(ServerFailure(e.message));
      } catch (e) {
        await offlineLocalDataSource.addPendingAction(action);
        return Right(
          PunchInResult(
            success: true,
            message:
                'Punch-in saved offline. It will sync automatically when possible.',
            data: const {'queued': true},
          ),
        );
      }
    } else {
      await offlineLocalDataSource.addPendingAction(action);
      return Right(
        PunchInResult(
          success: true,
          message: 'Punch-in saved offline. It will sync automatically.',
          data: const {'queued': true},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PunchInResult>> punchOut({
    String? punchOutLocation,
    double? latitude,
    double? longitude,
    bool needsAddressResolution = false,
  }) async {
    await _removeExpiredPendingActions();

    final action = OfflineAttendanceActionModel(
      id: _buildActionId(OfflineAttendanceActionType.punchOut),
      type: OfflineAttendanceActionType.punchOut,
      location: punchOutLocation ?? '',
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      createdAt: DateTime.now(),
      needsAddressResolution: needsAddressResolution,
    );

    if (needsAddressResolution) {
      await offlineLocalDataSource.addPendingAction(action);
      final synced = await syncPendingActions();
      return Right(
        PunchInResult(
          success: true,
          message:
              synced
                  ? 'Punch-out successful.'
                  : 'Punch-out saved. It will sync after location details are resolved.',
          data: {'queued': !synced},
        ),
      );
    }

    final hasPendingActions = await offlineLocalDataSource.hasPendingActions();
    if (hasPendingActions) {
      await offlineLocalDataSource.addPendingAction(action);
      final synced = await syncPendingActions();
      return Right(
        PunchInResult(
          success: true,
          message:
              synced
                  ? 'Punch-out successful.'
                  : 'Punch-out saved offline. It will sync automatically.',
          data: {'queued': !synced},
        ),
      );
    }

    if (await networkInfo.isConnected) {
      try {
        final request = PunchOutRequest(
          punchOutLocation: punchOutLocation,
          latitude: latitude,
          longitude: longitude,
        );
        
        final response = await remoteDataSource.punchOut(request);
        
        return Right(PunchInResult(
          success: response.success,
          message: response.message ?? 'Punch-out successful',
          data: response.data,
        ));
      } on ServerException catch (e) {
        if (_isRetryableFailure(e.message)) {
          await offlineLocalDataSource.addPendingAction(action);
          return Right(
            PunchInResult(
              success: true,
              message:
                  'Punch-out saved offline. It will sync automatically when possible.',
              data: const {'queued': true},
            ),
          );
        }
        return Left(ServerFailure(e.message));
      } catch (e) {
        await offlineLocalDataSource.addPendingAction(action);
        return Right(
          PunchInResult(
            success: true,
            message:
                'Punch-out saved offline. It will sync automatically when possible.',
            data: const {'queued': true},
          ),
        );
      }
    } else {
      await offlineLocalDataSource.addPendingAction(action);
      return Right(
        PunchInResult(
          success: true,
          message: 'Punch-out saved offline. It will sync automatically.',
          data: const {'queued': true},
        ),
      );
    }
  }

  @override
  Future<bool> syncPendingActions() async {
    await _removeExpiredPendingActions();
    if (!await networkInfo.isConnected) return false;

    final actions = await offlineLocalDataSource.getPendingActions();
    if (actions.isEmpty) return true;

    for (final action in actions) {
      try {
        final preparedAction = await _prepareActionForSync(action);

        if (preparedAction == null) {
          return false;
        }

        if (preparedAction.type == OfflineAttendanceActionType.punchIn) {
          final offlinePunchIn = _formatOfflineTimestamp(preparedAction.createdAt);
          debugPrint(
            'Syncing offline punch-in with preserved timestamp: $offlinePunchIn',
          );
          await remoteDataSource.punchIn(
            PunchInRequest(
              punchInLocation: preparedAction.location,
              latitude: preparedAction.latitude,
              longitude: preparedAction.longitude,
              punchType: preparedAction.punchType ?? 'remote',
              punchIn: offlinePunchIn,
            ),
          );
        } else {
          final offlinePunchOut = _formatOfflineTimestamp(
            preparedAction.createdAt,
          );
          debugPrint(
            'Syncing offline punch-out with preserved timestamp: $offlinePunchOut',
          );
          await remoteDataSource.punchOut(
            PunchOutRequest(
              punchOutLocation: preparedAction.location,
              latitude: preparedAction.latitude,
              longitude: preparedAction.longitude,
              punchOut: offlinePunchOut,
            ),
          );
        }
        await offlineLocalDataSource.removePendingAction(action.id);
      } on ServerException catch (e) {
        if (_isRetryableFailure(e.message)) {
          await offlineLocalDataSource.updatePendingAction(
            action.copyWith(
              retryCount: action.retryCount + 1,
              lastError: e.message,
            ),
          );
          return false;
        }
        await offlineLocalDataSource.removePendingAction(action.id);
      } catch (e) {
        await offlineLocalDataSource.updatePendingAction(
          action.copyWith(
            retryCount: action.retryCount + 1,
            lastError: e.toString(),
          ),
        );
        return false;
      }
    }

    return !await offlineLocalDataSource.hasPendingActions();
  }

  @override
  Future<bool> hasPendingActions() {
    return _hasActivePendingActions();
  }

  @override
  Future<int> pruneExpiredPendingActions() {
    return _removeExpiredPendingActions();
  }

  String _buildActionId(OfflineAttendanceActionType type) {
    return '${type.value}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<bool> _hasActivePendingActions() async {
    await _removeExpiredPendingActions();
    return offlineLocalDataSource.hasPendingActions();
  }

  Future<int> _removeExpiredPendingActions() async {
    final actions = await offlineLocalDataSource.getPendingActions();
    if (actions.isEmpty) return 0;

    final referenceTime = DateTime.now();
    final expiredActions =
        actions
            .where((action) => !action.isForSameLocalDay(referenceTime))
            .toList();

    for (final action in expiredActions) {
      await offlineLocalDataSource.removePendingAction(action.id);
    }

    return expiredActions.length;
  }

  Future<OfflineAttendanceActionModel?> _prepareActionForSync(
    OfflineAttendanceActionModel action,
  ) async {
    if (!action.needsAddressResolution) {
      return action;
    }

    final resolvedAddress = await locationService.tryGetAddressFromCoordinates(
      action.latitude,
      action.longitude,
    );

    if (resolvedAddress != null) {
      final resolvedAction = action.copyWith(
        location: resolvedAddress,
        needsAddressResolution: false,
        addressResolutionAttempts: action.addressResolutionAttempts + 1,
        lastError: null,
      );
      await offlineLocalDataSource.updatePendingAction(resolvedAction);
      return resolvedAction;
    }

    final attempts = action.addressResolutionAttempts + 1;
    if (attempts < 3) {
      await offlineLocalDataSource.updatePendingAction(
        action.copyWith(
          addressResolutionAttempts: attempts,
          lastError: 'Waiting for address resolution before sync.',
        ),
      );
      return null;
    }

    final fallbackAction = action.copyWith(
      location: locationService.buildCoordinateFallback(
        action.latitude,
        action.longitude,
      ),
      needsAddressResolution: false,
      addressResolutionAttempts: attempts,
      lastError: 'Address resolution failed. Synced with coordinates fallback.',
    );
    await offlineLocalDataSource.updatePendingAction(fallbackAction);
    return fallbackAction;
  }

  bool _isRetryableFailure(String message) {
    final normalized = message.toLowerCase();
    const retryableMarkers = [
      'timeout',
      'timed out',
      'socket',
      'network',
      'connection',
      'host lookup',
      'temporarily unavailable',
      '503',
      '502',
      '504',
      'punch-in failed:',
      'punch-out failed:',
    ];
    return retryableMarkers.any(normalized.contains);
  }

  String _formatOfflineTimestamp(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(value.toLocal());
  }
}
