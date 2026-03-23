import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/location_service.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/usecases/punch_in_usecase.dart';
import '../../domain/usecases/punch_out_usecase.dart';
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

  AttendancePunchBloc() : super(const AttendancePunchInitial()) {
    on<PunchInRequested>(_onPunchInRequested);
    on<PunchOutRequested>(_onPunchOutRequested);
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
      // Fetch current location with implicit timeout from LocationService
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      // Initialize dependency chain
      final punchInUseCase = _createPunchInUseCase();

      // Execute punch-in API call
      final result = await punchInUseCase(
        punchInLocation: locationData.address,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        punchType: 'remote',
      );

      // Handle Either result
      result.fold(
        (failure) => emit(AttendancePunchError(message: failure.message)),
        (success) => emit(
          AttendancePunchInSuccess(
            message: success.message,
            punchInTime: DateTime.now(),
          ),
        ),
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
      // Fetch current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      // Initialize dependency chain
      final punchOutUseCase = _createPunchOutUseCase();

      // Execute punch-out API call
      final result = await punchOutUseCase(
        punchOutLocation: locationData.address,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );

      // Handle Either result
      result.fold(
        (failure) => emit(AttendancePunchError(message: failure.message)),
        (success) => emit(AttendancePunchOutSuccess(message: success.message)),
      );
    } catch (e) {
      debugPrint('PunchOut error: $e');
      emit(AttendancePunchError(message: _getReadableErrorMessage(e)));
    } finally {
      _isProcessing = false;
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
  }

  /// Create PunchInUseCase with full dependency chain
  PunchInUseCase _createPunchInUseCase() {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = AttendanceRemoteDataSourceImpl(apiClient);
    final repository = AttendanceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    return PunchInUseCase(repository);
  }

  /// Create PunchOutUseCase with full dependency chain
  PunchOutUseCase _createPunchOutUseCase() {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = AttendanceRemoteDataSourceImpl(apiClient);
    final repository = AttendanceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    return PunchOutUseCase(repository);
  }
}
