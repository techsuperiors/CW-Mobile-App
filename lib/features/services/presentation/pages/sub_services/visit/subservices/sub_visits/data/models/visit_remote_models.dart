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

class VisitActivityCustomerSummaryRemoteModel {
  final int id;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String businessDomain;

  const VisitActivityCustomerSummaryRemoteModel({
    required this.id,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.businessDomain,
  });

  factory VisitActivityCustomerSummaryRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VisitActivityCustomerSummaryRemoteModel(
      id: _parseInt(json['id']),
      customerName: _asString(json['customer_name']),
      customerCode: _asString(json['customer_code']),
      customerType: _asString(json['customer_type']),
      businessDomain: _asString(json['business_domian']),
    );
  }

  VisitActivityCustomerSummaryModel toDomain() {
    return VisitActivityCustomerSummaryModel(
      id: id,
      customerName: customerName,
      customerCode: customerCode,
      customerType: customerType,
      businessDomain: businessDomain,
    );
  }
}

class VisitActivityAddressSummaryRemoteModel {
  final int id;
  final String addressName;
  final String addressType;
  final String city;
  final String state;
  final String country;
  final String pincode;

  const VisitActivityAddressSummaryRemoteModel({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory VisitActivityAddressSummaryRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VisitActivityAddressSummaryRemoteModel(
      id: _parseInt(json['id']),
      addressName: _asString(json['address_name']),
      addressType: _asString(json['address_type']),
      city: _asString(json['city']),
      state: _asString(json['state']),
      country: _asString(json['country']),
      pincode: _asString(json['pincode']),
    );
  }

  VisitActivityAddressSummaryModel toDomain() {
    return VisitActivityAddressSummaryModel(
      id: id,
      addressName: addressName,
      addressType: addressType,
      city: city,
      state: state,
      country: country,
      pincode: pincode,
    );
  }
}

class VisitActivityRemoteModel {
  final int id;
  final String activityType;
  final String activityStatus;
  final int? customerId;
  final int? addressId;
  final String? purpose;
  final String? estimatedTime;
  final int? estimatedDuration;
  final String? activityStartTime;
  final String? activityEndTime;
  final VisitActivityCustomerSummaryRemoteModel? customer;
  final VisitActivityAddressSummaryRemoteModel? address;

  const VisitActivityRemoteModel({
    required this.id,
    required this.activityType,
    required this.activityStatus,
    this.customerId,
    this.addressId,
    this.purpose,
    this.estimatedTime,
    this.estimatedDuration,
    this.activityStartTime,
    this.activityEndTime,
    this.customer,
    this.address,
  });

  factory VisitActivityRemoteModel.fromJson(Map<String, dynamic> json) {
    final customerJson =
        json['VisitCustomer'] is Map<String, dynamic>
            ? json['VisitCustomer'] as Map<String, dynamic>
            : null;
    final addressJson =
        json['VisitAddress'] is Map<String, dynamic>
            ? json['VisitAddress'] as Map<String, dynamic>
            : null;

    return VisitActivityRemoteModel(
      id: _parseInt(json['id']),
      activityType: _asString(json['activity_type']),
      activityStatus: _asString(json['activity_status']),
      customerId: _parseNullableInt(json['customer_id']),
      addressId: _parseNullableInt(json['address_id']),
      purpose: _nullableString(json['purpose']),
      estimatedTime: _normalizeTime(json['estimated_time']),
      estimatedDuration: _parseNullableInt(json['estimated_duration']),
      activityStartTime: _normalizeTime(json['activity_start_time']),
      activityEndTime: _normalizeTime(json['activity_end_time']),
      customer:
          customerJson == null
              ? null
              : VisitActivityCustomerSummaryRemoteModel.fromJson(customerJson),
      address:
          addressJson == null
              ? null
              : VisitActivityAddressSummaryRemoteModel.fromJson(addressJson),
    );
  }

