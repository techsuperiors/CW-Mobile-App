import 'wfh_request_model.dart';

class WfhRequestsPageModel {
  final List<WfhRequestModel> requests;
  final int total;
  final int pendingCount;

  const WfhRequestsPageModel({
    required this.requests,
    required this.total,
    required this.pendingCount,
  });

  factory WfhRequestsPageModel.fromJson(Map<String, dynamic> json) {
    final requestsList = json['data'] as List<dynamic>? ?? const [];

    return WfhRequestsPageModel(
      requests:
          requestsList
              .whereType<Map>()
              .map(
                (item) => WfhRequestModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
      total: _toInt(json['total']),
      pendingCount: _toInt(json['workFromHomeRequestPendingList']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
