import '../../domain/models/account_model.dart';

class AccountCreatorRemoteModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String profileColor;
  final String imageUrl;

  const AccountCreatorRemoteModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profileColor,
    required this.imageUrl,
  });

  factory AccountCreatorRemoteModel.fromJson(Map<String, dynamic> json) {
    return AccountCreatorRemoteModel(
      userId: _parseInt(json['user_id']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      email: _nullableString(json['email']),
      profileColor: _nullableString(json['profile_color']),
      imageUrl: _nullableString(json['image_url']),
    );
  }

  AccountCreatorModel toDomain() {
    return AccountCreatorModel(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      profileColor: profileColor,
      imageUrl: imageUrl,
    );
  }
}

class AccountContactRemoteModel {
  final String name;
  final String email;
  final String phone;
  final String designation;
  final bool isPrimary;

  const AccountContactRemoteModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.isPrimary,
  });

  factory AccountContactRemoteModel.fromJson(Map<String, dynamic> json) {
    return AccountContactRemoteModel(
      name: _asString(json['name']),
      email: _nullableString(json['email']),
      phone: _nullableString(json['phone']),
      designation: _nullableString(json['designation']),
      isPrimary: _parseBool(json['is_primary']),
    );
  }

  AccountContactModel toDomain() {
    return AccountContactModel(
      name: name,
      email: email,
      phone: phone,
      designation: designation,
      isPrimary: isPrimary,
    );
  }
}

class AccountCustomerRemoteModel {
  final int id;
  final String customerName;
  final String businessDomain;
  final String customerType;
  final String customerCode;
  final DateTime? createdAt;
  final String status;
  final AccountCreatorRemoteModel? createdBy;

  const AccountCustomerRemoteModel({
    required this.id,
    required this.customerName,
    required this.businessDomain,
    required this.customerType,
    required this.customerCode,
    required this.createdAt,
    required this.status,
    this.createdBy,
  });

  factory AccountCustomerRemoteModel.fromJson(Map<String, dynamic> json) {
    final createdByJson =
        json['CustomerCreatedBy'] is Map<String, dynamic>
            ? json['CustomerCreatedBy'] as Map<String, dynamic>
            : null;

    return AccountCustomerRemoteModel(
      id: _parseInt(json['id']),
      customerName: _asString(json['customer_name']),
      businessDomain: _asString(json['business_domian']),
      customerType: _asString(json['customer_type']),
      customerCode: _asString(json['customer_code']),
      createdAt: _parseDateTime(json['created_at']),
      status: _asString(json['status']),
      createdBy:
          createdByJson == null
              ? null
              : AccountCreatorRemoteModel.fromJson(createdByJson),
    );
  }

  AccountCustomerModel toDomain() {
    return AccountCustomerModel(
      id: id,
      customerName: customerName,
      businessDomain: businessDomain,
      customerType: customerType,
      customerCode: customerCode,
      createdAt: createdAt,
      status: status,
      createdBy: createdBy?.toDomain(),
    );
  }
}

class AccountAddressRemoteModel {
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
  final List<AccountVisitAreaRemoteModel> visitAreas;

  const AccountAddressRemoteModel({
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
    required this.visitAreas,
  });

