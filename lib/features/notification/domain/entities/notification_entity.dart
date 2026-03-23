import 'package:equatable/equatable.dart';

class SentByNotificationsEntity extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String profileColor;

  const SentByNotificationsEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    required this.profileColor,
  });

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, profileColor];
}

class NotificationEntity extends Equatable {
  final int id;
  final bool isRead;
  final DateTime? readAt;
  final int sentBy;
  final String title;
  final String message;
  final String module;
  final DateTime createdAt;
  final int userId;
  final SentByNotificationsEntity sentByNotifications;

  const NotificationEntity({
    required this.id,
    required this.isRead,
    this.readAt,
    required this.sentBy,
    required this.title,
    required this.message,
    required this.module,
    required this.createdAt,
    required this.userId,
    required this.sentByNotifications,
  });

  @override
  List<Object?> get props => [
    id,
    isRead,
    readAt,
    sentBy,
    title,
    message,
    module,
    createdAt,
    userId,
    sentByNotifications,
  ];
}
