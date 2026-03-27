import 'package:intl/intl.dart';

import '../../domain/models/document_file_model.dart';
import '../../domain/models/document_folder_model.dart';

class DocumentDirectoryRemoteModel {
  final int id;
  final String directoryName;
  final String type;
  final dynamic directoryTags;
  final int documentCount;

  const DocumentDirectoryRemoteModel({
    required this.id,
    required this.directoryName,
    required this.type,
    required this.directoryTags,
    required this.documentCount,
  });

  factory DocumentDirectoryRemoteModel.fromJson(Map<String, dynamic> json) {
    return DocumentDirectoryRemoteModel(
      id: _toInt(json['id']),
      directoryName: (json['directory_name'] as String?)?.trim() ?? '',
      type: (json['type'] as String?)?.trim() ?? '',
      directoryTags: json['directory_tags'],
      documentCount: _toInt(json['document_count']),
    );
  }

  DocumentFolderModel toDomain() {
    final isShared = directoryName.toLowerCase() == 'shared';
    return DocumentFolderModel(
      id: id.toString(),
      name: directoryName,
      fileCount: documentCount,
      folderType: isShared ? 'shared' : 'directory',
    );
  }
}

class DocumentDirectoryDetailsRemoteModel {
  final int id;
  final String directoryName;
  final String type;
  final List<DocumentAssetRemoteModel> documents;

  const DocumentDirectoryDetailsRemoteModel({
    required this.id,
    required this.directoryName,
    required this.type,
    required this.documents,
  });

  factory DocumentDirectoryDetailsRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final rawDocuments = data['Documents'] as List<dynamic>? ?? const [];

    return DocumentDirectoryDetailsRemoteModel(
      id: _toInt(data['id']),
      directoryName: (data['directory_name'] as String?)?.trim() ?? '',
      type: (data['type'] as String?)?.trim() ?? '',
      documents: rawDocuments
          .whereType<Map<String, dynamic>>()
          .map(DocumentAssetRemoteModel.fromJson)
          .toList(),
    );
  }
}

class DocumentAssetRemoteModel {
  final String id;
  final String name;
  final String? url;
  final String? fileType;
  final String? fileSize;
  final DateTime? createdAt;

