import 'package:equatable/equatable.dart';

enum VisitType {
  customer('CUSTOMER'),
  address('ADDRESS');

  final String value;

  const VisitType(this.value);

  String get label => value[0] + value.substring(1).toLowerCase();

  static VisitType? fromValue(String? value) {
    if (value == null) return null;
    for (final type in VisitType.values) {
      if (type.value == value.trim().toUpperCase()) {
        return type;
      }
    }
    return null;
  }
}

enum VisitStatus {
  planned('PLANNED'),
  started('STARTED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String value;

  const VisitStatus(this.value);

  String get label => value[0] + value.substring(1).toLowerCase();

  static VisitStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final status in VisitStatus.values) {
      if (status.value == value.trim().toUpperCase()) {
        return status;
      }
    }
    return null;
  }
}

class VisitUserModel extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const VisitUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Unknown User' : name;
  }

  String get initials {
    final parts = fullName.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, profileColor];
}

class VisitParticipantModel extends Equatable {
  final int id;
  final int userId;
  final String visitStatus;
  final VisitUserModel user;

  const VisitParticipantModel({
    required this.id,
    required this.userId,
    required this.visitStatus,
    required this.user,
  });

  @override
  List<Object?> get props => [id, userId, visitStatus, user];
}

class VisitModel extends Equatable {
  final int id;
  final VisitType? type;
  final String visitTitle;
  final String? description;
  final DateTime? scheduledDate;
  final String? startTime;
  final String? endTime;
  final VisitStatus? status;
  final DateTime? createdAt;
  final VisitUserModel createdBy;
  final List<VisitParticipantModel> participants;

  const VisitModel({
    required this.id,
    required this.type,
    required this.visitTitle,
    this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.participants,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    visitTitle,
    description,
    scheduledDate,
    startTime,
    endTime,
    status,
    createdAt,
    createdBy,
    participants,
  ];
}

class VisitActivityCustomerSummaryModel extends Equatable {
  final int id;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String businessDomain;

  const VisitActivityCustomerSummaryModel({
    required this.id,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.businessDomain,
  });

  @override
  List<Object?> get props => [
    id,
    customerName,
    customerCode,
    customerType,
    businessDomain,
  ];
}

class VisitActivityAddressSummaryModel extends Equatable {
  final int id;
  final String addressName;
  final String addressType;
  final String city;
  final String state;
  final String country;
  final String pincode;

