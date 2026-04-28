import 'package:equatable/equatable.dart';

class AccountCreatorModel extends Equatable {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String profileColor;
  final String imageUrl;

  const AccountCreatorModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profileColor,
    required this.imageUrl,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Unknown User' : name;
  }

  @override
  List<Object?> get props => [
    userId,
    firstName,
    lastName,
    email,
    profileColor,
    imageUrl,
  ];
}

class AccountContactModel extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String designation;
  final bool isPrimary;

  const AccountContactModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [name, email, phone, designation, isPrimary];
}

class AccountCustomerModel extends Equatable {
  final int id;
  final String customerName;
  final String businessDomain;
  final String customerType;
  final String customerCode;
  final DateTime? createdAt;
  final String status;
  final AccountCreatorModel? createdBy;

  const AccountCustomerModel({
    required this.id,
    required this.customerName,
    required this.businessDomain,
    required this.customerType,
    required this.customerCode,
    required this.createdAt,
    required this.status,
    this.createdBy,
  });

  String get titleLabel {
    final code = customerCode.trim();
    if (code.isEmpty) return customerName.trim().isEmpty ? '--' : customerName;
    return '${customerName.trim()} - $code';
  }

  String get businessDomainLabel =>
      businessDomain.trim().isEmpty ? '--' : businessDomain;

  @override
  List<Object?> get props => [
    id,
    customerName,
    businessDomain,
    customerType,
    customerCode,
    createdAt,
    status,
    createdBy,
  ];
}

class AccountAddressModel extends Equatable {
  final int id;
  final String addressName;
  final String addressType;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final String latitude;
  final String longitude;
  final DateTime? createdAt;
  final List<AccountVisitAreaModel> visitAreas;

  const AccountAddressModel({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.pincode,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.visitAreas = const [],
  });

  String get titleLabel {
    final type = addressType.trim();
    if (type.isEmpty) return addressName.trim().isEmpty ? '--' : addressName;
    return '${addressName.trim()} - $type';
  }

  String get locationLabel {
    final parts = [
      city.trim(),
      state.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty);
    final value = parts.join(', ');
    return value.isEmpty ? '--' : value;
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
    createdAt,
    visitAreas,
  ];
}

class AccountVisitAreaModel extends Equatable {
  final int areaId;
  final String areaName;
  final String description;
  final String latitude;
  final String longitude;
  final List<AccountPolygonPointModel> polygon;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountVisitAreaModel({
    required this.areaId,
    required this.areaName,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.polygon = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    areaId,
    areaName,
    description,
    latitude,
    longitude,
    polygon,
    status,
    createdAt,
    updatedAt,
  ];
}

class AccountPolygonPointModel extends Equatable {
  final double latitude;
  final double longitude;

