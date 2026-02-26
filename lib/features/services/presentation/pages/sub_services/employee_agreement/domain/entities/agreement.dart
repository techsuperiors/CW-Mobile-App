/// Agreement User Entity
class AgreementUser {
  final int id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? imageUrl;
  final String? profileColor;

  AgreementUser({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.imageUrl,
    this.profileColor,
  });

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

/// Agreement Entity
class Agreement {
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
  final AgreementUser agreementAssignedTo;
  final AgreementUser agreementAssignedBy;

  Agreement({
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
}

/// Agreement List Entity
class AgreementList {
  final List<Agreement> agreements;

  AgreementList({
    required this.agreements,
  });
}