  const VisitActivityAddressSummaryModel({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  String get locationLabel {
    final parts = [
      addressName,
      city,
      state,
      pincode,
    ].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    addressName,
    addressType,
    city,
    state,
    country,
    pincode,
  ];
}

class VisitActivityModel extends Equatable {
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
  final VisitActivityCustomerSummaryModel? customer;
  final VisitActivityAddressSummaryModel? address;

  const VisitActivityModel({
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

  VisitActivityModel copyWith({
    int? id,
    String? activityType,
    String? activityStatus,
    Object? customerId = _visitModelSentinel,
    Object? addressId = _visitModelSentinel,
    Object? purpose = _visitModelSentinel,
    Object? estimatedTime = _visitModelSentinel,
    Object? estimatedDuration = _visitModelSentinel,
    Object? activityStartTime = _visitModelSentinel,
    Object? activityEndTime = _visitModelSentinel,
    Object? customer = _visitModelSentinel,
    Object? address = _visitModelSentinel,
  }) {
    return VisitActivityModel(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      activityStatus: activityStatus ?? this.activityStatus,
      customerId:
          identical(customerId, _visitModelSentinel)
              ? this.customerId
              : customerId as int?,
      addressId:
          identical(addressId, _visitModelSentinel)
              ? this.addressId
              : addressId as int?,
      purpose:
          identical(purpose, _visitModelSentinel)
              ? this.purpose
              : purpose as String?,
      estimatedTime:
          identical(estimatedTime, _visitModelSentinel)
              ? this.estimatedTime
              : estimatedTime as String?,
      estimatedDuration:
          identical(estimatedDuration, _visitModelSentinel)
              ? this.estimatedDuration
              : estimatedDuration as int?,
      activityStartTime:
          identical(activityStartTime, _visitModelSentinel)
              ? this.activityStartTime
              : activityStartTime as String?,
      activityEndTime:
          identical(activityEndTime, _visitModelSentinel)
              ? this.activityEndTime
              : activityEndTime as String?,
      customer:
          identical(customer, _visitModelSentinel)
              ? this.customer
              : customer as VisitActivityCustomerSummaryModel?,
      address:
          identical(address, _visitModelSentinel)
              ? this.address
              : address as VisitActivityAddressSummaryModel?,
    );
  }

  String get displayTitle {
    final customerName = customer?.customerName.trim() ?? '';
    if (customerName.isNotEmpty) return customerName;
    final addressName = address?.addressName.trim() ?? '';
    if (addressName.isNotEmpty) return addressName;
    final normalizedType = activityType.trim();
    if (normalizedType.isNotEmpty) return normalizedType;
    return 'Activity #$id';
  }

  @override
  List<Object?> get props => [
    id,
    activityType,
    activityStatus,
    customerId,
    addressId,
    purpose,
    estimatedTime,
    estimatedDuration,
    activityStartTime,
    activityEndTime,
    customer,
    address,
  ];
}

class VisitDetailModel extends Equatable {
  final int id;
  final int clientId;
  final VisitType? type;
  final String visitTitle;
  final String? description;
  final DateTime? scheduledDate;
  final String? startTime;
  final String? endTime;
  final DateTime? completedDate;
  final DateTime? visitStartedAt;
  final DateTime? visitCompletedAt;
  final double? totalDistance;
  final VisitStatus? status;
  final String? recordStatus;
  final int createdById;
  final DateTime? createdAt;
  final int updatedById;
  final DateTime? updatedAt;
  final VisitUserModel createdBy;
  final List<VisitParticipantModel> participants;
  final List<VisitActivityModel> activities;

  const VisitDetailModel({
    required this.id,
    required this.clientId,
    required this.type,
    required this.visitTitle,
    this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.completedDate,
    this.visitStartedAt,
    this.visitCompletedAt,
    this.totalDistance,
    required this.status,
    this.recordStatus,
    required this.createdById,
    required this.createdAt,
    required this.updatedById,
    this.updatedAt,
    required this.createdBy,
    required this.participants,
    required this.activities,
  });

  VisitDetailModel copyWith({
    int? id,
    int? clientId,
    Object? type = _visitModelSentinel,
    String? visitTitle,
    Object? description = _visitModelSentinel,
    Object? scheduledDate = _visitModelSentinel,
    Object? startTime = _visitModelSentinel,
    Object? endTime = _visitModelSentinel,
    Object? completedDate = _visitModelSentinel,
    Object? visitStartedAt = _visitModelSentinel,
    Object? visitCompletedAt = _visitModelSentinel,
    Object? totalDistance = _visitModelSentinel,
    Object? status = _visitModelSentinel,
    Object? recordStatus = _visitModelSentinel,
    int? createdById,
    Object? createdAt = _visitModelSentinel,
    int? updatedById,
    Object? updatedAt = _visitModelSentinel,
    VisitUserModel? createdBy,
    List<VisitParticipantModel>? participants,
    List<VisitActivityModel>? activities,
  }) {
    return VisitDetailModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      type:
          identical(type, _visitModelSentinel)
              ? this.type
              : type as VisitType?,
      visitTitle: visitTitle ?? this.visitTitle,
      description:
          identical(description, _visitModelSentinel)
              ? this.description
              : description as String?,
      scheduledDate:
          identical(scheduledDate, _visitModelSentinel)
              ? this.scheduledDate
              : scheduledDate as DateTime?,
      startTime:
          identical(startTime, _visitModelSentinel)
              ? this.startTime
              : startTime as String?,
      endTime:
          identical(endTime, _visitModelSentinel)
              ? this.endTime
              : endTime as String?,
      completedDate:
          identical(completedDate, _visitModelSentinel)
              ? this.completedDate
              : completedDate as DateTime?,
      visitStartedAt:
          identical(visitStartedAt, _visitModelSentinel)
              ? this.visitStartedAt
              : visitStartedAt as DateTime?,
      visitCompletedAt:
          identical(visitCompletedAt, _visitModelSentinel)
              ? this.visitCompletedAt
              : visitCompletedAt as DateTime?,
      totalDistance:
          identical(totalDistance, _visitModelSentinel)
              ? this.totalDistance
              : totalDistance as double?,
      status:
          identical(status, _visitModelSentinel)
              ? this.status
              : status as VisitStatus?,
      recordStatus:
          identical(recordStatus, _visitModelSentinel)
              ? this.recordStatus
              : recordStatus as String?,
      createdById: createdById ?? this.createdById,
      createdAt:
          identical(createdAt, _visitModelSentinel)
              ? this.createdAt
              : createdAt as DateTime?,
      updatedById: updatedById ?? this.updatedById,
      updatedAt:
          identical(updatedAt, _visitModelSentinel)
              ? this.updatedAt
              : updatedAt as DateTime?,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      activities: activities ?? this.activities,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    type,
    visitTitle,
    description,
    scheduledDate,
    startTime,
    endTime,
    completedDate,
    visitStartedAt,
    visitCompletedAt,
    totalDistance,
    status,
    recordStatus,
    createdById,
    createdAt,
    updatedById,
    updatedAt,
    createdBy,
    participants,
    activities,
  ];
}

class VisitEmployeeModel extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? employeeId;
  final String? profileColor;
  final String? imageUrl;
  final String? department;
  final String? designation;

  const VisitEmployeeModel({
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

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    employeeId,
    profileColor,
    imageUrl,
    department,
    designation,
  ];
}

class VisitCustomerModel extends Equatable {
  final int id;
  final String customerName;
  final String businessDomain;
  final String customerType;
  final String customerCode;
  final String status;

  const VisitCustomerModel({
    required this.id,
    required this.customerName,
    required this.businessDomain,
    required this.customerType,
    required this.customerCode,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id,
    customerName,
    businessDomain,
    customerType,
    customerCode,
    status,
  ];
}

class VisitAddressModel extends Equatable {
  final int id;
  final String addressName;
  final String addressType;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final String? latitude;
  final String? longitude;

  const VisitAddressModel({
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

  String get locationLabel {
    final parts = [addressName, city].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    addressName,
    addressType,
    pincode,
    city,
    state,
    country,
    latitude,
    longitude,
  ];
}

class CreateVisitParams extends Equatable {
  final VisitType type;
  final String visitTitle;
  final String description;
  final DateTime scheduledDate;
  final String? startTime;
  final String? endTime;
  final int userId;

  const CreateVisitParams({
    required this.type,
    required this.visitTitle,
    required this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    required this.userId,
  });

  @override
  List<Object?> get props => [
    type,
    visitTitle,
    description,
    scheduledDate,
    startTime,
    endTime,
    userId,
  ];
}

class VisitActivityCustomerDetails extends Equatable {
  final String customerName;
  final String customerContactNumber;
  final String customerAddress;

  const VisitActivityCustomerDetails({
    required this.customerName,
    required this.customerContactNumber,
    required this.customerAddress,
  });

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'customer_contact_number': customerContactNumber,
    'customer_address': customerAddress,
  };

  @override
  List<Object?> get props => [
    customerName,
    customerContactNumber,
    customerAddress,
  ];
}

class VisitActivityCustomerAddress extends Equatable {
  final String label;
  final String address;
  final String city;
  final String pincode;
  final String latitude;
  final String longitude;

  const VisitActivityCustomerAddress({
    required this.label,
    required this.address,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': address,
    'city': city,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  List<Object?> get props => [
    label,
    address,
    city,
    pincode,
    latitude,
    longitude,
  ];
}

class CreateVisitActivityParams extends Equatable {
  final int visitId;
  final int userId;
  final String activityType;
  final int? customerId;
  final VisitActivityCustomerDetails? customerDetails;
  final VisitActivityCustomerAddress? customerAddress;
  final int? addressId;
  final int? areaId;
  final String estimatedTime;
  final int estimatedDuration;
  final String purpose;

  const CreateVisitActivityParams({
    required this.visitId,
    required this.userId,
    required this.activityType,
    this.customerId,
    this.customerDetails,
    this.customerAddress,
    this.addressId,
    this.areaId,
    required this.estimatedTime,
    required this.estimatedDuration,
    required this.purpose,
  });

  @override
  List<Object?> get props => [
    visitId,
    userId,
    activityType,
    customerId,
    customerDetails,
    customerAddress,
    addressId,
    areaId,
    estimatedTime,
    estimatedDuration,
    purpose,
  ];
}

class UpdateVisitActivityParams extends Equatable {
  final int activityId;
  final Object? userId;
  final Object? activityType;
  final Object? customerId;
  final Object? customerDetails;
  final Object? customerAddress;
  final Object? addressId;
  final Object? areaId;
  final Object? estimatedTime;
  final Object? estimatedDuration;
  final Object? purpose;

  const UpdateVisitActivityParams({
    required this.activityId,
    this.userId = _visitModelSentinel,
    this.activityType = _visitModelSentinel,
    this.customerId = _visitModelSentinel,
    this.customerDetails = _visitModelSentinel,
    this.customerAddress = _visitModelSentinel,
    this.addressId = _visitModelSentinel,
    this.areaId = _visitModelSentinel,
    this.estimatedTime = _visitModelSentinel,
    this.estimatedDuration = _visitModelSentinel,
    this.purpose = _visitModelSentinel,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'activity_id': activityId};

    if (!identical(userId, _visitModelSentinel)) {
      data['user_id'] = userId as int?;
    }
    if (!identical(activityType, _visitModelSentinel)) {
      data['activity_type'] = activityType as String?;
    }
    if (!identical(customerId, _visitModelSentinel)) {
      data['customer_id'] = customerId as int?;
    }
    if (!identical(customerDetails, _visitModelSentinel)) {
      data['customer_details'] =
          (customerDetails as VisitActivityCustomerDetails?)?.toJson();
    }
    if (!identical(customerAddress, _visitModelSentinel)) {
      data['customer_address'] =
          (customerAddress as VisitActivityCustomerAddress?)?.toJson();
    }
    if (!identical(addressId, _visitModelSentinel)) {
      data['address_id'] = addressId as int?;
    }
    if (!identical(areaId, _visitModelSentinel)) {
      data['area_id'] = areaId as int?;
    }
    if (!identical(estimatedTime, _visitModelSentinel)) {
      data['estimated_time'] = estimatedTime as String?;
    }
    if (!identical(estimatedDuration, _visitModelSentinel)) {
      data['estimated_duration'] = estimatedDuration as int?;
    }
    if (!identical(purpose, _visitModelSentinel)) {
      data['purpose'] = purpose as String?;
    }

    return data;
  }

  @override
  List<Object?> get props => [
    activityId,
    userId,
    activityType,
    customerId,
    customerDetails,
    customerAddress,
    addressId,
    areaId,
    estimatedTime,
    estimatedDuration,
    purpose,
  ];
}

class StartVisitActivityParams extends Equatable {
  final int activityId;
  final double activityStartLat;
  final double activityStartLng;
  final String activityCheckinSelfiePath;

  const StartVisitActivityParams({
    required this.activityId,
    required this.activityStartLat,
    required this.activityStartLng,
    required this.activityCheckinSelfiePath,
  });

  @override
  List<Object?> get props => [
    activityId,
    activityStartLat,
    activityStartLng,
    activityCheckinSelfiePath,
  ];
}

class CompleteVisitActivityParams extends Equatable {
  final int activityId;
  final double activityEndLat;
  final double activityEndLng;
  final String activityCheckoutSelfiePath;

  const CompleteVisitActivityParams({
    required this.activityId,
    required this.activityEndLat,
    required this.activityEndLng,
    required this.activityCheckoutSelfiePath,
  });

  @override
  List<Object?> get props => [
    activityId,
    activityEndLat,
    activityEndLng,
    activityCheckoutSelfiePath,
  ];
}

class VisitActivityContactModel extends Equatable {
  final String name;
  final String email;
  final String phone;
  final bool isPrimary;
  final String designation;

  const VisitActivityContactModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.isPrimary,
    required this.designation,
  });

  @override
  List<Object?> get props => [name, email, phone, isPrimary, designation];
}

class VisitActivityDetailAddressModel extends Equatable {
  final String city;
  final String type;
  final String label;
  final String state;
  final String address;
  final String country;
  final String pincode;
  final String? latitude;
  final String? longitude;
  final List<VisitActivityContactModel> contacts;

  const VisitActivityDetailAddressModel({
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

  String get locationLabel {
    final parts = [
      address,
      city,
      state,
      country,
      pincode,
    ].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    city,
    type,
    label,
    state,
    address,
    country,
    pincode,
    latitude,
    longitude,
    contacts,
  ];
}

class VisitActivityDetailCustomerModel extends Equatable {
  final int id;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String businessDomain;
  final List<VisitActivityDetailAddressModel> addresses;

  const VisitActivityDetailCustomerModel({
    required this.id,
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.businessDomain,
    this.addresses = const [],
  });

  @override
  List<Object?> get props => [
    id,
    customerName,
    customerCode,
    customerType,
    businessDomain,
    addresses,
  ];
}

class VisitActivityDetailModel extends Equatable {
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
  final VisitActivityDetailCustomerModel? customer;
  final VisitActivityAddressSummaryModel? address;

  const VisitActivityDetailModel({
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

  VisitActivityDetailModel copyWith({
    int? id,
    int? clientId,
    int? visitId,
    Object? userId = _visitModelSentinel,
    String? activityType,
    Object? addressId = _visitModelSentinel,
    Object? areaId = _visitModelSentinel,
    Object? customerId = _visitModelSentinel,
    Object? estimatedTime = _visitModelSentinel,
    Object? estimatedDuration = _visitModelSentinel,
    Object? purpose = _visitModelSentinel,
    Object? activityStartTime = _visitModelSentinel,
    Object? activityEndTime = _visitModelSentinel,
    Object? activityStartLat = _visitModelSentinel,
    Object? activityStartLng = _visitModelSentinel,
    Object? activityEndLat = _visitModelSentinel,
    Object? activityEndLng = _visitModelSentinel,
    Object? activityCheckinSelfie = _visitModelSentinel,
    Object? activityCheckoutSelfie = _visitModelSentinel,
    String? activityStatus,
    Object? recordStatus = _visitModelSentinel,
    Object? customer = _visitModelSentinel,
    Object? address = _visitModelSentinel,
  }) {
    return VisitActivityDetailModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      visitId: visitId ?? this.visitId,
      userId:
          identical(userId, _visitModelSentinel) ? this.userId : userId as int?,
      activityType: activityType ?? this.activityType,
      addressId:
          identical(addressId, _visitModelSentinel)
              ? this.addressId
              : addressId as int?,
      areaId:
          identical(areaId, _visitModelSentinel) ? this.areaId : areaId as int?,
      customerId:
          identical(customerId, _visitModelSentinel)
              ? this.customerId
              : customerId as int?,
      estimatedTime:
          identical(estimatedTime, _visitModelSentinel)
              ? this.estimatedTime
              : estimatedTime as String?,
      estimatedDuration:
          identical(estimatedDuration, _visitModelSentinel)
              ? this.estimatedDuration
              : estimatedDuration as int?,
      purpose:
          identical(purpose, _visitModelSentinel)
              ? this.purpose
              : purpose as String?,
      activityStartTime:
          identical(activityStartTime, _visitModelSentinel)
              ? this.activityStartTime
              : activityStartTime as String?,
      activityEndTime:
          identical(activityEndTime, _visitModelSentinel)
              ? this.activityEndTime
              : activityEndTime as String?,
      activityStartLat:
          identical(activityStartLat, _visitModelSentinel)
              ? this.activityStartLat
              : activityStartLat as double?,
      activityStartLng:
          identical(activityStartLng, _visitModelSentinel)
              ? this.activityStartLng
              : activityStartLng as double?,
      activityEndLat:
          identical(activityEndLat, _visitModelSentinel)
              ? this.activityEndLat
              : activityEndLat as double?,
      activityEndLng:
          identical(activityEndLng, _visitModelSentinel)
              ? this.activityEndLng
              : activityEndLng as double?,
      activityCheckinSelfie:
          identical(activityCheckinSelfie, _visitModelSentinel)
              ? this.activityCheckinSelfie
              : activityCheckinSelfie as String?,
      activityCheckoutSelfie:
          identical(activityCheckoutSelfie, _visitModelSentinel)
              ? this.activityCheckoutSelfie
              : activityCheckoutSelfie as String?,
      activityStatus: activityStatus ?? this.activityStatus,
      recordStatus:
          identical(recordStatus, _visitModelSentinel)
              ? this.recordStatus
              : recordStatus as String?,
      customer:
          identical(customer, _visitModelSentinel)
              ? this.customer
              : customer as VisitActivityDetailCustomerModel?,
      address:
          identical(address, _visitModelSentinel)
              ? this.address
              : address as VisitActivityAddressSummaryModel?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    visitId,
    userId,
    activityType,
    addressId,
    areaId,
    customerId,
    estimatedTime,
    estimatedDuration,
    purpose,
    activityStartTime,
    activityEndTime,
    activityStartLat,
    activityStartLng,
    activityEndLat,
    activityEndLng,
    activityCheckinSelfie,
    activityCheckoutSelfie,
    activityStatus,
    recordStatus,
    customer,
    address,
  ];
}

const Object _visitModelSentinel = Object();
