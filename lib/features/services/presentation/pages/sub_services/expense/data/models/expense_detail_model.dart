import 'package:equatable/equatable.dart';

import '../../../../../../../../core/utils/date_pareser.dart';

class ExpenseDocument extends Equatable {
  final String id;
  final String url;
  final String name;

  const ExpenseDocument({
    required this.id,
    required this.url,
    required this.name,
  });

  factory ExpenseDocument.fromJson(Map<String, dynamic> json) {
    return ExpenseDocument(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, url, name];
}

class ExpenseRequester extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const ExpenseRequester({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ExpenseRequester.fromJson(Map<String, dynamic> json) {
    return ExpenseRequester(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      profileColor: json['profile_color']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, profileColor];
}

class ExpensePolicyInfo extends Equatable {
  final int id;
  final String policyName;
  final String currency;

  const ExpensePolicyInfo({
    required this.id,
    required this.policyName,
    required this.currency,
  });

  factory ExpensePolicyInfo.fromJson(Map<String, dynamic> json) {
    return ExpensePolicyInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      policyName: json['policy_name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  @override
  List<Object?> get props => [id, policyName, currency];
}

class ExpenseApprovalDetail extends Equatable {
  final int id;
  final String approvalStatus;
  final bool isFinalApproval;
  final bool approvalMandatory;
  final String? remarks;
  final double? approvedAmount;
  final DateTime? actionTakenAt;
  final ExpenseRequester assignee;

  const ExpenseApprovalDetail({
    required this.id,
    required this.approvalStatus,
    required this.isFinalApproval,
    required this.approvalMandatory,
    required this.remarks,
    required this.approvedAmount,
    required this.actionTakenAt,
    required this.assignee,
  });

  factory ExpenseApprovalDetail.fromJson(Map<String, dynamic> json) {
    return ExpenseApprovalDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      approvalStatus: json['approval_status']?.toString() ?? 'Pending',
      isFinalApproval: json['is_final_approval'] as bool? ?? false,
      approvalMandatory: json['approval_mandatory'] as bool? ?? false,
      remarks: json['remarks']?.toString(),
      approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
      actionTakenAt: parseApiDateNullable(json['action_taken_at']),
      assignee: ExpenseRequester.fromJson(
        json['ExpenseRequestAssignee'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    approvalStatus,
    isFinalApproval,
    approvalMandatory,
    remarks,
    approvedAmount,
    actionTakenAt,
    assignee,
  ];
}

class ExpenseComment extends Equatable {
  final String id;
  final String comment;
  final DateTime? createdAt;
  final ExpenseRequester createdBy;

  const ExpenseComment({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.createdBy,
  });

  factory ExpenseComment.fromJson(Map<String, dynamic> json) {
    return ExpenseComment(
      id: json['id']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      createdAt: parseApiDateNullable(json['created_at']),
      createdBy: ExpenseRequester.fromJson(
        json['commentCreatedBy'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toPayloadJson() {
    return {
      'id': id,
      'comment': comment,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'commentCreatedBy': {
        'id': createdBy.id,
        'first_name': createdBy.firstName,
        'last_name': createdBy.lastName,
        'image_url': createdBy.imageUrl,
        'profile_color': createdBy.profileColor,
      },
    };
  }

  @override
  List<Object?> get props => [id, comment, createdAt, createdBy];
}

class ExpenseActivity extends Equatable {
  final String action;
  final String actionType;
  final String firstName;
  final String lastName;
  final DateTime? createdAt;

  const ExpenseActivity({
    required this.action,
    required this.actionType,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
  });

  factory ExpenseActivity.fromJson(Map<String, dynamic> json) {
    return ExpenseActivity(
      action: json['action']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      createdAt: parseApiDateNullable(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [action, actionType, firstName, lastName, createdAt];
}

class ExpenseDetailModel extends Equatable {
  final int id;
  final int expensePolicyId;
  final int? tripId;
  final String? tripType;
  final String expenseName;
  final String expenseType;
  final String? invoiceNumber;
  final double amount;
  final double approvedAmount;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final String? description;
  final String? settlementMode;
  final String approvalStatus;
  final DateTime? paidDate;
  final DateTime? actionTakenAt;
  final List<ExpenseComment> comments;
  final List<ExpenseActivity> activity;
  final ExpensePolicyInfo policy;
  final ExpenseRequester requestUser;
  final List<ExpenseDocument> documents;
  final List<ExpenseApprovalDetail> approvals;
  final bool canApprove;

  const ExpenseDetailModel({
    required this.id,
    required this.expensePolicyId,
    required this.tripId,
    required this.tripType,
    required this.expenseName,
    required this.expenseType,
    required this.invoiceNumber,
    required this.amount,
    required this.approvedAmount,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.description,
    required this.settlementMode,
    required this.approvalStatus,
    required this.paidDate,
    required this.actionTakenAt,
    required this.comments,
    required this.activity,
    required this.policy,
    required this.requestUser,
    required this.documents,
    required this.approvals,
    this.canApprove = false,
  });

  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final documents =
        (data['documents'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ExpenseDocument.fromJson)
            .toList();
    final approvals =
        (data['ExpenseApprovals'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ExpenseApprovalDetail.fromJson)
            .toList();
    final comments =
        (data['comments'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ExpenseComment.fromJson)
            .toList();
    final activity =
        (data['activity'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ExpenseActivity.fromJson)
            .toList();

    return ExpenseDetailModel(
      id: (data['id'] as num?)?.toInt() ?? 0,
      expensePolicyId: (data['expense_policy_id'] as num?)?.toInt() ?? 0,
      tripId: (data['trip_id'] as num?)?.toInt(),
      tripType: data['trip_type']?.toString(),
      expenseName: data['expense_name']?.toString() ?? '',
      expenseType: data['expense_type']?.toString() ?? '',
      invoiceNumber: data['invoice_number']?.toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (data['approved_amount'] as num?)?.toDouble() ?? 0,
      fromDate: parseApiDate(data['from']),
      toDate: parseApiDate(data['to']),
      totalDays: (data['total_days'] as num?)?.toInt() ?? 0,
      description: data['description']?.toString(),
      settlementMode: data['settlement_mode']?.toString(),
      approvalStatus: data['approval_status']?.toString() ?? 'Pending',
      paidDate: parseApiDateNullable(data['paid_date']),
      actionTakenAt: parseApiDateNullable(data['action_taken_at']),
      comments: comments,
      activity: activity,
      policy: ExpensePolicyInfo.fromJson(
        data['ExpensePolicy'] as Map<String, dynamic>? ?? const {},
      ),
      requestUser: ExpenseRequester.fromJson(
        data['ExpenseReuestUser'] as Map<String, dynamic>? ?? const {},
      ),
      documents: documents,
      approvals: approvals,
      canApprove: data['canApprove'] as bool? ?? false,
    );
  }

  ExpenseDetailModel copyWith({
    int? id,
    int? expensePolicyId,
    int? tripId,
    String? tripType,
    String? expenseName,
    String? expenseType,
    String? invoiceNumber,
    double? amount,
    double? approvedAmount,
    DateTime? fromDate,
    DateTime? toDate,
    int? totalDays,
    String? description,
    String? settlementMode,
    String? approvalStatus,
    DateTime? paidDate,
    DateTime? actionTakenAt,
    List<ExpenseComment>? comments,
    List<ExpenseActivity>? activity,
    ExpensePolicyInfo? policy,
    ExpenseRequester? requestUser,
    List<ExpenseDocument>? documents,
    List<ExpenseApprovalDetail>? approvals,
    bool? canApprove,
  }) {
    return ExpenseDetailModel(
      id: id ?? this.id,
      expensePolicyId: expensePolicyId ?? this.expensePolicyId,
      tripId: tripId ?? this.tripId,
      tripType: tripType ?? this.tripType,
      expenseName: expenseName ?? this.expenseName,
      expenseType: expenseType ?? this.expenseType,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      totalDays: totalDays ?? this.totalDays,
      description: description ?? this.description,
      settlementMode: settlementMode ?? this.settlementMode,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      paidDate: paidDate ?? this.paidDate,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      comments: comments ?? this.comments,
      activity: activity ?? this.activity,
      policy: policy ?? this.policy,
      requestUser: requestUser ?? this.requestUser,
      documents: documents ?? this.documents,
      approvals: approvals ?? this.approvals,
      canApprove: canApprove ?? this.canApprove,
    );
  }

  @override
  List<Object?> get props => [
    id,
    expensePolicyId,
    tripId,
    tripType,
    expenseName,
    expenseType,
    invoiceNumber,
    amount,
    approvedAmount,
    fromDate,
    toDate,
    totalDays,
    description,
    settlementMode,
    approvalStatus,
    paidDate,
    actionTakenAt,
    comments,
    activity,
    policy,
    requestUser,
    documents,
    approvals,
    canApprove,
  ];
}
