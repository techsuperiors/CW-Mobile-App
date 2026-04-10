import '../../domain/entities/announcement_entity.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    super.createdByUser,
    required super.createdAt,
    super.scheduleAnnouncement,
    required super.subject,
    super.repostThought,
    required super.description,
    super.type,
    super.documentUrls,
    super.totalLikes = 0,
    super.totalComments = 0,
    super.announcementLikes,
    super.reactionsCount,
    super.options,
    super.pollResults,
    super.answerResponse,
    super.question,
    super.badge,
    super.praisedUser,
    super.repostedBy,
    super.repostedByUser,
    super.repostPostCreatedAt,
    super.isEdited = false,
    super.comments,
    super.bookmarkedByUserIds,
    super.isLiked = false,
    super.adminRemark,
    super.reportedByCount = 0,
    super.reportedByUserIds = const [],
    super.reportedBy = const [],
    super.status = 'Active',
    super.enableLikes = true,
    super.enableComments = true,
    super.enableRepost = true,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final reportedByEntries = _reportedByEntries(json['reported_by']);
    return AnnouncementModel(
      id: json['id'] as int? ?? 0,
      createdByUser:
          json['createdByUser'] != null
              ? CreatedByUserModel.fromJson(
                json['createdByUser'] as Map<String, dynamic>,
              )
              : null,
      createdAt:
          json['created_at'] as String? ??
          json['schedule_announcement'] as String? ??
          '',
      scheduleAnnouncement:
          json['schedule_announcement'] as String? ??
          json['created_at'] as String?,
      subject: json['subject'] as String? ?? '',
      repostThought: json['repost_thought'] as String?,
      description: json['description'] as String? ?? '',
      type: json['type'] as String?,
      documentUrls:
          (json['document_urls'] as List?)
              ?.map((e) => MediaItemModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      totalLikes:
          json['total_likes'] as int? ?? json['likedCount'] as int? ?? 0,
      totalComments:
          json['total_comments'] as int? ?? json['commentCount'] as int? ?? 0,
      announcementLikes:
          (json['AnnouncementLikes'] as List?)
              ?.map(
                (e) =>
                    AnnouncementLikeModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      reactionsCount:
          (json['reactions_count'] as Map<String, dynamic>?)
              ?.cast<String, int>(),
      options: (json['options'] as List?)?.cast<String>(),
      pollResults:
          (json['pollResults'] as List?)
              ?.map((e) => PollOptionModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      answerResponse:
          (json['answer_response'] as List?)
              ?.map(
                (e) =>
                    PollAnswerResponseModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      question: json['question'] as String?,
      badge:
          json['Badge'] != null
              ? BadgeModel.fromJson(json['Badge'] as Map<String, dynamic>)
              : null,
      praisedUser:
          json['praisedUser'] != null
              ? PraisedUserModel.fromJson(
                json['praisedUser'] as Map<String, dynamic>,
              )
              : null,
      repostedBy: json['reposted_by'] as int?,
      repostedByUser:
          json['repostedByUser'] != null
              ? CreatedByUserModel.fromJson(
                json['repostedByUser'] as Map<String, dynamic>,
              )
              : null,
      repostPostCreatedAt: json['repost_post_created_at'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      comments:
          (json['Comments'] as List?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      bookmarkedByUserIds:
          (json['bookmarked_by_user_ids'] as List?)?.cast<int>(),
      isLiked: json['isLiked'] as bool? ?? false,
      adminRemark: json['admin_remark'] as String?,
      reportedByCount: reportedByEntries.length,
      reportedByUserIds: _reportedByUserIds(json['reported_by']),
      reportedBy: reportedByEntries,
      status: json['status'] as String? ?? 'Active',
      enableLikes: parseToBool(json['enable_likes'], fallback: true),
      enableComments: parseToBool(json['enable_comments'], fallback: true),
      enableRepost: parseToBool(json['enable_repost'], fallback: true),
    );
  }

  static List<ReportedByEntity> _reportedByEntries(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(ReportedByModel.fromJson)
          .toList(growable: false);
    }

    if (value is Map<String, dynamic>) {
      return [ReportedByModel.fromJson(value)];
    }

    return const [];
  }

  static List<int> _reportedByUserIds(dynamic value) {
    if (value is List) {
      return value
          .map(_parseReportedById)
          .where((id) => id > 0)
          .toList(growable: false);
    }

    final singleId = _parseReportedById(value);
    return singleId > 0 ? [singleId] : const [];
  }

  static int _parseReportedById(dynamic value) {
    if (value is Map<String, dynamic>) {
      return parseToInt(value['id']);
    }
    return parseToInt(value);
  }
}

class CreatedByUserModel extends CreatedByUserEntity {
  const CreatedByUserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.imageUrl,
    super.profileColor,
  });

  factory CreatedByUserModel.fromJson(Map<String, dynamic> json) {
    return CreatedByUserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }
}

class MediaItemModel extends MediaItemEntity {
  const MediaItemModel({
    super.id,
    super.name,
    required super.type,
    required super.url,
  });

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.comment,
    super.userId,
    super.isEdited = false,
    super.createdAt,
    super.commentLikes,
    super.reactionsCount,
    super.user,
    super.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      comment: json['comment'] as String? ?? '',
      userId: parseToInt(json['user_id']),
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      commentLikes:
          (json['CommentLikes'] as List?)
              ?.map((e) => CommentLikeModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      reactionsCount:
          (json['reactions_count'] as Map<String, dynamic>?)
              ?.cast<String, int>(),
      user:
          json['User'] != null
              ? CreatedByUserModel.fromJson(
                json['User'] as Map<String, dynamic>,
              )
              : null,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class CommentLikeModel extends CommentLikeEntity {
  const CommentLikeModel({
    super.id,
    required super.likedBy,
    required super.reactions,
  });

  factory CommentLikeModel.fromJson(Map<String, dynamic> json) {
    return CommentLikeModel(
      id: json['id'],
      likedBy: json['liked_by'],
      reactions:
          json['reactions'] as String? ??
          json['reaction_name'] as String? ??
          '',
    );
  }
}

class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.id,
    required super.name,
    super.color,
    super.icon,
    super.createdAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class PraisedUserModel extends PraisedUserEntity {
  const PraisedUserModel({
    required super.id,
    super.firstName,
    super.lastName,
    super.email,
  });

  factory PraisedUserModel.fromJson(Map<String, dynamic> json) {
    return PraisedUserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
    );
  }
}

class PollOptionModel extends PollOptionEntity {
  const PollOptionModel({
    required super.option,
    required super.count,
    required super.percentage,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      option: json['option'] as String? ?? '',
      count: parseToInt(json['count']),
      percentage: parseToDouble(json['percentage']),
    );
  }
}

double parseToDouble(dynamic value) {
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is num) return value.toDouble();
  return 0.0;
}

int parseToInt(dynamic value) {
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is num) return value.toInt();
  return 0;
}

