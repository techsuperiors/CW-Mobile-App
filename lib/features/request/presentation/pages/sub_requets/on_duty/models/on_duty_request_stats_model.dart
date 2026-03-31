class OnDutyRequestStatsModel {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int withdrawn;

  const OnDutyRequestStatsModel({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.withdrawn,
  });

  factory OnDutyRequestStatsModel.fromJson(Map<String, dynamic> json) {
    return OnDutyRequestStatsModel(
      total: _toInt(json['total']),
      pending: _toInt(json['pending']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
      withdrawn: _toInt(json['withdrawn']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
