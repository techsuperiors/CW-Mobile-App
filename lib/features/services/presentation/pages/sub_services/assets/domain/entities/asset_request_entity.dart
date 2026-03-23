/// Represents a person linked to an asset request (requester, assignee, approver)
class AssetRequestPerson {
  final int id;
  final String firstName;
  final String lastName;
  final String? profileColor;
  final String? imageUrl;

  const AssetRequestPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();
}

/// Represents a document attached to an asset request
class AssetRequestDocument {
  final String id;
  final String url;
  final String name;

  const AssetRequestDocument({
    required this.id,
    required this.url,
    required this.name,
  });
}

/// Represents an activity log entry for an asset request
class AssetRequestActivity {
  final String action;
  final String actionType;
  final String userEmail;
  final String firstName;
  final String lastName;
  final int createdBy;
  final DateTime createdAt;

  const AssetRequestActivity({
    required this.action,
    required this.actionType,
    required this.userEmail,
    required this.firstName,
    required this.lastName,
    required this.createdBy,
    required this.createdAt,
  });
}

/// Asset Request Entity - represents a request made by a user for an asset
class AssetRequestEntity {
  final int id;
  final int clientId;
  final int assetCategoryId;
  final int assetSubCategoryId;
  final int userId;
  final String requestType;
  final String approvalStatus;
  final String requestStatus;
  final String reason;
  final String? remark;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested objects
  final AssetRequestPerson? assetAssignedTo;
  final AssetRequestPerson? requestAssignee;
  final AssetRequestPerson? requestCreatedBy;
  final List<AssetRequestDocument> documents;
  final List<AssetRequestActivity> activity;

  // Category info
  final String categoryName;
  final String subCategoryName;

  const AssetRequestEntity({
    required this.id,
    required this.clientId,
    required this.assetCategoryId,
    required this.assetSubCategoryId,
    required this.userId,
    required this.requestType,
    required this.approvalStatus,
    required this.requestStatus,
    required this.reason,
    this.remark,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assetAssignedTo,
    this.requestAssignee,
    this.requestCreatedBy,
    required this.documents,
    required this.activity,
    required this.categoryName,
    required this.subCategoryName,
  });
}