bool parseToBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

class PollAnswerResponseModel extends PollAnswerResponseEntity {
  const PollAnswerResponseModel({
    required super.id,
    required super.userId,
    required super.option,
  });

  factory PollAnswerResponseModel.fromJson(Map<String, dynamic> json) {
    return PollAnswerResponseModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      option: json['option'] as String? ?? '',
    );
  }
}

class AnnouncementLikeModel extends AnnouncementLikeEntity {
  const AnnouncementLikeModel({
    super.id,
    required super.likedBy,
    required super.reactionName,
    super.createdAt,
    super.user,
  });

  factory AnnouncementLikeModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementLikeModel(
      id: json['id'],
      likedBy: json['liked_by'] as int? ?? 0,
      reactionName: json['reaction_name'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      user:
          json['User'] != null
              ? UserItemModel.fromJson(json['User'] as Map<String, dynamic>)
              : null,
    );
  }
}

class UserItemModel extends UserItemEntity {
  const UserItemModel({
    super.id,
    required super.firstName,
    required super.lastName,
    super.imageUrl,
    super.profileColor,
  });

  factory UserItemModel.fromJson(Map<String, dynamic> json) {
    return UserItemModel(
      id: json['id'] as int?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }
}

class ReportedByModel extends ReportedByEntity {
  const ReportedByModel({
    required super.id,
    required super.fullName,
    super.profileColor,
    required super.reason,
    super.reportedAt,
    super.designation,
  });

  factory ReportedByModel.fromJson(Map<String, dynamic> json) {
    return ReportedByModel(
      id: parseToInt(json['id']),
      fullName: json['full_name'] as String? ?? '',
      profileColor: json['profile_color'] as String?,
      reason: json['reason'] as String? ?? '',
      reportedAt: json['reported_at'] as String?,
      designation: json['designation'] as String?,
    );
  }
}

class AnnouncementResponseModel {
  final bool success;
  final List<AnnouncementModel> data;
  final int allAnnouncementCount;
  final int likedAnnouncementCount;
  final int myAnnouncementCount;
  final int pariseAnnouncementCount;
  final int pendingApprovalCount;
  final int reportedAnnouncementCount;
  final int totalRepostCount;

  AnnouncementResponseModel({
    required this.success,
    required this.data,
    required this.allAnnouncementCount,
    required this.likedAnnouncementCount,
    required this.myAnnouncementCount,
    required this.pariseAnnouncementCount,
    required this.pendingApprovalCount,
    required this.reportedAnnouncementCount,
    required this.totalRepostCount,
  });

  factory AnnouncementResponseModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponseModel(
      success: json['success'] as bool? ?? false,
      data:
          (json['data'] as List?)
              ?.map(
                (e) => AnnouncementModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      allAnnouncementCount: parseToInt(json['allAnnouncementCount']),
      likedAnnouncementCount: parseToInt(json['likedAnnouncementCount']),
      myAnnouncementCount: parseToInt(json['myAnnouncementCount']),
      pariseAnnouncementCount: parseToInt(
        json['pariseAnnouncementCount'] ?? json['praiseAnnouncementCount'],
      ),
      pendingApprovalCount: parseToInt(json['pendingApprovalCount']),
      reportedAnnouncementCount: parseToInt(json['reportedAnnouncementCount']),
      totalRepostCount: parseToInt(json['totalRepostCount']),
    );
  }
}
