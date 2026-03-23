import '../../domain/entities/asset_request_entity.dart';

/// Data model extending AssetRequestEntity with JSON parsing
class AssetRequestPersonModel extends AssetRequestPerson {
  const AssetRequestPersonModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.profileColor,
    super.imageUrl,
  });

  factory AssetRequestPersonModel.fromJson(Map<String, dynamic> json) {
    return AssetRequestPersonModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileColor: json['profile_color'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class AssetRequestDocumentModel extends AssetRequestDocument {
  const AssetRequestDocumentModel({
    required super.id,
    required super.url,
    required super.name,
  });

  factory AssetRequestDocumentModel.fromJson(Map<String, dynamic> json) {
    return AssetRequestDocumentModel(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AssetRequestActivityModel extends AssetRequestActivity {
  const AssetRequestActivityModel({
    required super.action,
    required super.actionType,
    required super.userEmail,
    required super.firstName,
    required super.lastName,
    required super.createdBy,
    required super.createdAt,
  });

  factory AssetRequestActivityModel.fromJson(Map<String, dynamic> json) {
    return AssetRequestActivityModel(
      action: json['action'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      createdBy: json['created_by'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Data Model for an Asset Request parsed from the API response
class AssetRequestModel extends AssetRequestEntity {
  const AssetRequestModel({
    required super.id,
    required super.clientId,
    required super.assetCategoryId,
    required super.assetSubCategoryId,
    required super.userId,
    required super.requestType,
    required super.approvalStatus,
    required super.requestStatus,
    required super.reason,
    super.remark,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.assetAssignedTo,
    super.requestAssignee,
    super.requestCreatedBy,
    required super.documents,
    required super.activity,
    required super.categoryName,
    required super.subCategoryName,
  });

  factory AssetRequestModel.fromJson(Map<String, dynamic> json) {
    // Parse nested objects
    final assetAssignedToJson =
        json['assetAssignedTo'] as Map<String, dynamic>?;
    final requestAssigneeJson =
        json['requestAssignee'] as Map<String, dynamic>?;
    final requestCreatedByJson =
        json['requestCreatedBy'] as Map<String, dynamic>?;

    // Parse category & sub-category
    final categoryJson = json['AssetCategory'] as Map<String, dynamic>?;
    final subCategoryJson = json['AssetSubCategory'] as Map<String, dynamic>?;

    // Parse documents list
    final documentsList =
        (json['documents'] as List<dynamic>? ?? [])
            .map(
              (d) =>
                  AssetRequestDocumentModel.fromJson(d as Map<String, dynamic>),
            )
            .toList();

    // Parse activity list
    final activityList =
        (json['activity'] as List<dynamic>? ?? [])
            .map(
              (a) =>
                  AssetRequestActivityModel.fromJson(a as Map<String, dynamic>),
            )
            .toList();

    return AssetRequestModel(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      assetCategoryId: json['asset_category_id'] as int? ?? 0,
      assetSubCategoryId: json['asset_subCategory_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      requestType: json['request_type'] as String? ?? '',
      approvalStatus: json['approval_status'] as String? ?? '',
      requestStatus: json['request_status'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      remark: json['remark'] as String?,
      status: json['status'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      assetAssignedTo:
          assetAssignedToJson != null
              ? AssetRequestPersonModel.fromJson(assetAssignedToJson)
              : null,
      requestAssignee:
          requestAssigneeJson != null
              ? AssetRequestPersonModel.fromJson(requestAssigneeJson)
              : null,
      requestCreatedBy:
          requestCreatedByJson != null
              ? AssetRequestPersonModel.fromJson(requestCreatedByJson)
              : null,
      documents: documentsList,
      activity: activityList,
      categoryName: categoryJson?['category_name'] as String? ?? '',
      subCategoryName: subCategoryJson?['subCategory_name'] as String? ?? '',
    );
  }
}
