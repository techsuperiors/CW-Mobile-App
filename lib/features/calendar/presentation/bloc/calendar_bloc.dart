import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/calendar_remote_datasource.dart';
import '../../data/repository/calendar_repository_impl.dart';
import '../../domain/entities/calendar_day_entity.dart';
import '../../domain/usecases/get_calendar_data_usecase.dart';

// ─── Events ───

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when a month's calendar data should be loaded.
class LoadCalendarData extends CalendarEvent {
  final int month; // 1–12
  final int year;

  const LoadCalendarData({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

// ─── States ───

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  final List<CalendarDayEntity> days;

  const CalendarLoaded(this.days);

  @override
  List<Object?> get props => [days];
}

class CalendarError extends CalendarState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───

/// Manages calendar data fetching for a given month and year.
/// Reuses a single ApiClient instance across events (no new Dio per call).
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  late final GetCalendarDataUseCase _useCase;

  CalendarBloc() : super(const CalendarInitial()) {
    // Create dependencies once and reuse — avoids new Dio per event
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = CalendarRemoteDataSourceImpl(apiClient);
    final repository = CalendarRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    _useCase = GetCalendarDataUseCase(repository);

    on<LoadCalendarData>(
      _onLoadCalendarData,
      // Allow concurrent events so fast month-nav doesn't queue up stale calls
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _onLoadCalendarData(
    LoadCalendarData event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());

    try {
      final result = await _useCase(event.month, event.year);

      result.fold(
        (failure) => emit(CalendarError(failure.message)),
        (days) => emit(CalendarLoaded(days)),
      );
    } catch (e) {
      emit(CalendarError('Failed to load calendar: ${e.toString()}'));
    }
  }
}
