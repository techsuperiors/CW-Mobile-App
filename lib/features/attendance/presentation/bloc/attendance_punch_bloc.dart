import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/location_service.dart';
import '../../data/datasources/attendance_offline_local_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/punch_in_usecase.dart';
import '../../domain/usecases/punch_out_usecase.dart';
import '../utils/attendance_punch_reconciliation_helper.dart';
import 'attendance_punch_event.dart';
import 'attendance_punch_state.dart';

/// Shared BLoC for PunchIn/PunchOut operations
///
/// Provided at app level (collectivWork.dart) so all screens share the same
/// instance. This ensures state consistency when navigating between Dashboard
/// and Services/Attendance screens.
///
/// Usage in widget:
/// ```dart
/// // Trigger punch in
/// context.read<AttendancePunchBloc>().add(const PunchInRequested());
///
/// // Listen to state changes
/// BlocListener<AttendancePunchBloc, AttendancePunchState>(
///   listener: (context, state) {
///     if (state is AttendancePunchInSuccess) { ... }
///   },
/// )
/// ```
class AttendancePunchBloc
    extends Bloc<AttendancePunchEvent, AttendancePunchState> {
  /// Guard flag to prevent duplicate requests from double-taps
  bool _isProcessing = false;
  bool _isSyncingPendingActions = false;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  AttendancePunchBloc() : super(const AttendancePunchInitial()) {
    on<PunchInRequested>(_onPunchInRequested);
    on<PunchOutRequested>(_onPunchOutRequested);
    on<PendingAttendanceSyncRequested>(_onPendingAttendanceSyncRequested);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none) {
        add(const PendingAttendanceSyncRequested(showFeedback: true));
      }
    });

    add(const PendingAttendanceSyncRequested(showFeedback: false));
  }

  /// Handle Punch In request
  Future<void> _onPunchInRequested(
    PunchInRequested event,
    Emitter<AttendancePunchState> emit,
  ) async {
    // Prevent duplicate requests (double-tap edge case)
    if (_isProcessing) return;
    _isProcessing = true;

    emit(const AttendancePunchLoading());

    try {
      String? punchInLocation;
      double? latitude;
      double? longitude;
      var needsAddressResolution = false;

      if (event.captureLocation) {
        final locationService = LocationService();
        final locationData = await locationService.getCurrentLocation();
        punchInLocation = locationData.address;
        latitude = locationData.latitude;
        longitude = locationData.longitude;
        needsAddressResolution = !locationData.hasResolvedAddress;
      }

      // Initialize dependency chain
      final punchInUseCase = _createPunchInUseCase();

      // Execute punch-in API call
      final result = await punchInUseCase(
        punchInLocation: punchInLocation,
        latitude: latitude,
        longitude: longitude,
        punchType: 'remote',
        needsAddressResolution: needsAddressResolution,
      );

      // Handle Either result
      result.fold(
        (failure) => emit(AttendancePunchError(message: failure.message)),
        (success) {
          final needsReconciliation =
              AttendancePunchReconciliationHelper.requiresPunchInReconciliation(
                success.message,
              );
          emit(
            AttendancePunchInSuccess(
              message: success.message,
              punchInTime: DateTime.now(),
              requiresServerRefresh: needsReconciliation,
              isQueuedOffline: success.data?['queued'] == true,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('PunchIn error: $e');
      emit(AttendancePunchError(message: _getReadableErrorMessage(e)));
    } finally {
      _isProcessing = false;
    }
  }

  /// Handle Punch Out request
  Future<void> _onPunchOutRequested(
    PunchOutRequested event,
    Emitter<AttendancePunchState> emit,
  ) async {
    // Prevent duplicate requests
    if (_isProcessing) return;
    _isProcessing = true;

    emit(const AttendancePunchLoading());

    try {
      String? punchOutLocation;
      double? latitude;
      double? longitude;
      var needsAddressResolution = false;

      if (event.captureLocation) {
        final locationService = LocationService();
        final locationData = await locationService.getCurrentLocation();
        punchOutLocation = locationData.address;
        latitude = locationData.latitude;
        longitude = locationData.longitude;
        needsAddressResolution = !locationData.hasResolvedAddress;
      }

      // Initialize dependency chain
      final punchOutUseCase = _createPunchOutUseCase();

      // Execute punch-out API call
      final result = await punchOutUseCase(
        punchOutLocation: punchOutLocation,
        latitude: latitude,
        longitude: longitude,
        needsAddressResolution: needsAddressResolution,
      );

      // Handle Either result
      result.fold(
        (failure) => emit(AttendancePunchError(message: failure.message)),
        (success) {
          final needsReconciliation =
              AttendancePunchReconciliationHelper.requiresPunchOutReconciliation(
                success.message,
              );
          emit(
            AttendancePunchOutSuccess(
              message: success.message,
              requiresServerRefresh: needsReconciliation,
              isQueuedOffline: success.data?['queued'] == true,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('PunchOut error: $e');
      emit(AttendancePunchError(message: _getReadableErrorMessage(e)));
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onPendingAttendanceSyncRequested(
    PendingAttendanceSyncRequested event,
    Emitter<AttendancePunchState> emit,
  ) async {
    if (_isSyncingPendingActions) return;
    _isSyncingPendingActions = true;

    try {
      final repository = _createAttendanceRepository();
      final hadPendingActions = await repository.hasPendingActions();
      if (!hadPendingActions) return;

      final synced = await repository.syncPendingActions();
      if (synced && event.showFeedback) {
        emit(
          AttendancePendingSyncSuccess(
            message: 'Pending attendance actions synced successfully.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Pending attendance sync error: $e');
    } finally {
      _isSyncingPendingActions = false;
    }
  }

  /// Creates user-friendly error messages from exceptions
  String _getReadableErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('location') || message.contains('permission')) {
      return 'Unable to get location. Please enable location services and try again.';
    }
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
    // return message;
  }

  /// Create PunchInUseCase with full dependency chain
  PunchInUseCase _createPunchInUseCase() {
    final repository = _createAttendanceRepository();
    return PunchInUseCase(repository);
  }

  AttendanceRepository _createAttendanceRepository() {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = AttendanceRemoteDataSourceImpl(apiClient);
    return AttendanceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
      offlineLocalDataSource: AttendanceOfflineLocalDataSourceImpl(),
      locationService: LocationService(),
    );
  }

  /// Create PunchOutUseCase with full dependency chain
  PunchOutUseCase _createPunchOutUseCase() {
    return PunchOutUseCase(_createAttendanceRepository());
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
