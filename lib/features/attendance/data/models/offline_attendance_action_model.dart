import 'dart:convert';

enum OfflineAttendanceActionType { punchIn, punchOut }

extension OfflineAttendanceActionTypeValue on OfflineAttendanceActionType {
  String get value {
    switch (this) {
      case OfflineAttendanceActionType.punchIn:
        return 'punchIn';
      case OfflineAttendanceActionType.punchOut:
        return 'punchOut';
    }
  }

  static OfflineAttendanceActionType fromValue(String value) {
    switch (value) {
      case 'punchOut':
        return OfflineAttendanceActionType.punchOut;
      case 'punchIn':
      default:
        return OfflineAttendanceActionType.punchIn;
    }
  }
}

class OfflineAttendanceActionModel {
  final String id;
  final OfflineAttendanceActionType type;
  final String location;
  final double latitude;
  final double longitude;
  final String? punchType;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final bool needsAddressResolution;
  final int addressResolutionAttempts;

  const OfflineAttendanceActionModel({
    required this.id,
    required this.type,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.punchType,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.needsAddressResolution = false,
    this.addressResolutionAttempts = 0,
  });

  OfflineAttendanceActionModel copyWith({
    String? id,
    OfflineAttendanceActionType? type,
    String? location,
    double? latitude,
    double? longitude,
    String? punchType,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
    bool? needsAddressResolution,
    int? addressResolutionAttempts,
  }) {
    return OfflineAttendanceActionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      punchType: punchType ?? this.punchType,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError,
      needsAddressResolution:
          needsAddressResolution ?? this.needsAddressResolution,
      addressResolutionAttempts:
          addressResolutionAttempts ?? this.addressResolutionAttempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'punchType': punchType,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
      'needsAddressResolution': needsAddressResolution,
      'addressResolutionAttempts': addressResolutionAttempts,
    };
  }

  factory OfflineAttendanceActionModel.fromJson(Map<String, dynamic> json) {
    return OfflineAttendanceActionModel(
      id: json['id']?.toString() ?? '',
      type: OfflineAttendanceActionTypeValue.fromValue(
        json['type']?.toString() ?? 'punchIn',
      ),
      location: json['location']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      punchType: json['punchType']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
      needsAddressResolution: json['needsAddressResolution'] as bool? ?? false,
      addressResolutionAttempts:
          (json['addressResolutionAttempts'] as num?)?.toInt() ?? 0,
    );
  }

  bool isForSameLocalDay(DateTime referenceTime) {
    final localCreatedAt = createdAt.toLocal();
    final localReferenceTime = referenceTime.toLocal();
    return localCreatedAt.year == localReferenceTime.year &&
        localCreatedAt.month == localReferenceTime.month &&
        localCreatedAt.day == localReferenceTime.day;
  }

  static String encodeList(List<OfflineAttendanceActionModel> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  static List<OfflineAttendanceActionModel> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <OfflineAttendanceActionModel>[];
    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              OfflineAttendanceActionModel.fromJson(item.cast<String, dynamic>()),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
