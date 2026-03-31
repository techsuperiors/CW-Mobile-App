import 'package:equatable/equatable.dart';

import '../../../../../../../../core/utils/date_pareser.dart';

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
  final int approvalId;
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;
  final String approvalStatus;

  const ExpenseApproverInfo({
    required this.approvalId,
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
      approvalId: (json['id'] as num?)?.toInt() ?? 0,
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
    approvalId,
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
  final ExpenseRequesterInfo? requestUser;
  final bool canApprove;

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
    this.requestUser,
    this.canApprove = false,
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

    final requestUserJson =
        json['ExpenseReuestUser'] as Map<String, dynamic>? ?? const {};

    return ExpenseItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      expenseName: json['expense_name']?.toString() ?? '',
      expenseType: json['expense_type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      fromDate: parseApiDate(json['from']),
      toDate: parseApiDate(json['to']),
      status: json['status']?.toString() ?? '',
      approvalStatusLabel: json['approval_status']?.toString() ?? 'Pending',
      invoiceNumber: json['invoice_number']?.toString(),
      isEditEnabled: json['is_edit_enable'] as bool? ?? false,
      approvals: approvals,
      requestUser:
          requestUserJson.isEmpty
              ? null
              : ExpenseRequesterInfo.fromJson(requestUserJson),
      canApprove: json['canApprove'] as bool? ?? false,
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
    requestUser,
    canApprove,
  ];
}

class ExpenseRequesterInfo extends Equatable {
  final int id;
  final String employeeId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String? profileColor;
  final String? imageUrl;

  const ExpenseRequesterInfo({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  String get fullName => [firstName, middleName, lastName]
      .where((part) => part.trim().isNotEmpty)
      .join(' ');

  factory ExpenseRequesterInfo.fromJson(Map<String, dynamic> json) {
    return ExpenseRequesterInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      employeeId: json['employeeID']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      profileColor: json['profile_color']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    firstName,
    middleName,
    lastName,
    profileColor,
    imageUrl,
  ];
}