  VisitActivityModel toDomain() {
    return VisitActivityModel(
      id: id,
      activityType: activityType,
      activityStatus: activityStatus,
      customerId: customerId,
      addressId: addressId,
      purpose: purpose,
      estimatedTime: estimatedTime,
      estimatedDuration: estimatedDuration,
      activityStartTime: activityStartTime,
      activityEndTime: activityEndTime,
      customer: customer?.toDomain(),
      address: address?.toDomain(),
    );
  }
}

class VisitActivityContactRemoteModel {
  final String name;
  final String email;
  final String phone;
  final bool isPrimary;
  final String designation;

  const VisitActivityContactRemoteModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.isPrimary,
    required this.designation,
  });

  factory VisitActivityContactRemoteModel.fromJson(Map<String, dynamic> json) {
    return VisitActivityContactRemoteModel(
      name: _asString(json['name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      isPrimary: _parseBool(json['is_primary']),
      designation: _asString(json['designation']),
    );
  }

  VisitActivityContactModel toDomain() {
    return VisitActivityContactModel(
      name: name,
      email: email,
      phone: phone,
      isPrimary: isPrimary,
      designation: designation,
    );
  }
}

class VisitActivityDetailAddressRemoteModel {
  final String city;
  final String type;
  final String label;
  final String state;
  final String address;
  final String country;
  final String pincode;
  final String? latitude;
  final String? longitude;
  final List<VisitActivityContactRemoteModel> contacts;

  const VisitActivityDetailAddressRemoteModel({
    required this.city,
    required this.type,
    required this.label,
    required this.state,
    required this.address,
    required this.country,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.contacts = const [],
  });

  factory VisitActivityDetailAddressRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final contactsJson = (json['contacts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VisitActivityContactRemoteModel.fromJson)
        .toList(growable: false);

    return VisitActivityDetailAddressRemoteModel(
      city: _asString(json['city']),
      type: _asString(json['type']),
      label: _asString(json['label']),
      state: _asString(json['state']),
      address: _asString(json['address']),
      country: _asString(json['country']),
      pincode: _asString(json['pincode']),
      latitude: _nullableString(json['latitude']),
      longitude: _nullableString(json['longitude']),
      contacts: contactsJson,
    );
  }

  VisitActivityDetailAddressModel toDomain() {
    return VisitActivityDetailAddressModel(
      city: city,
      type: type,
      label: label,
      state: state,
      address: address,
      country: country,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      contacts: contacts.map((contact) => contact.toDomain()).toList(
        growable: false,
      ),
    );
  }
}

class VisitActivityDetailCustomerRemoteModel {
  final int id;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String businessDomain;
  final List<VisitActivityDetailAddressRemoteModel> addresses;

  const VisitActivityDetailCustomerRemoteModel({
    required this.id,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.businessDomain,
    this.addresses = const [],
  });

  factory VisitActivityDetailCustomerRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final addressesJson = (json['addresses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VisitActivityDetailAddressRemoteModel.fromJson)
        .toList(growable: false);

    return VisitActivityDetailCustomerRemoteModel(
      id: _parseInt(json['id']),
      customerName: _asString(json['customer_name']),
      customerCode: _asString(json['customer_code']),
      customerType: _asString(json['customer_type']),
      businessDomain: _asString(json['business_domian']),
      addresses: addressesJson,
    );
  }

  VisitActivityDetailCustomerModel toDomain() {
    return VisitActivityDetailCustomerModel(
      id: id,
      customerName: customerName,
      customerCode: customerCode,
      customerType: customerType,
      businessDomain: businessDomain,
      addresses: addresses
          .map((address) => address.toDomain())
          .toList(growable: false),
    );
  }
}

class VisitActivityDetailRemoteModel {
  final int id;
  final int clientId;
  final int visitId;
  final int? userId;
  final String activityType;
  final int? addressId;
  final int? areaId;
  final int? customerId;
  final String? estimatedTime;
  final int? estimatedDuration;
  final String? purpose;
  final String? activityStartTime;
  final String? activityEndTime;
  final double? activityStartLat;
  final double? activityStartLng;
  final double? activityEndLat;
  final double? activityEndLng;
  final String? activityCheckinSelfie;
  final String? activityCheckoutSelfie;
  final String activityStatus;
  final String? recordStatus;
  final VisitActivityDetailCustomerRemoteModel? customer;
  final VisitActivityAddressSummaryRemoteModel? address;

  const VisitActivityDetailRemoteModel({
    required this.id,
    required this.clientId,
    required this.visitId,
    this.userId,
    required this.activityType,
    this.addressId,
    this.areaId,
    this.customerId,
    this.estimatedTime,
    this.estimatedDuration,
    this.purpose,
    this.activityStartTime,
    this.activityEndTime,
    this.activityStartLat,
    this.activityStartLng,
    this.activityEndLat,
    this.activityEndLng,
    this.activityCheckinSelfie,
    this.activityCheckoutSelfie,
    required this.activityStatus,
    this.recordStatus,
    this.customer,
    this.address,
  });

  factory VisitActivityDetailRemoteModel.fromJson(Map<String, dynamic> json) {
    final customerJson =
        json['VisitCustomer'] is Map<String, dynamic>
            ? json['VisitCustomer'] as Map<String, dynamic>
            : null;
    final addressJson =
        json['VisitAddress'] is Map<String, dynamic>
            ? json['VisitAddress'] as Map<String, dynamic>
            : null;

    return VisitActivityDetailRemoteModel(
      id: _parseInt(json['id']),
      clientId: _parseInt(json['client_id']),
      visitId: _parseInt(json['visit_id']),
      userId: _parseNullableInt(json['user_id']),
      activityType: _asString(json['activity_type']),
      addressId: _parseNullableInt(json['address_id']),
      areaId: _parseNullableInt(json['area_id']),
      customerId: _parseNullableInt(json['customer_id']),
      estimatedTime: _normalizeTime(json['estimated_time']),
      estimatedDuration: _parseNullableInt(json['estimated_duration']),
      purpose: _nullableString(json['purpose']),
      activityStartTime: _normalizeTime(json['activity_start_time']),
      activityEndTime: _normalizeTime(json['activity_end_time']),
      activityStartLat: _parseNullableDouble(json['activity_start_lat']),
      activityStartLng: _parseNullableDouble(json['activity_start_lng']),
      activityEndLat: _parseNullableDouble(json['activity_end_lat']),
      activityEndLng: _parseNullableDouble(json['activity_end_lng']),
      activityCheckinSelfie: _nullableString(json['activity_checkin_selfie']),
      activityCheckoutSelfie: _nullableString(json['activity_checkout_selfie']),
      activityStatus: _asString(json['activity_status']),
      recordStatus: _nullableString(json['status']),
      customer:
          customerJson == null
              ? null
              : VisitActivityDetailCustomerRemoteModel.fromJson(customerJson),
      address:
          addressJson == null
              ? null
              : VisitActivityAddressSummaryRemoteModel.fromJson(addressJson),
    );
  }

  VisitActivityDetailModel toDomain() {
    return VisitActivityDetailModel(
      id: id,
      clientId: clientId,
      visitId: visitId,
      userId: userId,
      activityType: activityType,
      addressId: addressId,
      areaId: areaId,
      customerId: customerId,
      estimatedTime: estimatedTime,
      estimatedDuration: estimatedDuration,
      purpose: purpose,
      activityStartTime: activityStartTime,
      activityEndTime: activityEndTime,
      activityStartLat: activityStartLat,
      activityStartLng: activityStartLng,
      activityEndLat: activityEndLat,
      activityEndLng: activityEndLng,
      activityCheckinSelfie: activityCheckinSelfie,
      activityCheckoutSelfie: activityCheckoutSelfie,
      activityStatus: activityStatus,
      recordStatus: recordStatus,
      customer: customer?.toDomain(),
      address: address?.toDomain(),
    );
  }
}

class VisitDetailRemoteModel {
  final int id;
  final int clientId;
  final String visitType;
  final String visitTitle;
  final String? description;
  final DateTime? scheduledDate;
  final String? startTime;
  final String? endTime;
  final DateTime? completedDate;
  final DateTime? visitStartedAt;
  final DateTime? visitCompletedAt;
  final double? totalDistance;
  final String visitStatus;
  final String? recordStatus;
  final int createdById;
  final DateTime? createdAt;
  final int updatedById;
  final DateTime? updatedAt;
  final VisitUserRemoteModel createdBy;
  final List<VisitParticipantRemoteModel> participants;
  final List<VisitActivityRemoteModel> activities;

  const VisitDetailRemoteModel({
    required this.id,
    required this.clientId,
    required this.visitType,
    required this.visitTitle,
    this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.completedDate,
    this.visitStartedAt,
    this.visitCompletedAt,
    this.totalDistance,
    required this.visitStatus,
    this.recordStatus,
    required this.createdById,
    this.createdAt,
    required this.updatedById,
    this.updatedAt,
    required this.createdBy,
    required this.participants,
    required this.activities,
  });

  factory VisitDetailRemoteModel.fromJson(Map<String, dynamic> json) {
    final createdByJson =
        json['VisitCreatedBy'] is Map<String, dynamic>
            ? json['VisitCreatedBy'] as Map<String, dynamic>
            : <String, dynamic>{};
    final participantsJson = (json['VisitParticipants'] as List<dynamic>? ??
            const [])
        .whereType<Map<String, dynamic>>()
        .map(VisitParticipantRemoteModel.fromJson)
        .toList(growable: false);
    final activitiesJson = (json['VisitActivities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VisitActivityRemoteModel.fromJson)
        .toList(growable: false);

    return VisitDetailRemoteModel(
      id: _parseInt(json['id']),
      clientId: _parseInt(json['client_id']),
      visitType: _asString(json['visit_type']),
      visitTitle: _asString(json['visit_title']),
      description: _nullableString(json['description']),
      scheduledDate: _parseDate(json['scheduled_date']),
      startTime: _normalizeTime(json['start_time']),
      endTime: _normalizeTime(json['end_time']),
      completedDate: _parseDate(json['completed_date']),
      visitStartedAt: _parseDateTime(json['visit_started_at']),
      visitCompletedAt: _parseDateTime(json['visit_completed_at']),
      totalDistance: _parseNullableDouble(json['total_distance']),
      visitStatus: _asString(json['visit_status']),
      recordStatus: _nullableString(json['status']),
      createdById: _parseInt(json['created_by']),
      createdAt: _parseDateTime(json['created_at']),
      updatedById: _parseInt(json['updated_by']),
      updatedAt: _parseDateTime(json['updated_at']),
      createdBy: VisitUserRemoteModel.fromJson(createdByJson),
      participants: participantsJson,
      activities: activitiesJson,
    );
  }

  VisitDetailModel toDomain() {
    return VisitDetailModel(
      id: id,
      clientId: clientId,
      type: VisitType.fromValue(visitType),
      visitTitle: visitTitle,
      description: description,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      completedDate: completedDate,
      visitStartedAt: visitStartedAt,
      visitCompletedAt: visitCompletedAt,
      totalDistance: totalDistance,
      status: VisitStatus.fromValue(visitStatus),
      recordStatus: recordStatus,
      createdById: createdById,
      createdAt: createdAt,
      updatedById: updatedById,
      updatedAt: updatedAt,
      createdBy: createdBy.toDomain(),
      participants: participants
          .map((participant) => participant.toDomain())
          .toList(growable: false),
      activities: activities
          .map((activity) => activity.toDomain())
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

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  if (value is String) return int.tryParse(value.trim());
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
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
