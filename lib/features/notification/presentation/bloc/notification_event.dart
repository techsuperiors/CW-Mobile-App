import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotifications extends NotificationEvent {}

class FetchNotificationCount extends NotificationEvent {}

class MarkNotificationsAsViewed extends NotificationEvent {}

class ReadSingleNotification extends NotificationEvent {
  final int notificationId;

  const ReadSingleNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ClearNotificationCountLocally extends NotificationEvent {}
