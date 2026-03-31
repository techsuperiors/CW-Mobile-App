class CompOffRequestStatsModel {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const CompOffRequestStatsModel({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory CompOffRequestStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return CompOffRequestStatsModel(
      total: (data['total'] as num?)?.toInt() ?? 0,
      pending: (data['pending'] as num?)?.toInt() ?? 0,
      approved: (data['approved'] as num?)?.toInt() ?? 0,
      rejected: (data['rejected'] as num?)?.toInt() ?? 0,
    );
  }
}
