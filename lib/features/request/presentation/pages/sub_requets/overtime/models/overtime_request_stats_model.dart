class OvertimeRequestStatsModel {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int withdrawn;

  const OvertimeRequestStatsModel({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.withdrawn,
  });

  factory OvertimeRequestStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return OvertimeRequestStatsModel(
      total: (data['total'] as num?)?.toInt() ?? 0,
      pending: (data['pending'] as num?)?.toInt() ?? 0,
      approved: (data['approved'] as num?)?.toInt() ?? 0,
      rejected: (data['rejected'] as num?)?.toInt() ?? 0,
      withdrawn: (data['withdrawn'] as num?)?.toInt() ?? 0,
    );
  }
}
