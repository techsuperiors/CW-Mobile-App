import 'package:equatable/equatable.dart';

class AnnouncementEntity extends Equatable {
  final int id;
  final CreatedByUserEntity? createdByUser;
  final String createdAt;
  final String? scheduleAnnouncement;
  final String subject;
  final String? repostThought;
  final String description;
  final String? type;
  final List<MediaItemEntity>? documentUrls;
  final int totalLikes;
  final int totalComments;
  final List<AnnouncementLikeEntity>? announcementLikes;
  final Map<String, int>? reactionsCount;
  final List<String>? options;
  final List<PollOptionEntity>? pollResults;
  final List<PollAnswerResponseEntity>? answerResponse;
  final String? question;
  final BadgeEntity? badge;
  final PraisedUserEntity? praisedUser;
  final int? repostedBy;
  final CreatedByUserEntity? repostedByUser;
  final String? repostPostCreatedAt;
  final bool isEdited;
  final List<CommentEntity>? comments;
  final List<int>? bookmarkedByUserIds;
  final bool isLiked;
  final String? adminRemark;
  final int reportedByCount;
  final List<int> reportedByUserIds;
  final List<ReportedByEntity> reportedBy;
  final String status;
  final bool enableLikes;
  final bool enableComments;
  final bool enableRepost;

  const AnnouncementEntity({
    required this.id,
    this.createdByUser,
    required this.createdAt,
    this.scheduleAnnouncement,
    required this.subject,
    this.repostThought,
    required this.description,
    this.type,
    this.documentUrls,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.announcementLikes,
    this.reactionsCount,
    this.options,
    this.pollResults,
    this.answerResponse,
    this.question,
    this.badge,
    this.praisedUser,
    this.repostedBy,
    this.repostedByUser,
    this.repostPostCreatedAt,
    this.isEdited = false,
    this.comments,
    this.bookmarkedByUserIds,
    this.isLiked = false,
    this.adminRemark,
    this.reportedByCount = 0,
    this.reportedByUserIds = const [],
    this.reportedBy = const [],
    this.status = 'Active',
    this.enableLikes = true,
    this.enableComments = true,
    this.enableRepost = true,
  });

  AnnouncementEntity copyWith({
    int? id,
    CreatedByUserEntity? createdByUser,
    String? createdAt,
    String? scheduleAnnouncement,
    String? subject,
    String? repostThought,
    String? description,
    String? type,
    List<MediaItemEntity>? documentUrls,
    int? totalLikes,
    int? totalComments,
    List<AnnouncementLikeEntity>? announcementLikes,
    Map<String, int>? reactionsCount,
    List<String>? options,
    List<PollOptionEntity>? pollResults,
    List<PollAnswerResponseEntity>? answerResponse,
    String? question,
    BadgeEntity? badge,
    PraisedUserEntity? praisedUser,
    int? repostedBy,
    CreatedByUserEntity? repostedByUser,
    String? repostPostCreatedAt,
    bool? isEdited,
    List<CommentEntity>? comments,
    List<int>? bookmarkedByUserIds,
    bool? isLiked,
    String? adminRemark,
    int? reportedByCount,
    List<int>? reportedByUserIds,
    List<ReportedByEntity>? reportedBy,
    String? status,
    bool? enableLikes,
    bool? enableComments,
    bool? enableRepost,
  }) {
    return AnnouncementEntity(
      id: id ?? this.id,
      createdByUser: createdByUser ?? this.createdByUser,
      createdAt: createdAt ?? this.createdAt,
      scheduleAnnouncement: scheduleAnnouncement ?? this.scheduleAnnouncement,
      subject: subject ?? this.subject,
      repostThought: repostThought ?? this.repostThought,
      description: description ?? this.description,
      type: type ?? this.type,
      documentUrls: documentUrls ?? this.documentUrls,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      announcementLikes: announcementLikes ?? this.announcementLikes,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      options: options ?? this.options,
      pollResults: pollResults ?? this.pollResults,
      answerResponse: answerResponse ?? this.answerResponse,
      question: question ?? this.question,
      badge: badge ?? this.badge,
      praisedUser: praisedUser ?? this.praisedUser,
      repostedBy: repostedBy ?? this.repostedBy,
      repostedByUser: repostedByUser ?? this.repostedByUser,
      repostPostCreatedAt: repostPostCreatedAt ?? this.repostPostCreatedAt,
      isEdited: isEdited ?? this.isEdited,
      comments: comments ?? this.comments,
      bookmarkedByUserIds: bookmarkedByUserIds ?? this.bookmarkedByUserIds,
      isLiked: isLiked ?? this.isLiked,
      adminRemark: adminRemark ?? this.adminRemark,
      reportedByCount: reportedByCount ?? this.reportedByCount,
      reportedByUserIds: reportedByUserIds ?? this.reportedByUserIds,
      reportedBy: reportedBy ?? this.reportedBy,
      status: status ?? this.status,
      enableLikes: enableLikes ?? this.enableLikes,
      enableComments: enableComments ?? this.enableComments,
      enableRepost: enableRepost ?? this.enableRepost,
    );
  }

