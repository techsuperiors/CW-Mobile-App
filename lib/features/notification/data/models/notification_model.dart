import '../../domain/entities/notification_entity.dart';

class SentByNotificationsModel extends SentByNotificationsEntity {
  const SentByNotificationsModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.imageUrl,
    required super.profileColor,
  });

  factory SentByNotificationsModel.fromJson(Map<String, dynamic> json) {
    return SentByNotificationsModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'image_url': imageUrl,
      'profile_color': profileColor,
    };
  }
}

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.isRead,
    super.readAt,
    required super.sentBy,
    required super.title,
    required super.message,
    required super.module,
    required super.createdAt,
    required super.userId,
    required super.sentByNotifications,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      isRead: json['is_read'] as bool? ?? false,
      readAt:
          json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      sentBy: json['sent_by'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      module: json['module'] as String? ?? '',
      // createdAt:
      //     json['created_at'] != null
      //         ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
      //         : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      userId: json['user_id'] as int? ?? 0,
      sentByNotifications: SentByNotificationsModel.fromJson(
        json['sentByNotifications'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'sent_by': sentBy,
      'title': title,
      'message': message,
      'module': module,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'sentByNotifications':
          (sentByNotifications as SentByNotificationsModel).toJson(),
    };
  }
}

class NotificationResponseModel {
  final bool success;
  final List<NotificationModel> allData;
  final List<NotificationModel> paginationData;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  NotificationResponseModel({
    required this.success,
    required this.allData,
    required this.paginationData,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) {
    var allDataJson = json['allData'] as List? ?? [];
    var paginationDataJson = json['paginationData'] as List? ?? [];

    return NotificationResponseModel(
      success: json['success'] as bool? ?? false,
      allData: allDataJson.map((e) => NotificationModel.fromJson(e)).toList(),
      paginationData:
          paginationDataJson.map((e) => NotificationModel.fromJson(e)).toList(),
      totalCount: json['totalCount'] as int?,
      currentPage: json['currentPage'] as int?,
      totalPages: json['totalPages'] as int?,
    );
  }
}
