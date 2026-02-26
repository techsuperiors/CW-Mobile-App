/// Policy model for policies page
class PolicyModel {
  final int id;
  final String name;
  final String assignedBy;
  final String assignedByAvatar;
  final String assignedTo;
  final String assignedToAvatar;
  final String assignedDate;
  final String status;
  final bool isAcknowledged;
  final String? acknowledgedDate; // Optional date if acknowledged
  final String? content; // Policy content text

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
  });
}