  @override
  List<Object?> get props => [
        id,
        createdByUser,
        createdAt,
        scheduleAnnouncement,
        subject,
        repostThought,
        description,
        type,
        documentUrls,
        totalLikes,
        totalComments,
        announcementLikes,
        reactionsCount,
        options,
        pollResults,
        answerResponse,
        question,
        badge,
        praisedUser,
        repostedBy,
        repostedByUser,
        repostPostCreatedAt,
        isEdited,
        comments,
        bookmarkedByUserIds,
        isLiked,
        adminRemark,
        reportedByCount,
        reportedByUserIds,
        reportedBy,
        status,
        enableLikes,
        enableComments,
        enableRepost,
      ];
}

class ReportedByEntity extends Equatable {
  final int id;
  final String fullName;
  final String? profileColor;
  final String reason;
  final String? reportedAt;
  final String? designation;

  const ReportedByEntity({
    required this.id,
    required this.fullName,
    this.profileColor,
    required this.reason,
    this.reportedAt,
    this.designation,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    profileColor,
    reason,
    reportedAt,
    designation,
  ];
}

class CreatedByUserEntity extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const CreatedByUserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, profileColor];
}

class MediaItemEntity extends Equatable {
  final dynamic id;
  final String? name;
  final String type;
  final String url;

  const MediaItemEntity({
    this.id,
    this.name,
    required this.type,
    required this.url,
  });

  @override
  List<Object?> get props => [id, name, type, url];
}

class CommentEntity extends Equatable {
  final dynamic id;
  final String comment;
  final int? userId;
  final bool isEdited;
  final String? createdAt;
  final List<CommentLikeEntity>? commentLikes;
  final Map<String, int>? reactionsCount;
  final CreatedByUserEntity? user;
  final String? updatedAt;

  const CommentEntity({
    required this.id,
    required this.comment,
    this.userId,
    this.isEdited = false,
    this.createdAt,
    this.commentLikes,
    this.reactionsCount,
    this.user,
    this.updatedAt,
  });

  CommentEntity copyWith({
    dynamic id,
    String? comment,
    int? userId,
    bool? isEdited,
    String? createdAt,
    List<CommentLikeEntity>? commentLikes,
    Map<String, int>? reactionsCount,
    CreatedByUserEntity? user,
    String? updatedAt,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      userId: userId ?? this.userId,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      commentLikes: commentLikes ?? this.commentLikes,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      user: user ?? this.user,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    comment,
    userId,
    isEdited,
    createdAt,
    commentLikes,
    reactionsCount,
    user,
    updatedAt,
  ];
}

class CommentLikeEntity extends Equatable {
  final dynamic id;
  final dynamic likedBy;
  final String reactions;

  const CommentLikeEntity({
    this.id,
    required this.likedBy,
    required this.reactions,
  });

  CommentLikeEntity copyWith({
    dynamic id,
    dynamic likedBy,
    String? reactions,
  }) {
    return CommentLikeEntity(
      id: id ?? this.id,
      likedBy: likedBy ?? this.likedBy,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  List<Object?> get props => [id, likedBy, reactions];
}

class BadgeEntity extends Equatable {
  final int id;
  final String name;
  final String? color;
  final String? icon;
  final String? createdAt;

  const BadgeEntity({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, color, icon, createdAt];
}

class PraisedUserEntity extends Equatable {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;

  const PraisedUserEntity({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  @override
  List<Object?> get props => [id, firstName, lastName, email];
}

class PollOptionEntity extends Equatable {
  final String option;
  final int count;
  final double percentage;

  const PollOptionEntity({
    required this.option,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [option, count, percentage];
}

class PollAnswerResponseEntity extends Equatable {
  final int id;
  final int userId;
  final String option;

  const PollAnswerResponseEntity({
    required this.id,
    required this.userId,
    required this.option,
  });

  @override
  List<Object?> get props => [id, userId, option];
}

class AnnouncementLikeEntity extends Equatable {
  final dynamic id;
  final int likedBy;
  final String reactionName;
  final String? createdAt;
  final UserItemEntity? user;

  const AnnouncementLikeEntity({
    this.id,
    required this.likedBy,
    required this.reactionName,
    this.createdAt,
    this.user,
  });

  @override
  List<Object?> get props => [id, likedBy, reactionName, createdAt, user];
}

class UserItemEntity extends Equatable {
  final int? id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const UserItemEntity({
    this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, profileColor];
}
