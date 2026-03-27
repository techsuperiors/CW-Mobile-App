/// Document file model
class DocumentFileModel {
  final String id;
  final String name;
  final String fileType; // 'pdf', 'doc', 'jpg', etc.
  final String fileSize; // e.g., '208kb', '1.2MB'
  final String date; // e.g., 'Dec 19', 'Jan 05'
  final String? folderId;
  final String? downloadUrl;
  final int? agreementId;
  final String? agreementContent;
  final String? agreementSignatureUrl;
  final String? agreementStatus;
  final String? agreementEmployeeName;
  final String? agreementEmployeeAvatar;
  final String? agreementType;
  final String? agreementAssignedBy;
  final String? agreementAssignedByAvatar;
  final String? agreementExpiryDate;

  const DocumentFileModel({
    required this.id,
    required this.name,
    required this.fileType,
    required this.fileSize,
    required this.date,
    this.folderId,
    this.downloadUrl,
    this.agreementId,
    this.agreementContent,
    this.agreementSignatureUrl,
    this.agreementStatus,
    this.agreementEmployeeName,
    this.agreementEmployeeAvatar,
    this.agreementType,
    this.agreementAssignedBy,
    this.agreementAssignedByAvatar,
    this.agreementExpiryDate,
  });

  bool get isAgreementItem => agreementId != null;
  bool get hasPreviewUrl => downloadUrl != null && downloadUrl!.isNotEmpty;
  bool get isPdfType => fileType.toLowerCase() == 'pdf';
  bool get isImageType => fileTypeCategory == 'image';

  /// Get file type category for filtering
  String get fileTypeCategory {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'document';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image';
      default:
        return 'other';
    }
  }

  /// Create a copy with updated values
  DocumentFileModel copyWith({
    String? id,
    String? name,
    String? fileType,
    String? fileSize,
    String? date,
    String? folderId,
    String? downloadUrl,
    int? agreementId,
    String? agreementContent,
    String? agreementSignatureUrl,
    String? agreementStatus,
    String? agreementEmployeeName,
    String? agreementEmployeeAvatar,
    String? agreementType,
    String? agreementAssignedBy,
    String? agreementAssignedByAvatar,
    String? agreementExpiryDate,
  }) {
    return DocumentFileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      date: date ?? this.date,
      folderId: folderId ?? this.folderId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      agreementId: agreementId ?? this.agreementId,
      agreementContent: agreementContent ?? this.agreementContent,
      agreementSignatureUrl:
          agreementSignatureUrl ?? this.agreementSignatureUrl,
      agreementStatus: agreementStatus ?? this.agreementStatus,
      agreementEmployeeName:
          agreementEmployeeName ?? this.agreementEmployeeName,
      agreementEmployeeAvatar:
          agreementEmployeeAvatar ?? this.agreementEmployeeAvatar,
      agreementType: agreementType ?? this.agreementType,
      agreementAssignedBy: agreementAssignedBy ?? this.agreementAssignedBy,
      agreementAssignedByAvatar:
          agreementAssignedByAvatar ?? this.agreementAssignedByAvatar,
      agreementExpiryDate: agreementExpiryDate ?? this.agreementExpiryDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentFileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
