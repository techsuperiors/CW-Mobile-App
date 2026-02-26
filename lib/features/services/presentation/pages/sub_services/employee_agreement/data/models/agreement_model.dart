/// Agreement Assigned To/By User Model
class AgreementUserModel {
  final int id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? imageUrl;
  final String? profileColor;

  AgreementUserModel({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  factory AgreementUserModel.fromJson(Map<String, dynamic> json) {
    return AgreementUserModel(
      id: (json['id'] as int?) ?? 0,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
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
    return parts.isEmpty ? email ?? 'User' : parts.join(' ');
  }
}

/// Agreement Model based on API response
class AgreementModel {
  final int id;
  final int clientId;
  final int userId;
  final String category;
  final String agreementName;
  final int? documentId;
  final String agreementContent;
  final bool signatureRequired;
  final bool acknowledgementRequired;
  final bool agreementAcknowledged;
  final String? expiryDate;
  final String? signatureUrl;
  final String? documentUrl;
  final String agreementStatus;
  final String status;
  final String? sentAt;
  final String? signedAt;
  final String? createdAt;
  final int? createdBy;
  final String? updatedAt;
  final int? updatedBy;
  final AgreementUserModel agreementAssignedTo;
  final AgreementUserModel agreementAssignedBy;

  AgreementModel({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.category,
    required this.agreementName,
    this.documentId,
    required this.agreementContent,
    required this.signatureRequired,
    required this.acknowledgementRequired,
    required this.agreementAcknowledged,
    this.expiryDate,
    this.signatureUrl,
    this.documentUrl,
    required this.agreementStatus,
    required this.status,
    this.sentAt,
    this.signedAt,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.agreementAssignedTo,
    required this.agreementAssignedBy,
  });

  factory AgreementModel.fromJson(Map<String, dynamic> json) {
    return AgreementModel(
      id: (json['id'] as int?) ?? 0,
      clientId: (json['client_id'] as int?) ?? 0,
      userId: (json['user_id'] as int?) ?? 0,
      category: json['category'] as String? ?? '',
      agreementName: json['agreement_name'] as String? ?? '',
      documentId: json['document_id'] as int?,
      agreementContent: json['agreement_content'] as String? ?? '',
      signatureRequired: json['signature_required'] as bool? ?? false,
      acknowledgementRequired: json['acknowledgement_required'] as bool? ?? false,
      agreementAcknowledged: json['agreement_acknowledged'] as bool? ?? false,
      expiryDate: json['expiry_date'] as String?,
      signatureUrl: json['signature_url'] as String?,
      documentUrl: json['document_url'] as String?,
      agreementStatus: json['agreement_status'] as String? ?? '',
      status: json['status'] as String? ?? '',
      sentAt: json['sent_at'] as String?,
      signedAt: json['signed_at'] as String?,
      createdAt: json['created_at'] as String?,
      createdBy: json['created_by'] as int?,
      updatedAt: json['updated_at'] as String?,
      updatedBy: json['updated_by'] as int?,
      agreementAssignedTo: AgreementUserModel.fromJson(
        json['AgreementAssignedTo'] as Map<String, dynamic>,
      ),
      agreementAssignedBy: AgreementUserModel.fromJson(
        json['AgreementAssignedBy'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Agreement List API Response
class AgreementListApiResponse {
  final bool success;
  final String? message;
  final List<AgreementModel>? data;

  AgreementListApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AgreementListApiResponse.fromJson(Map<String, dynamic> json) {
    List<AgreementModel> agreements = [];
    if (json['data'] != null && json['data'] is List) {
      agreements = (json['data'] as List)
          .map((item) => AgreementModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return AgreementListApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: agreements,
    );
  }
}

/// Agreement Consent Request Model
class AgreementConsentRequest {
  final int agreementId;
  final bool agreementAcknowledged;

  AgreementConsentRequest({
    required this.agreementId,
    required this.agreementAcknowledged,
  });

  Map<String, dynamic> toJson() {
    return {
      'agreement_id': agreementId,
      'agreement_acknowledged': agreementAcknowledged,
    };
  }
}

/// Agreement Consent API Response
class AgreementConsentResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  AgreementConsentResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AgreementConsentResponse.fromJson(Map<String, dynamic> json) {
    return AgreementConsentResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}