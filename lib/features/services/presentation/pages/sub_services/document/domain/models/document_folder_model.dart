/// Document folder model
class DocumentFolderModel {
  final String id;
  final String name;
  final int fileCount;
  final String? folderType; // 'shared' or 'employee'
  final String? employeeId;

  const DocumentFolderModel({
    required this.id,
    required this.name,
    required this.fileCount,
    this.folderType,
    this.employeeId,
  });

  /// Create a copy with updated values
  DocumentFolderModel copyWith({
    String? id,
    String? name,
    int? fileCount,
    String? folderType,
    String? employeeId,
  }) {
    return DocumentFolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fileCount: fileCount ?? this.fileCount,
      folderType: folderType ?? this.folderType,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentFolderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
