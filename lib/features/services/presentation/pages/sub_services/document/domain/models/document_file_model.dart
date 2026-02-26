/// Document file model
class DocumentFileModel {
  final String id;
  final String name;
  final String fileType; // 'pdf', 'doc', 'jpg', etc.
  final String fileSize; // e.g., '208kb', '1.2MB'
  final String date; // e.g., 'Dec 19', 'Jan 05'
  final String? folderId;
  final String? downloadUrl;

  const DocumentFileModel({
    required this.id,
    required this.name,
    required this.fileType,
    required this.fileSize,
    required this.date,
    this.folderId,
    this.downloadUrl,
  });

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
  }) {
    return DocumentFileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      date: date ?? this.date,
      folderId: folderId ?? this.folderId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
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
