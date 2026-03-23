import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_notification_count.dart';
import '../../domain/usecases/view_notifications.dart';
import '../../domain/usecases/read_notification.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final GetNotificationCount getNotificationCount;
  final ViewNotifications viewNotifications;
  final ReadNotification readNotification;

  NotificationBloc({
    required this.getNotifications,
    required this.getNotificationCount,
    required this.viewNotifications,
    required this.readNotification,
  }) : super(NotificationInitial()) {
    on<FetchNotifications>(_onFetchNotifications);
    on<FetchNotificationCount>(_onFetchNotificationCount);
    on<MarkNotificationsAsViewed>(_onMarkNotificationsAsViewed);
    on<ReadSingleNotification>(_onReadSingleNotification);
    on<ClearNotificationCountLocally>(_onClearNotificationCountLocally);
  }

  void _onClearNotificationCountLocally(
    ClearNotificationCountLocally event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationCountLoaded(count: 0));
  }

  Future<void> _onFetchNotifications(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    final failureOrNotifications = await getNotifications();

    failureOrNotifications.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) {
        final hasUnread = notifications.any(
          (notification) => !notification.isRead,
        );
        emit(
          NotificationLoaded(
            notifications: notifications,
            hasUnread: hasUnread,
          ),
        );
      },
    );
  }

  Future<void> _onFetchNotificationCount(
    FetchNotificationCount event,
    Emitter<NotificationState> emit,
  ) async {
    final failureOrCount = await getNotificationCount();

    failureOrCount.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (count) => emit(NotificationCountLoaded(count: count)),
    );
  }

  Future<void> _onMarkNotificationsAsViewed(
    MarkNotificationsAsViewed event,
    Emitter<NotificationState> emit,
  ) async {
    final failureOrVoid = await viewNotifications();

    failureOrVoid.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) {
        if (state is NotificationCountLoaded) {
          emit(const NotificationCountLoaded(count: 0));
        } else if (state is NotificationLoaded) {
          final currentState = state as NotificationLoaded;
          final updatedNotifications = currentState.notifications.map((n) {
            return NotificationEntity(
              id: n.id,
              isRead: true,
              readAt: n.readAt ?? DateTime.now(),
              sentBy: n.sentBy,
              title: n.title,
              message: n.message,
              module: n.module,
              createdAt: n.createdAt,
              userId: n.userId,
              sentByNotifications: n.sentByNotifications,
            );
          }).toList();
          emit(
            NotificationLoaded(
              notifications: updatedNotifications,
              hasUnread: false,
            ),
          );
        }
      },
    );
  }

  Future<void> _onReadSingleNotification(
    ReadSingleNotification event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic Update
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == event.notificationId) {
          return NotificationEntity(
            id: n.id,
            isRead: true,
            readAt: n.readAt ?? DateTime.now(),
            sentBy: n.sentBy,
            title: n.title,
            message: n.message,
            module: n.module,
            createdAt: n.createdAt,
            userId: n.userId,
            sentByNotifications: n.sentByNotifications,
          );
        }
        return n;
      }).toList();

      final hasUnread = updatedNotifications.any((n) => !n.isRead);

      emit(
        NotificationLoaded(
          notifications: updatedNotifications,
          hasUnread: hasUnread,
        ),
      );
    }

    // Call API
    final failureOrVoid = await readNotification(event.notificationId);

    failureOrVoid.fold(
      (failure) {
        // We could revert the optimistic update or emit an error, but silent fail is typical for read status unless specified otherwise.
        // For robustness, returning state back to what it was is preferred, but since it's just 'isRead', we can log it.
        // Let's emit error to show toast if it fails.
        // We might not want to wipe the list just to show an error, so we don't emit NotificationError if it replaces the whole list.
      },
      (_) {}, // Success
    );
  }
}
