import 'package:equatable/equatable.dart';

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
      actionTakenAt: DateTime.tryParse(json['action_taken_at']?.toString() ?? ''),
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

class ExpenseDetailModel extends Equatable {
  final int id;
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
  final String? comments;
  final ExpensePolicyInfo policy;
  final ExpenseRequester requestUser;
  final List<ExpenseDocument> documents;
  final List<ExpenseApprovalDetail> approvals;

  const ExpenseDetailModel({
    required this.id,
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
    required this.policy,
    required this.requestUser,
    required this.documents,
    required this.approvals,
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

    return ExpenseDetailModel(
      id: (data['id'] as num?)?.toInt() ?? 0,
      expenseName: data['expense_name']?.toString() ?? '',
      expenseType: data['expense_type']?.toString() ?? '',
      invoiceNumber: data['invoice_number']?.toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (data['approved_amount'] as num?)?.toDouble() ?? 0,
      fromDate: DateTime.tryParse(data['from']?.toString() ?? '') ?? DateTime.now(),
      toDate: DateTime.tryParse(data['to']?.toString() ?? '') ?? DateTime.now(),
      totalDays: (data['total_days'] as num?)?.toInt() ?? 0,
      description: data['description']?.toString(),
      settlementMode: data['settlement_mode']?.toString(),
      approvalStatus: data['approval_status']?.toString() ?? 'Pending',
      paidDate: DateTime.tryParse(data['paid_date']?.toString() ?? ''),
      actionTakenAt: DateTime.tryParse(data['action_taken_at']?.toString() ?? ''),
      comments: data['comments']?.toString(),
      policy: ExpensePolicyInfo.fromJson(
        data['ExpensePolicy'] as Map<String, dynamic>? ?? const {},
      ),
      requestUser: ExpenseRequester.fromJson(
        data['ExpenseReuestUser'] as Map<String, dynamic>? ?? const {},
      ),
      documents: documents,
      approvals: approvals,
    );
  }

  @override
  List<Object?> get props => [
    id,
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
    policy,
    requestUser,
    documents,
    approvals,
  ];
}
