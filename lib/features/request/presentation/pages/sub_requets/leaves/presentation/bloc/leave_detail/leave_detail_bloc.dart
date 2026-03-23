import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/core/network/api_client.dart';
import 'package:collectivWork/core/constants/app_urls.dart';
import 'package:collectivWork/core/error/exceptions.dart';
import 'package:collectivWork/core/utils/data_encoder.dart';
import 'package:dio/dio.dart';
import '../../../data/models/leave_detail_model.dart';
import 'leave_detail_event.dart';
import 'leave_detail_state.dart';

class LeaveDetailBloc extends Bloc<LeaveDetailEvent, LeaveDetailState> {
  final ApiClient apiClient;

  LeaveDetailBloc({required this.apiClient}) : super(LeaveDetailInitial()) {
    on<FetchLeaveDetail>(_onFetchLeaveDetail);
    on<WithdrawLeave>(_onWithdrawLeave);
    on<UpdateLeaveStatus>(_onUpdateLeaveStatus);
    on<AddLeaveComment>(_onAddLeaveComment);
  }

  Future<void> _onFetchLeaveDetail(
    FetchLeaveDetail event,
    Emitter<LeaveDetailState> emit,
  ) async {
    emit(LeaveDetailLoading());
    try {
      final encodedPayload = encodeData({'leave_id': event.leaveId});
      developer.log(
        'Fetching leave detail: leave_id=${event.leaveId}',
        name: 'LeaveDetailBloc',
      );

      final response = await apiClient.get(
        '${AppUrls.leaveRequestDetails}?payload=$encodedPayload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load leave details',
        );
      }

      var detail = LeaveDetailModel.fromJson(data);
      final comments = await _fetchLeaveComments(event.leaveId);
      detail = detail.copyWith(comments: comments);
      developer.log(
        'Leave detail loaded: ${detail.leaveType} — ${detail.status}',
        name: 'LeaveDetailBloc',
      );
      emit(LeaveDetailLoaded(detail));
    } on ServerException catch (e) {
      emit(LeaveDetailError(e.message));
    } catch (e) {
      emit(LeaveDetailError('Failed to load leave details: $e'));
    }
  }

  Future<void> _onWithdrawLeave(
    WithdrawLeave event,
    Emitter<LeaveDetailState> emit,
  ) async {
    final currentState = state;
    LeaveDetailModel? detail;
    if (currentState is LeaveDetailLoaded) {
      detail = currentState.detail;
      emit(LeaveDetailWithdrawing(detail));
    }

    try {
      final encodedPayload = encodeData({'leave_request_id': event.leaveRequestId});
      developer.log(
        'Withdrawing leave: leave_request_id=${event.leaveRequestId}',
        name: 'LeaveDetailBloc',
      );

      final response = await apiClient.post(
        AppUrls.leaveWithdraw,
        data: {'payload': encodedPayload},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to withdraw leave',
        );
      }

      emit(LeaveDetailWithdrawn(data['message'] as String? ?? 'Leave withdrawn successfully'));
      
      // Refresh the details so the status updates in UI
      add(FetchLeaveDetail(event.leaveRequestId));
      
    } on ServerException catch (e) {
      emit(LeaveDetailError(e.message));
      if (detail != null) emit(LeaveDetailLoaded(detail)); // Revert if failed
    } catch (e) {
      emit(LeaveDetailError('Failed to withdraw leave: $e'));
      if (detail != null) emit(LeaveDetailLoaded(detail));
    }
  }

  Future<void> _onAddLeaveComment(
    AddLeaveComment event,
    Emitter<LeaveDetailState> emit,
  ) async {
    final currentState = state;
    LeaveDetailModel? detail;
    if (currentState is LeaveDetailLoaded) {
      detail = currentState.detail;
      emit(LeaveCommentSubmitting(detail));
    }

    try {
      final encodedPayload = encodeData({
        'leave_id': event.leaveId,
        'comment': event.comment,
      });

      final response = await apiClient.post(
        AppUrls.leaveComments,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to add comment',
        );
      }

      emit(
        LeaveCommentAdded(
          data['message'] as String? ?? 'Comment added on Leave',
        ),
      );
      add(FetchLeaveDetail(event.leaveId));
    } on ServerException catch (e) {
      emit(LeaveDetailError(e.message));
      if (detail != null) emit(LeaveDetailLoaded(detail));
    } catch (e) {
      emit(LeaveDetailError('Failed to add comment: $e'));
      if (detail != null) emit(LeaveDetailLoaded(detail));
    }
  }

  Future<void> _onUpdateLeaveStatus(
    UpdateLeaveStatus event,
    Emitter<LeaveDetailState> emit,
  ) async {
    final currentState = state;
    LeaveDetailModel? detail;
    if (currentState is LeaveDetailLoaded) {
      detail = currentState.detail;
      emit(
        LeaveDetailStatusUpdating(
          detail: currentState.detail,
          status: event.status,
        ),
      );
    }

    try {
      final encodedPayload = encodeData({
        'status': event.status,
        'leave_request_id': event.leaveRequestId,
        'user_id': event.userId,
      });

      final response = await apiClient.post(
        AppUrls.leaveRequestStatus,
        data: {'payload': encodedPayload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to update leave status',
        );
      }

      emit(
        LeaveStatusUpdated(
          data['message'] as String? ?? 'Leave request status updated',
        ),
      );
      add(FetchLeaveDetail(event.leaveRequestId));
    } on ServerException catch (e) {
      emit(LeaveDetailError(e.message));
      if (detail != null) emit(LeaveDetailLoaded(detail));
    } catch (e) {
      emit(LeaveDetailError('Failed to update leave status: $e'));
      if (detail != null) emit(LeaveDetailLoaded(detail));
    }
  }

  Future<List<LeaveComment>> _fetchLeaveComments(int leaveId) async {
    final encodedPayload = encodeData({'leave_id': leaveId});
    final response = await apiClient.get(
      '${AppUrls.leaveCommentsList}?payload=$encodedPayload',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ServerException(
        data['message'] as String? ?? 'Failed to load comments',
      );
    }

    return parseLeaveCommentsResponse(data);
  }
}
