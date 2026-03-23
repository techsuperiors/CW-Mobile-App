import 'package:intl/intl.dart';

/// Policy model for policies page
class PolicyModel {
  final int id;
  final String name;
  final String assignedBy;
  final String? assignedByAvatar;
  final String assignedTo;
  final String? assignedToAvatar;
  final String assignedDate;
  final String status;
  final bool isAcknowledged;
  final String? acknowledgedDate; // Optional date if acknowledged
  final String? content; // Policy content text
  final bool isFile;
  final String? fileUrl;
  final String? fileName;
  final String? htmlContent;
  final String? coverImage;
  final bool eConsentRequired;
  final String? signatureUrl;
  final int assignedUserId;

  const PolicyModel({
    required this.id,
    required this.name,
    required this.assignedBy,
    required this.assignedByAvatar,
    required this.assignedTo,
    required this.assignedToAvatar,
    required this.assignedDate,
    required this.status,
    required this.isAcknowledged,
    this.acknowledgedDate,
    this.content,
    this.isFile = false,
    this.fileUrl,
    this.fileName,
    this.htmlContent,
    this.coverImage,
    this.eConsentRequired = false,
    this.signatureUrl,
    this.assignedUserId = 0,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    final createdBy = json['CreatedBy'] as Map<String, dynamic>?;
    final assignedUsers = json['AssignedUsers'] as List<dynamic>? ?? const [];
    final assignedUser =
        assignedUsers.isNotEmpty && assignedUsers.first is Map<String, dynamic>
            ? assignedUsers.first as Map<String, dynamic>
            : null;

    final createdAt = _parseDate(json['created_at']);
    final acknowledgedAt = _parseDate(assignedUser?['acknowledged_at']);
    final status = assignedUser?['status'] as String? ?? 'Pending';

    return PolicyModel(
      id: _toInt(json['id']),
      name: json['policy_name'] as String? ?? '',
      assignedBy:
          createdBy?['full_name'] as String? ??
          _buildFullName(createdBy?['first_name'], createdBy?['last_name']),
      assignedByAvatar: createdBy?['image_url'] as String?,
      assignedTo: 'You',
      assignedToAvatar: _extractAssignedUserAvatar(assignedUser),
      assignedDate:
          createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt) : 'N/A',
      status: status,
      isAcknowledged: assignedUser?['acknowledged'] as bool? ?? false,
      acknowledgedDate:
          acknowledgedAt != null
              ? DateFormat('dd/MM/yyyy, hh:mm a').format(acknowledgedAt)
              : null,
      content: (json['description'] as String?)?.trim(),
      isFile: json['is_file'] as bool? ?? false,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      htmlContent: (json['html_content'] as String?)?.trim(),
      coverImage: json['cover_image'] as String?,
      eConsentRequired: assignedUser?['econsent_required'] as bool? ?? false,
      signatureUrl: assignedUser?['signature_url'] as String?,
      assignedUserId: _toInt(assignedUser?['user_id']),
    );
  }
}

String _buildFullName(dynamic firstName, dynamic lastName) {
  final first = (firstName as String? ?? '').trim();
  final last = (lastName as String? ?? '').trim();
  final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
  return fullName.isNotEmpty ? fullName : 'Unknown';
}

String? _extractAssignedUserAvatar(Map<String, dynamic>? assignedUser) {
  final user = assignedUser?['User'] as Map<String, dynamic>?;
  return user?['image_url'] as String?;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
