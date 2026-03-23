import 'package:equatable/equatable.dart';

enum ExpenseApprovalStatus {
  pending,
  approved,
  rejected,
  withdrawn,
  unknown;

  static ExpenseApprovalStatus fromValue(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'pending':
        return ExpenseApprovalStatus.pending;
      case 'approved':
        return ExpenseApprovalStatus.approved;
      case 'rejected':
        return ExpenseApprovalStatus.rejected;
      case 'withdrawn':
        return ExpenseApprovalStatus.withdrawn;
      default:
        return ExpenseApprovalStatus.unknown;
    }
  }
}

class ExpenseApproverInfo extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;
  final String approvalStatus;

  const ExpenseApproverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
    required this.approvalStatus,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ExpenseApproverInfo.fromJson(Map<String, dynamic> json) {
    final assignee =
        json['ExpenseRequestAssignee'] as Map<String, dynamic>? ?? const {};
    return ExpenseApproverInfo(
      id: (assignee['id'] as num?)?.toInt() ?? 0,
      firstName: assignee['first_name']?.toString() ?? '',
      lastName: assignee['last_name']?.toString() ?? '',
      imageUrl: assignee['image_url']?.toString(),
      profileColor: assignee['profile_color']?.toString(),
      approvalStatus: json['approval_status']?.toString() ?? 'Pending',
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    imageUrl,
    profileColor,
    approvalStatus,
  ];
}

class ExpenseItemModel extends Equatable {
  final int id;
  final String expenseName;
  final String expenseType;
  final double amount;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final String approvalStatusLabel;
  final String? invoiceNumber;
  final bool isEditEnabled;
  final List<ExpenseApproverInfo> approvals;

  const ExpenseItemModel({
    required this.id,
    required this.expenseName,
    required this.expenseType,
    required this.amount,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.approvalStatusLabel,
    required this.invoiceNumber,
    required this.isEditEnabled,
    required this.approvals,
  });

  ExpenseApprovalStatus get approvalStatus =>
      ExpenseApprovalStatus.fromValue(approvalStatusLabel);

  int get durationDays {
    final difference = toDate.difference(fromDate).inDays + 1;
    return difference < 1 ? 1 : difference;
  }

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    final approvals =
        (json['all_approvals'] as List<dynamic>? ??
                json['ExpenseApprovals'] as List<dynamic>? ??
                const [])
            .whereType<Map<String, dynamic>>()
            .map(ExpenseApproverInfo.fromJson)
            .toList();

    return ExpenseItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      expenseName: json['expense_name']?.toString() ?? '',
      expenseType: json['expense_type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      fromDate: DateTime.tryParse(json['from']?.toString() ?? '') ?? DateTime.now(),
      toDate: DateTime.tryParse(json['to']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? '',
      approvalStatusLabel: json['approval_status']?.toString() ?? 'Pending',
      invoiceNumber: json['invoice_number']?.toString(),
      isEditEnabled: json['is_edit_enable'] as bool? ?? false,
      approvals: approvals,
    );
  }

  @override
  List<Object?> get props => [
    id,
    expenseName,
    expenseType,
    amount,
    fromDate,
    toDate,
    status,
    approvalStatusLabel,
    invoiceNumber,
    isEditEnabled,
    approvals,
  ];
}
