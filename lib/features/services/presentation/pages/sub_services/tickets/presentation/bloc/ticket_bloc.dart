import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_ticket_list_usecase.dart';
import '../../domain/usecases/get_ticket_stats_usecase.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/usecases/upload_ticket_file_usecase.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

/// Ticket BLoC
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final GetTicketListUseCase getTicketListUseCase;
  final GetTicketStatsUseCase getTicketStatsUseCase;
  final GetTicketDetailsUseCase getTicketDetailsUseCase;
  final UploadTicketFileUseCase uploadTicketFileUseCase;

  TicketBloc({
    required this.getTicketListUseCase,
    required this.getTicketStatsUseCase,
    required this.getTicketDetailsUseCase,
    required this.uploadTicketFileUseCase,
  }) : super(const TicketInitial()) {
    on<LoadTicketList>(_onLoadTicketList);
    on<RefreshTicketList>(_onRefreshTicketList);
    on<LoadTicketStats>(_onLoadTicketStats);
    on<LoadTicketData>(_onLoadTicketData);
    on<LoadTicketDetails>(_onLoadTicketDetails);
    on<UploadTicketFile>(_onUploadTicketFile);
  }

  Future<void> _onLoadTicketList(
    LoadTicketList event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());

    final result = await getTicketListUseCase(event.requestType);

    result.fold(
      (failure) {
        emit(TicketError(failure.message));
      },
      (ticketList) {
        emit(TicketLoaded(ticketList: ticketList, requestType: event.requestType));
      },
    );
  }

  Future<void> _onRefreshTicketList(
    RefreshTicketList event,
    Emitter<TicketState> emit,
  ) async {
    final result = await getTicketListUseCase(event.requestType);

    result.fold(
      (failure) {
        emit(TicketError(failure.message));
      },
      (ticketList) {
        emit(TicketLoaded(ticketList: ticketList, requestType: event.requestType));
      },
    );
  }

  Future<void> _onLoadTicketStats(
    LoadTicketStats event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketStatsLoading());

    final result = await getTicketStatsUseCase();

    result.fold(
      (failure) {
        emit(TicketStatsError(failure.message));
      },
      (stats) {
        emit(TicketStatsLoaded(stats: stats));
      },
    );
  }

  Future<void> _onLoadTicketData(
    LoadTicketData event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());

    // Load both APIs in parallel
    final ticketListResult = await getTicketListUseCase(event.requestType);
    final statsResult = await getTicketStatsUseCase();

    // Check if both succeeded
    ticketListResult.fold(
      (failure) {
        emit(TicketError(failure.message));
      },
      (ticketList) {
        statsResult.fold(
          (failure) {
            emit(TicketError(failure.message));
          },
          (stats) {
            // Both APIs succeeded, emit combined state
            emit(TicketDataLoaded(
              ticketList: ticketList,
              requestType: event.requestType,
              stats: stats,
            ));
          },
        );
      },
    );
  }

  Future<void> _onLoadTicketDetails(
    LoadTicketDetails event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketDetailsLoading());

    final result = await getTicketDetailsUseCase(event.ticketId);

    result.fold(
      (failure) {
        emit(TicketDetailsError(failure.message));
      },
      (details) {
        emit(TicketDetailsLoaded(details: details));
      },
    );
  }

  Future<void> _onUploadTicketFile(
    UploadTicketFile event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketFileUploading());

    final result = await uploadTicketFileUseCase(
      event.clientId,
      event.ticketId,
      event.filePath,
    );

    result.fold(
      (failure) {
        emit(TicketFileUploadError(failure.message));
      },
      (stats) {
        emit(TicketFileUploaded(stats: stats));
      },
    );
  }
}
