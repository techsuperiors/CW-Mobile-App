/// Ticket Created By User Model
class TicketCreatedByModel {
  final String? firstName;
  final String? lastName;
  final String? profileColor;
  final String? imageUrl;

  TicketCreatedByModel({
    this.firstName,
    this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  factory TicketCreatedByModel.fromJson(Map<String, dynamic> json) {
    return TicketCreatedByModel(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileColor: json['profile_color'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket Model based on API response
class TicketApiModel {
  final int id;
  final String ticketID;
  final String priority;
  final String subject;
  final String ticketStatus;
  final int ticketCategoryId;
  final int? ticketSubCategoryId;
  final int? pinnedBy;
  final int createdBy;
  final int? raisedFor;
  final String createdAt;
  final String updatedAt;
  final TicketCreatedByModel createdByUser;
  final String categoryName;
  final String? subcategoryName;

  TicketApiModel({
    required this.id,
    required this.ticketID,
    required this.priority,
    required this.subject,
    required this.ticketStatus,
    required this.ticketCategoryId,
    this.ticketSubCategoryId,
    this.pinnedBy,
    required this.createdBy,
    this.raisedFor,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUser,
    required this.categoryName,
    this.subcategoryName,
  });

  factory TicketApiModel.fromJson(Map<String, dynamic> json) {
    return TicketApiModel(
      id: (json['id'] as int?) ?? 0,
      ticketID: json['ticketID'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      ticketStatus: json['ticket_status'] as String? ?? '',
      ticketCategoryId: (json['ticket_category_id'] as int?) ?? 0,
      ticketSubCategoryId: json['ticket_subCategory_id'] as int?,
      pinnedBy: json['pinned_by'] as int?,
      createdBy: (json['created_by'] as int?) ?? 0,
      raisedFor: json['raised_for'] as int?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      createdByUser: TicketCreatedByModel.fromJson(
        json['createdBy'] as Map<String, dynamic>? ?? {},
      ),
      categoryName: json['category_name'] as String? ?? '',
      subcategoryName: json['subcategory_name'] as String?,
    );
  }
}

/// Ticket List API Response
class TicketListApiResponse {
  final bool success;
  final String? message;
  final List<TicketApiModel>? data;

  TicketListApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory TicketListApiResponse.fromJson(Map<String, dynamic> json) {
    List<TicketApiModel> tickets = [];
    if (json['data'] != null && json['data'] is List) {
      tickets = (json['data'] as List)
          .map((item) => TicketApiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return TicketListApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: tickets,
    );
  }
}

/// Ticket Stats Model based on API response
class TicketStatsModel {
  final int open;
  final int inProgress;
  final int resolved;
  final int escalated;

  TicketStatsModel({
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.escalated,
  });

  factory TicketStatsModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int values
    int parseCount(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return TicketStatsModel(
      open: parseCount(json['open'] ?? json['Open'] ?? 0),
      inProgress: parseCount(json['In-Progress'] ?? json['in-progress'] ?? json['inProgress'] ?? 0),
      resolved: parseCount(json['Resolved'] ?? json['resolved'] ?? 0),
      escalated: parseCount(json['Escalated'] ?? json['escalated'] ?? 0),
    );
  }
}

/// Ticket Stats API Response
class TicketStatsApiResponse {
  final bool success;
  final String? message;
  final TicketStatsModel? data;

  TicketStatsApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory TicketStatsApiResponse.fromJson(Map<String, dynamic> json) {
    TicketStatsModel? statsData;
    if (json['data'] != null && json['data'] is Map) {
      statsData = TicketStatsModel.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    return TicketStatsApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: statsData,
    );
  }
}

/// Ticket Document Model
class TicketDocumentModel {
  final String id;
  final String url;
  final String name;

  TicketDocumentModel({
    required this.id,
    required this.url,
    required this.name,
  });

  factory TicketDocumentModel.fromJson(Map<String, dynamic> json) {
    return TicketDocumentModel(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Ticket Activity Model
class TicketActivityModel {
  final String action;
  final String actionType;
  final String? userEmail;
  final String? firstName;
  final String? lastName;
  final int? createdBy;
  final String createdAt;

  TicketActivityModel({
    required this.action,
    required this.actionType,
    this.userEmail,
    this.firstName,
    this.lastName,
    this.createdBy,
    required this.createdAt,
  });

  factory TicketActivityModel.fromJson(Map<String, dynamic> json) {
    return TicketActivityModel(
      action: json['action'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      userEmail: json['user_email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket User Model (for raised_for, created_by, assigneeTicket, createdBy)
class TicketUserModel {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? profileColor;
  final String? imageUrl;
  final String? phone;
  final String? email;

  TicketUserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.profileColor,
    this.imageUrl,
    this.phone,
    this.email,
  });

  factory TicketUserModel.fromJson(Map<String, dynamic> json) {
    return TicketUserModel(
      id: (json['id'] as int?) ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileColor: json['profile_color'] as String?,
      imageUrl: json['image_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket Category Model
class TicketCategoryModel {
  final int id;
  final String categoryName;
  final List<dynamic> followers;
  final List<int> assignee;
  final bool hasSubCategories;

  TicketCategoryModel({
    required this.id,
    required this.categoryName,
    required this.followers,
    required this.assignee,
    required this.hasSubCategories,
  });

  factory TicketCategoryModel.fromJson(Map<String, dynamic> json) {
    return TicketCategoryModel(
      id: (json['id'] as int?) ?? 0,
      categoryName: json['category_name'] as String? ?? '',
      followers: json['followers'] as List<dynamic>? ?? [],
      assignee: (json['assignee'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      hasSubCategories: json['has_SubCategories'] as bool? ?? false,
    );
  }
}

/// Ticket Follower Model
class TicketFollowerModel {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? profileColor;
  final String? imageUrl;

  TicketFollowerModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  factory TicketFollowerModel.fromJson(Map<String, dynamic> json) {
    return TicketFollowerModel(
      id: (json['id'] as int?) ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileColor: json['profile_color'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket Details Model based on API response
class TicketDetailsModel {
  final int id;
  final String subject;
  final String priority;
  final int? assignee;
  final String description;
  final String ticketStatus;
  final List<TicketDocumentModel> documents;
  final List<TicketActivityModel> activity;
  final int ticketCategoryId;
  final int? ticketSubCategoryId;
  final String ticketID;
  final TicketUserModel? raisedFor;
  final int createdBy;
  final String createdAt;
  final TicketUserModel? assigneeTicket;
  final TicketUserModel? createdByUser;
  final TicketCategoryModel? ticketCategory;
  final dynamic ticketSubCategory; // Can be null
  final List<TicketFollowerModel> followers;

  TicketDetailsModel({
    required this.id,
    required this.subject,
    required this.priority,
    this.assignee,
    required this.description,
    required this.ticketStatus,
    required this.documents,
    required this.activity,
    required this.ticketCategoryId,
    this.ticketSubCategoryId,
    required this.ticketID,
    this.raisedFor,
    required this.createdBy,
    required this.createdAt,
    this.assigneeTicket,
    this.createdByUser,
    this.ticketCategory,
    this.ticketSubCategory,
    required this.followers,
  });

  factory TicketDetailsModel.fromJson(Map<String, dynamic> json) {
    // Parse documents
    List<TicketDocumentModel> documents = [];
    if (json['documents'] != null && json['documents'] is List) {
      documents = (json['documents'] as List)
          .map((item) => TicketDocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Parse activity
    List<TicketActivityModel> activity = [];
    if (json['activity'] != null && json['activity'] is List) {
      activity = (json['activity'] as List)
          .map((item) => TicketActivityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Parse followers
    List<TicketFollowerModel> followers = [];
    if (json['followers'] != null && json['followers'] is List) {
      followers = (json['followers'] as List)
          .map((item) => TicketFollowerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return TicketDetailsModel(
      id: (json['id'] as int?) ?? 0,
      subject: json['subject'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      assignee: json['assignee'] as int?,
      description: json['description'] as String? ?? '',
      ticketStatus: json['ticket_status'] as String? ?? '',
      documents: documents,
      activity: activity,
      ticketCategoryId: (json['ticket_category_id'] as int?) ?? 0,
      ticketSubCategoryId: json['ticket_subCategory_id'] as int?,
      ticketID: json['ticketID'] as String? ?? '',
      raisedFor: json['raised_for'] != null
          ? TicketUserModel.fromJson(json['raised_for'] as Map<String, dynamic>)
          : null,
      createdBy: (json['created_by'] as int?) ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      assigneeTicket: json['assigneeTicket'] != null
          ? TicketUserModel.fromJson(json['assigneeTicket'] as Map<String, dynamic>)
          : null,
      createdByUser: json['createdBy'] != null
          ? TicketUserModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      ticketCategory: json['TicketCategory'] != null
          ? TicketCategoryModel.fromJson(json['TicketCategory'] as Map<String, dynamic>)
          : null,
      ticketSubCategory: json['TicketSubCategory'],
      followers: followers,
    );
  }
}

/// Ticket Details API Response
class TicketDetailsApiResponse {
  final bool success;
  final String? message;
  final TicketDetailsModel? data;

  TicketDetailsApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory TicketDetailsApiResponse.fromJson(Map<String, dynamic> json) {
    TicketDetailsModel? detailsData;
    if (json['data'] != null && json['data'] is Map) {
      detailsData = TicketDetailsModel.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    return TicketDetailsApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: detailsData,
    );
  }
}

/// Ticket File Upload Request Model
class TicketFileUploadRequest {
  final int clientId;
  final int ticketId;

  TicketFileUploadRequest({
    required this.clientId,
    required this.ticketId,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'ticket_id': ticketId,
    };
  }
}

/// Ticket File Upload Response Model
class TicketFileUploadResponse {
  final bool success;
  final String? message;
  final TicketStatsModel? data;

  TicketFileUploadResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory TicketFileUploadResponse.fromJson(Map<String, dynamic> json) {
    TicketStatsModel? statsData;
    if (json['data'] != null && json['data'] is Map) {
      statsData = TicketStatsModel.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    return TicketFileUploadResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: statsData,
    );
  }
}
