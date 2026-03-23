import 'package:equatable/equatable.dart';

class AttendanceRequestCommentUser extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const AttendanceRequestCommentUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, profileColor];
}

class AttendanceRequestComment extends Equatable {
  final int id;
  final int requestId;
  final String comment;
  final String type;
  final String status;
  final int createdBy;
  final DateTime? createdAt;
  final AttendanceRequestCommentUser? user;

  const AttendanceRequestComment({
    required this.id,
    required this.requestId,
    required this.comment,
    required this.type,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.user,
  });

  @override
  List<Object?> get props => [
        id,
        requestId,
        comment,
        type,
        status,
        createdBy,
        createdAt,
        user,
      ];
}