  factory AccountAddressRemoteModel.fromJson(Map<String, dynamic> json) {
    return AccountAddressRemoteModel(
      id: _parseInt(json['id']),
      addressName: _asString(json['address_name']),
      addressType: _asString(json['address_type']),
      pincode: _asString(json['pincode']),
      city: _asString(json['city']),
      state: _asString(json['state']),
      country: _asString(json['country']),
      latitude: _nullableString(json['latitude']),
      longitude: _nullableString(json['longitude']),
      createdAt: _parseDateTime(json['created_at']),
      visitAreas:
          (json['VisitAreas'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AccountVisitAreaRemoteModel.fromJson)
              .toList(growable: false),
    );
  }

  AccountAddressModel toDomain() {
    return AccountAddressModel(
      id: id,
      addressName: addressName,
      addressType: addressType,
      pincode: pincode,
      city: city,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      visitAreas:
          visitAreas.map((visitArea) => visitArea.toDomain()).toList(
            growable: false,
          ),
    );
  }
}

class AccountVisitAreaRemoteModel {
  final int areaId;
  final String areaName;
  final String description;
  final String latitude;
  final String longitude;
  final List<AccountPolygonPointRemoteModel> polygon;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountVisitAreaRemoteModel({
    required this.areaId,
    required this.areaName,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.polygon,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountVisitAreaRemoteModel.fromJson(Map<String, dynamic> json) {
    return AccountVisitAreaRemoteModel(
      areaId: _parseInt(json['area_id']),
      areaName: _asString(json['area_name']),
      description: _nullableString(json['description']),
      latitude: _nullableString(json['latitude']),
      longitude: _nullableString(json['longitude']),
      polygon: _parsePolygonPoints(json['polygon']),
      status: _asString(json['status']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  AccountVisitAreaModel toDomain() {
    return AccountVisitAreaModel(
      areaId: areaId,
      areaName: areaName,
      description: description,
      latitude: latitude,
      longitude: longitude,
      polygon: polygon.map((point) => point.toDomain()).toList(growable: false),
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AccountPolygonPointRemoteModel {
  final double latitude;
  final double longitude;

  const AccountPolygonPointRemoteModel({
    required this.latitude,
    required this.longitude,
  });

  factory AccountPolygonPointRemoteModel.fromJson(Map<String, dynamic> json) {
    return AccountPolygonPointRemoteModel(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  AccountPolygonPointModel toDomain() {
    return AccountPolygonPointModel(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class AccountCustomerDetailAddressRemoteModel {
  final String city;
  final String type;
  final String label;
  final String state;
  final String address;
  final String country;
  final String pincode;
  final List<AccountContactRemoteModel> contacts;
  final String latitude;
  final String longitude;

  const AccountCustomerDetailAddressRemoteModel({
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

  factory AccountCustomerDetailAddressRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AccountCustomerDetailAddressRemoteModel(
      city: _asString(json['city']),
      type: _asString(json['type']),
      label: _asString(json['label']),
      state: _asString(json['state']),
      address: _asString(json['address']),
      country: _asString(json['country']),
      pincode: _asString(json['pincode']),
      contacts:
          (json['contacts'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AccountContactRemoteModel.fromJson)
              .toList(growable: false),
      latitude: _nullableString(json['latitude']),
      longitude: _nullableString(json['longitude']),
    );
  }

  AccountCustomerDetailAddressModel toDomain() {
    return AccountCustomerDetailAddressModel(
      city: city,
      type: type,
      label: label,
      state: state,
      address: address,
      country: country,
      pincode: pincode,
      contacts: contacts.map((contact) => contact.toDomain()).toList(
        growable: false,
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class AccountCustomerDetailRemoteModel {
  final int id;
  final String customerType;
  final String customerName;
  final String customerCode;
  final String businessDomain;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AccountCreatorRemoteModel? createdBy;
  final List<AccountCustomerDetailAddressRemoteModel> addresses;

  const AccountCustomerDetailRemoteModel({
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

  factory AccountCustomerDetailRemoteModel.fromJson(Map<String, dynamic> json) {
    final createdByJson =
        json['CustomerCreatedBy'] is Map<String, dynamic>
            ? json['CustomerCreatedBy'] as Map<String, dynamic>
            : null;

    return AccountCustomerDetailRemoteModel(
      id: _parseInt(json['id']),
      customerType: _asString(json['customer_type']),
      customerName: _asString(json['customer_name']),
      customerCode: _asString(json['customer_code']),
      businessDomain: _asString(json['business_domian']),
      description: _nullableString(json['description']),
      status: _asString(json['status']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      createdBy:
          createdByJson == null
              ? null
              : AccountCreatorRemoteModel.fromJson(createdByJson),
      addresses:
          (json['addresses'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AccountCustomerDetailAddressRemoteModel.fromJson)
              .toList(growable: false),
    );
  }

  AccountCustomerDetailModel toDomain() {
    return AccountCustomerDetailModel(
      id: id,
      customerType: customerType,
      customerName: customerName,
      customerCode: customerCode,
      businessDomain: businessDomain,
      description: description,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy?.toDomain(),
      addresses: addresses.map((address) => address.toDomain()).toList(
        growable: false,
      ),
    );
  }
}

class AccountAddressDetailRemoteModel {
  final int id;
  final String addressName;
  final String addressType;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final List<AccountPolygonPointRemoteModel> polygon;
  final String latitude;
  final String longitude;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AccountVisitAreaRemoteModel> visitAreas;

  const AccountAddressDetailRemoteModel({
    required this.id,
    required this.addressName,
    required this.addressType,
    required this.pincode,
    required this.city,
    required this.state,
    required this.country,
    required this.polygon,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.visitAreas,
  });

  factory AccountAddressDetailRemoteModel.fromJson(Map<String, dynamic> json) {
    return AccountAddressDetailRemoteModel(
      id: _parseInt(json['id']),
      addressName: _asString(json['address_name']),
      addressType: _asString(json['address_type']),
      pincode: _asString(json['pincode']),
      city: _asString(json['city']),
      state: _asString(json['state']),
      country: _asString(json['country']),
      polygon: _parsePolygonPoints(json['polygon']),
      latitude: _nullableString(json['latitude']),
      longitude: _nullableString(json['longitude']),
      status: _asString(json['status']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      visitAreas:
          (json['VisitAreas'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AccountVisitAreaRemoteModel.fromJson)
              .toList(growable: false),
    );
  }

  AccountAddressDetailModel toDomain() {
    return AccountAddressDetailModel(
      id: id,
      addressName: addressName,
      addressType: addressType,
      pincode: pincode,
      city: city,
      state: state,
      country: country,
      polygon: polygon.map((point) => point.toDomain()).toList(growable: false),
      latitude: latitude,
      longitude: longitude,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      visitAreas: visitAreas.map((area) => area.toDomain()).toList(
        growable: false,
      ),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.toLowerCase() == 'null' ? '' : trimmed;
  }
  return value.toString().trim();
}

String _nullableString(dynamic value) {
  if (value == null) return '';
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.toLowerCase() == 'null' ? '' : trimmed;
  }
  return value.toString().trim();
}

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toLocal();
  }
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

List<AccountPolygonPointRemoteModel> _parsePolygonPoints(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(AccountPolygonPointRemoteModel.fromJson)
      .toList(growable: false);
}
