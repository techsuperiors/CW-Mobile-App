class WfhRequestStatsModel {
  final int total;
  final int approved;
  final int rejected;
  final int pending;
  final int withdrawn;

  const WfhRequestStatsModel({
    required this.total,
    required this.approved,
    required this.rejected,
    required this.pending,
    required this.withdrawn,
  });

  factory WfhRequestStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};

    return WfhRequestStatsModel(
      total: _toInt(data['total']),
      approved: _toInt(data['approved']),
      rejected: _toInt(data['rejected']),
      pending: _toInt(data['pending']),
      withdrawn: _toInt(data['withdrawn']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