  const DocumentAssetRemoteModel({
    required this.id,
    required this.name,
    required this.url,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  factory DocumentAssetRemoteModel.fromJson(Map<String, dynamic> json) {
    final url = _pickString(json, const [
      'document_url',
      'file_url',
      'download_url',
      'url',
      'signed_url',
      'image_url',
    ]);
    final explicitType = _pickString(json, const [
      'file_type',
      'document_type',
      'mime_type',
      'extension',
      'type',
    ]);

    return DocumentAssetRemoteModel(
      id: (_pickValue(json, const ['id', 'document_id']) ?? '').toString(),
      name: _pickString(json, const [
            'document_name',
            'file_name',
            'name',
            'title',
            'original_name',
          ]) ??
          'Untitled Document',
      url: url,
      fileType: explicitType ?? _extensionFromUrl(url),
      fileSize: _stringifySize(
        _pickValue(json, const ['file_size', 'size', 'document_size']),
      ),
      createdAt: _parseDate(
        _pickValue(json, const [
          'created_at',
          'updated_at',
          'document_date',
          'date',
        ]),
      ),
    );
  }

  DocumentFileModel toDomain(String folderId) {
    final resolvedType = (fileType == null || fileType!.isEmpty)
        ? _extensionFromName(name)
        : fileType!;
    return DocumentFileModel(
      id: id.isEmpty ? name : id,
      name: name,
      fileType: resolvedType.isEmpty ? 'other' : resolvedType,
      fileSize: fileSize ?? '-',
      date: _formatDate(createdAt),
      folderId: folderId,
      downloadUrl: url,
    );
  }
}

class AgreementDocumentRemoteModel {
  final int id;
  final String agreementName;
  final String? agreementContent;
  final String? documentUrl;
  final String? signatureUrl;
  final String agreementStatus;
  final String? category;
  final String? expiryDate;
  final DateTime? sentAt;
  final DateTime? signedAt;
  final String employeeName;
  final String employeeAvatar;
  final String assignedBy;
  final String assignedByAvatar;

  const AgreementDocumentRemoteModel({
    required this.id,
    required this.agreementName,
    required this.agreementContent,
    required this.documentUrl,
    required this.signatureUrl,
    required this.agreementStatus,
    required this.category,
    required this.expiryDate,
    required this.sentAt,
    required this.signedAt,
    required this.employeeName,
    required this.employeeAvatar,
    required this.assignedBy,
    required this.assignedByAvatar,
  });

  factory AgreementDocumentRemoteModel.fromJson(Map<String, dynamic> json) {
    final assignedTo =
        json['AgreementAssignedTo'] as Map<String, dynamic>? ?? const {};
    final assignedBy =
        json['AgreementAssignedBy'] as Map<String, dynamic>? ?? const {};

    return AgreementDocumentRemoteModel(
      id: _toInt(json['id']),
      agreementName: (json['agreement_name'] as String?)?.trim().isNotEmpty ==
              true
          ? (json['agreement_name'] as String).trim()
          : 'Untitled Agreement',
      agreementContent: json['agreement_content'] as String?,
      documentUrl: json['document_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      agreementStatus: (json['agreement_status'] as String?)?.trim() ?? '-',
      category: json['category'] as String?,
      expiryDate: json['expiry_date'] as String?,
      sentAt: _parseDate(json['sent_at']),
      signedAt: _parseDate(json['signed_at']),
      employeeName: _fullName(assignedTo),
      employeeAvatar: (assignedTo['image_url'] as String?) ?? '',
      assignedBy: _fullName(assignedBy),
      assignedByAvatar: (assignedBy['image_url'] as String?) ?? '',
    );
  }

  DocumentFileModel toDomain(String folderId) {
    final effectiveUrl =
        (documentUrl != null && documentUrl!.isNotEmpty) ? documentUrl : null;
    final effectiveType = effectiveUrl != null
        ? _extensionFromUrl(effectiveUrl)
        : (agreementContent != null && agreementContent!.isNotEmpty
              ? 'html'
              : 'other');

    return DocumentFileModel(
      id: id.toString(),
      name: agreementName,
      fileType: effectiveType.isEmpty ? 'other' : effectiveType,
      fileSize: category?.isNotEmpty == true ? category! : agreementStatus,
      date: _formatDate(signedAt ?? sentAt),
      folderId: folderId,
      downloadUrl: effectiveUrl,
      agreementId: id,
      agreementContent: agreementContent,
      agreementSignatureUrl: signatureUrl,
      agreementStatus: agreementStatus,
      agreementEmployeeName: employeeName,
      agreementEmployeeAvatar: employeeAvatar,
      agreementType: category,
      agreementAssignedBy: assignedBy,
      agreementAssignedByAvatar: assignedByAvatar,
      agreementExpiryDate: _formatExpiryDate(expiryDate),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

dynamic _pickValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}

String? _pickString(Map<String, dynamic> json, List<String> keys) {
  final value = _pickValue(json, keys);
  final stringValue = value?.toString().trim();
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return DateFormat('dd MMM yyyy').format(value);
}

String? _stringifySize(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}

String _extensionFromUrl(String? url) {
  if (url == null || url.isEmpty) {
    return '';
  }
  final sanitized = url.split('?').first;
  final dotIndex = sanitized.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == sanitized.length - 1) {
    return '';
  }
  return sanitized.substring(dotIndex + 1).toLowerCase();
}

String _extensionFromName(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}

String _fullName(Map<String, dynamic> json) {
  final first = (json['first_name'] as String?)?.trim() ?? '';
  final last = (json['last_name'] as String?)?.trim() ?? '';
  final fullName = '$first $last'.trim();
  return fullName.isEmpty ? 'N/A' : fullName;
}

String _formatExpiryDate(String? value) {
  if (value == null || value.isEmpty) {
    return 'N/A';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}
