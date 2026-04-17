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
