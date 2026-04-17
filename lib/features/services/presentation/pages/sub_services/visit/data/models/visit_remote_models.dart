import 'package:intl/intl.dart';

import '../../domain/models/visit_model.dart';

class VisitUserRemoteModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const VisitUserRemoteModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  factory VisitUserRemoteModel.fromJson(Map<String, dynamic> json) {
    return VisitUserRemoteModel(
      id: _parseInt(json['id']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      imageUrl: _nullableString(json['image_url']),
      profileColor: _nullableString(json['profile_color']),
    );
  }

  VisitUserModel toDomain() {
    return VisitUserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      imageUrl: imageUrl,
      profileColor: profileColor,
    );
  }
}

class VisitParticipantRemoteModel {
  final int id;
  final int userId;
  final String visitStatus;
  final VisitUserRemoteModel user;

  const VisitParticipantRemoteModel({
    required this.id,
    required this.userId,
    required this.visitStatus,
    required this.user,
  });

  factory VisitParticipantRemoteModel.fromJson(Map<String, dynamic> json) {
    final userJson =
        json['VisitParticipants'] is Map<String, dynamic>
            ? json['VisitParticipants'] as Map<String, dynamic>
            : <String, dynamic>{};

    return VisitParticipantRemoteModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      visitStatus: _asString(json['visit_status']),
      user: VisitUserRemoteModel.fromJson(userJson),
    );
  }

  VisitParticipantModel toDomain() {
    return VisitParticipantModel(
      id: id,
      userId: userId,
      visitStatus: visitStatus,
      user: user.toDomain(),
    );
  }
}

class VisitRemoteModel {
  final int id;
  final String visitType;
  final String visitTitle;
  final String? description;
  final DateTime? scheduledDate;
  final String? startTime;
  final String? endTime;
  final String visitStatus;
  final DateTime? createdAt;
  final VisitUserRemoteModel createdBy;
  final List<VisitParticipantRemoteModel> participants;

  const VisitRemoteModel({
    required this.id,
    required this.visitType,
    required this.visitTitle,
    this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    required this.visitStatus,
    required this.createdAt,
    required this.createdBy,
    required this.participants,
  });

  factory VisitRemoteModel.fromJson(Map<String, dynamic> json) {
    final createdByJson =
        json['VisitCreatedBy'] is Map<String, dynamic>
            ? json['VisitCreatedBy'] as Map<String, dynamic>
            : <String, dynamic>{};

    final participantsJson = (json['VisitParticipants'] as List<dynamic>? ??
            const [])
        .whereType<Map<String, dynamic>>()
        .map(VisitParticipantRemoteModel.fromJson)
        .toList(growable: false);

    return VisitRemoteModel(
      id: _parseInt(json['id']),
      visitType: _asString(json['visit_type']),
      visitTitle: _asString(json['visit_title']),
      description: _nullableString(json['description']),
      scheduledDate: _parseDate(json['scheduled_date']),
      startTime: _normalizeTime(json['start_time']),
      endTime: _normalizeTime(json['end_time']),
      visitStatus: _asString(json['visit_status']),
      createdAt: _parseDateTime(json['created_at']),
      createdBy: VisitUserRemoteModel.fromJson(createdByJson),
      participants: participantsJson,
    );
  }

  VisitModel toDomain() {
    return VisitModel(
      id: id,
      type: VisitType.fromValue(visitType),
      visitTitle: visitTitle,
      description: description,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      status: VisitStatus.fromValue(visitStatus),
      createdAt: createdAt,
      createdBy: createdBy.toDomain(),
      participants: participants
          .map((participant) => participant.toDomain())
          .toList(growable: false),
    );
  }
}

class VisitEmployeeRemoteModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? employeeId;
  final String? profileColor;
  final String? imageUrl;
  final String? department;
  final String? designation;

  const VisitEmployeeRemoteModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.employeeId,
    this.profileColor,
    this.imageUrl,
    this.department,
    this.designation,
  });

  factory VisitEmployeeRemoteModel.fromJson(Map<String, dynamic> json) {
    return VisitEmployeeRemoteModel(
      id: _parseInt(json['id']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      email: _asString(json['email']),
      employeeId: _nullableString(json['employeeID']),
      profileColor: _nullableString(json['profile_color']),
      imageUrl: _nullableString(json['image_url']),
      department: _nullableString(json['department']),
      designation: _nullableString(json['designation']),
    );
  }

  VisitEmployeeModel toDomain() {
    return VisitEmployeeModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      employeeId: employeeId,
      profileColor: profileColor,
      imageUrl: imageUrl,
      department: department,
      designation: designation,
    );
  }
}

class VisitCustomerRemoteModel {
  final int id;
  final String customerName;
  final String businessDomain;
  final String customerType;
  final String customerCode;
  final String status;

  const VisitCustomerRemoteModel({
    required this.id,
    required this.customerName,
    required this.businessDomain,
    required this.customerType,
    required this.customerCode,
    required this.status,
  });

  factory VisitCustomerRemoteModel.fromJson(Map<String, dynamic> json) {
    return VisitCustomerRemoteModel(
      id: _parseInt(json['id']),
      customerName: _asString(json['customer_name']),
      businessDomain: _asString(json['business_domian']),
      customerType: _asString(json['customer_type']),
      customerCode: _asString(json['customer_code']),
      status: _asString(json['status']),
    );
  }

  VisitCustomerModel toDomain() {
    return VisitCustomerModel(
      id: id,
      customerName: customerName,
      businessDomain: businessDomain,
      customerType: customerType,
      customerCode: customerCode,
      status: status,
    );
  }
}

class VisitAddressRemoteModel {
  final int id;
  final String addressName;
  final String addressType;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final String? latitude;
  final String? longitude;

  const VisitAddressRemoteModel({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.pincode,
    required this.city,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
  });

  factory VisitAddressRemoteModel.fromJson(Map<String, dynamic> json) {
    return VisitAddressRemoteModel(
      id: _parseInt(json['id']),
      addressName: _asString(json['address_name']),
      addressType: _asString(json['address_type']),
      pincode: _asString(json['pincode']),
      city: _asString(json['city']),
      state: _asString(json['state']),
      country: _asString(json['country']),
      latitude: _nullableString(json['latitude']),
      longitude: _nullableString(json['longitude']),
    );
  }

  VisitAddressModel toDomain() {
    return VisitAddressModel(
      id: id,
      addressName: addressName,
      addressType: addressType,
      pincode: pincode,
      city: city,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  return value.toString().trim();
}

String? _nullableString(dynamic value) {
  final normalized = _asString(value);
  return normalized.isEmpty ? null : normalized;
}

DateTime? _parseDate(dynamic value) {
  final raw = _nullableString(value);
  if (raw == null) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}

DateTime? _parseDateTime(dynamic value) {
  final raw = _nullableString(value);
  if (raw == null) return null;
  try {
    return DateTime.parse(raw).toLocal();
  } catch (_) {
    return null;
  }
}

String? _normalizeTime(dynamic value) {
  final raw = _nullableString(value);
  if (raw == null) return null;

  final rawTimeMatch = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
  if (rawTimeMatch.hasMatch(raw)) {
    try {
      final parsed = DateFormat(
        raw.length == 5 ? 'HH:mm' : 'HH:mm:ss',
      ).parse(raw);
      return DateFormat('hh:mm a').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  try {
    return DateFormat('hh:mm a').format(DateTime.parse(raw).toLocal());
  } catch (_) {
    return raw;
  }
}