  const AccountPolygonPointModel({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class AccountCustomerDetailAddressModel extends Equatable {
  final String city;
  final String type;
  final String label;
  final String state;
  final String address;
  final String country;
  final String pincode;
  final List<AccountContactModel> contacts;
  final String latitude;
  final String longitude;

  const AccountCustomerDetailAddressModel({
    required this.city,
    required this.type,
    required this.label,
    required this.state,
    required this.address,
    required this.country,
    required this.pincode,
    required this.contacts,
    required this.latitude,
    required this.longitude,
  });

  String get titleLabel {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isNotEmpty) {
      return trimmedAddress;
    }
    return label.trim().isEmpty ? '--' : label.trim();
  }

  String get subtitleLabel {
    final parts = [
      city.trim(),
      state.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty);
    final value = parts.join(', ');
    return value.isEmpty ? '--' : value;
  }

  AccountContactModel? get primaryContact {
    for (final contact in contacts) {
      if (contact.isPrimary) return contact;
    }
    return contacts.isEmpty ? null : contacts.first;
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
    contacts,
    latitude,
    longitude,
  ];
}

class AccountCustomerDetailModel extends Equatable {
  final int id;
  final String customerType;
  final String customerName;
  final String customerCode;
  final String businessDomain;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AccountCreatorModel? createdBy;
  final List<AccountCustomerDetailAddressModel> addresses;

  const AccountCustomerDetailModel({
    required this.id,
    required this.customerType,
    required this.customerName,
    required this.customerCode,
    required this.businessDomain,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.addresses,
  });

  AccountCustomerDetailAddressModel? get primaryAddress {
    return addresses.isEmpty ? null : addresses.first;
  }

  AccountContactModel? get primaryContact => primaryAddress?.primaryContact;

  @override
  List<Object?> get props => [
    id,
    customerType,
    customerName,
    customerCode,
    businessDomain,
    description,
    status,
    createdAt,
    updatedAt,
    createdBy,
    addresses,
  ];
}

class AccountAddressDetailModel extends Equatable {
  final int id;
  final String addressName;
  final String addressType;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final List<AccountPolygonPointModel> polygon;
  final String latitude;
  final String longitude;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AccountVisitAreaModel> visitAreas;

  const AccountAddressDetailModel({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.pincode,
    required this.city,
    required this.state,
    required this.country,
    this.polygon = const [],
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.visitAreas,
  });

  String get titleLabel {
    final trimmedType = addressType.trim();
    if (trimmedType.isEmpty) {
      return addressName.trim().isEmpty ? '--' : addressName.trim();
    }
    return '${addressName.trim()} - $trimmedType';
  }

  String get locationLabel {
    final parts = [
      city.trim(),
      state.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty);
    final value = parts.join(', ');
    return value.isEmpty ? '--' : value;
  }

  String get coordinatesLabel {
    final hasLatitude = latitude.trim().isNotEmpty;
    final hasLongitude = longitude.trim().isNotEmpty;
    if (!hasLatitude && !hasLongitude) return '--';
    if (hasLatitude && hasLongitude) {
      return '${latitude.trim()}, ${longitude.trim()}';
    }
    return hasLatitude ? latitude.trim() : longitude.trim();
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
    polygon,
    latitude,
    longitude,
    status,
    createdAt,
    updatedAt,
    visitAreas,
  ];
}

class CreateAccountCustomerParams extends Equatable {
  final String customerName;
  final String customerCode;
  final String customerType;
  final String businessDomain;
  final String description;
  final List<CreateAccountAddressParams> addresses;

  const CreateAccountCustomerParams({
    required this.customerName,
    required this.customerCode,
    required this.customerType,
    required this.businessDomain,
    required this.description,
    required this.addresses,
  });

  @override
  List<Object?> get props => [
    customerName,
    customerCode,
    customerType,
    businessDomain,
    description,
    addresses,
  ];
}

class CreateAccountAddressParams extends Equatable {
  final String label;
  final String type;
  final String address;
  final String country;
  final String state;
  final String city;
  final String pincode;
  final String latitude;
  final String longitude;
  final List<CreateAccountContactParams> contacts;

  const CreateAccountAddressParams({
    required this.label,
    required this.type,
    required this.address,
    required this.country,
    required this.state,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.contacts,
  });

  @override
  List<Object?> get props => [
    label,
    type,
    address,
    country,
    state,
    city,
    pincode,
    latitude,
    longitude,
    contacts,
  ];
}

class CreateAccountContactParams extends Equatable {
  final String name;
  final String designation;
  final String phone;
  final String email;
  final bool isPrimary;

  const CreateAccountContactParams({
    required this.name,
    required this.designation,
    required this.phone,
    required this.email,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [name, designation, phone, email, isPrimary];
}

class CreateVisitAddressPolygonPointParams extends Equatable {
  final double latitude;
  final double longitude;

  const CreateVisitAddressPolygonPointParams({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class CreateVisitAddressParams extends Equatable {
  final String addressName;
  final String addressType;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final String latitude;
  final String longitude;
  final List<CreateVisitAddressPolygonPointParams> polygon;

  const CreateVisitAddressParams({
    required this.addressName,
    required this.addressType,
    required this.pincode,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.polygon,
  });

  @override
  List<Object?> get props => [
    addressName,
    addressType,
    pincode,
    city,
    state,
    country,
    latitude,
    longitude,
    polygon,
  ];
}
