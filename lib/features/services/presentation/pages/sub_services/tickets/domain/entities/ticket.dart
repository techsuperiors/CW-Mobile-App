/// Ticket Created By User Entity
class TicketCreatedBy {
  final String? firstName;
  final String? lastName;
  final String? profileColor;
  final String? imageUrl;

  TicketCreatedBy({
    this.firstName,
    this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket Entity
class Ticket {
  final int id;
  final String ticketID;
  final String priority;
  final String subject;
  final String ticketStatus;
  final int ticketCategoryId;
  final int? ticketSubCategoryId;
  final int? pinnedBy;
  final int createdBy;
  final int? raisedFor;
  final String createdAt;
  final String updatedAt;
  final TicketCreatedBy createdByUser;
  final String categoryName;
  final String? subcategoryName;

  Ticket({
    required this.id,
    required this.ticketID,
    required this.priority,
    required this.subject,
    required this.ticketStatus,
    required this.ticketCategoryId,
    this.ticketSubCategoryId,
    this.pinnedBy,
    required this.createdBy,
    this.raisedFor,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUser,
    required this.categoryName,
    this.subcategoryName,
  });
}

/// Ticket List Entity
class TicketList {
  final List<Ticket> tickets;

  TicketList({
    required this.tickets,
  });
}

/// Ticket Document Entity
class TicketDocument {
  final String id;
  final String url;
  final String name;

  TicketDocument({
    required this.id,
    required this.url,
    required this.name,
  });
}

/// Ticket Activity Entity
class TicketActivity {
  final String action;
  final String actionType;
  final String? userEmail;
  final String? firstName;
  final String? lastName;
  final int? createdBy;
  final String createdAt;

  TicketActivity({
    required this.action,
    required this.actionType,
    this.userEmail,
    this.firstName,
    this.lastName,
    this.createdBy,
    required this.createdAt,
  });

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket User Entity (for raised_for, created_by, assigneeTicket, createdBy)
class TicketUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? profileColor;
  final String? imageUrl;
  final String? phone;
  final String? email;

  TicketUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.profileColor,
    this.imageUrl,
    this.phone,
    this.email,
  });

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket Category Entity
class TicketCategory {
  final int id;
  final String categoryName;
  final List<dynamic> followers;
  final List<int> assignee;
  final bool hasSubCategories;

  TicketCategory({
    required this.id,
    required this.categoryName,
    required this.followers,
    required this.assignee,
    required this.hasSubCategories,
  });
}

/// Ticket Follower Entity
class TicketFollower {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? profileColor;
  final String? imageUrl;

  TicketFollower({
    required this.id,
    this.firstName,
    this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'User' : parts.join(' ');
  }
}

/// Ticket Details Entity
class TicketDetails {
  final int id;
  final String subject;
  final String priority;
  final int? assignee;
  final String description;
  final String ticketStatus;
  final List<TicketDocument> documents;
  final List<TicketActivity> activity;
  final int ticketCategoryId;
  final int? ticketSubCategoryId;
  final String ticketID;
  final TicketUser? raisedFor;
  final int createdBy;
  final String createdAt;
  final TicketUser? assigneeTicket;
  final TicketUser? createdByUser;
  final TicketCategory? ticketCategory;
  final dynamic ticketSubCategory; // Can be null
  final List<TicketFollower> followers;

  TicketDetails({
    required this.id,
    required this.subject,
    required this.priority,
    this.assignee,
    required this.description,
    required this.ticketStatus,
    required this.documents,
    required this.activity,
    required this.ticketCategoryId,
    this.ticketSubCategoryId,
    required this.ticketID,
    this.raisedFor,
    required this.createdBy,
    required this.createdAt,
    this.assigneeTicket,
    this.createdByUser,
    this.ticketCategory,
    this.ticketSubCategory,
    required this.followers,
  });
}
