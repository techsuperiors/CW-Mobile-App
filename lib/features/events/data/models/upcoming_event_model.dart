/// Upcoming Event Model based on API response
class UpcomingEventModel {
  final int? id;
  final String? eventType;
  final String? title;
  final String? description;
  final String? personName;
  final String? date;
  final String? startDate;
  final String? endDate;
  final String? eventDate;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? employee;
  final String? imageUrl;       // add
  final String? profileColor;   // add


  UpcomingEventModel({
    this.id,
    this.eventType,
    this.title,
    this.description,
    this.personName,
    this.date,
    this.startDate,
    this.endDate,
    this.eventDate,
    this.user,
    this.employee,
    this.imageUrl,              // add
    this.profileColor,          // add
  });

  factory UpcomingEventModel.fromJson(Map<String, dynamic> json) {
    // Try to extract person name from various possible structures
    String? personName;
    
    // Check if first_name and last_name are directly in the json (new API structure)
    if (json['first_name'] != null || json['last_name'] != null) {
      final firstName = json['first_name'] as String? ?? '';
      final lastName = json['last_name'] as String? ?? '';
      final parts = <String>[];
      if (firstName.isNotEmpty) parts.add(firstName);
      if (lastName.isNotEmpty) parts.add(lastName);
      personName = parts.isEmpty ? null : parts.join(' ');
    }
    // Try to extract from user or employee object
    else if (json['user'] != null && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      final firstName = user['first_name'] as String?;
      final lastName = user['last_name'] as String?;
      final middleName = user['middle_name'] as String?;
      final parts = <String>[];
      if (firstName != null && firstName.isNotEmpty) parts.add(firstName);
      if (middleName != null && middleName.isNotEmpty) parts.add(middleName);
      if (lastName != null && lastName.isNotEmpty) parts.add(lastName);
      personName = parts.isEmpty ? user['email'] as String? : parts.join(' ');
    } else if (json['employee'] != null && json['employee'] is Map) {
      final employee = json['employee'] as Map<String, dynamic>;
      final firstName = employee['first_name'] as String?;
      final lastName = employee['last_name'] as String?;
      final middleName = employee['middle_name'] as String?;
      final parts = <String>[];
      if (firstName != null && firstName.isNotEmpty) parts.add(firstName);
      if (middleName != null && middleName.isNotEmpty) parts.add(middleName);
      if (lastName != null && lastName.isNotEmpty) parts.add(lastName);
      personName = parts.isEmpty ? employee['email'] as String? : parts.join(' ');
    } else {
      personName = json['person_name'] as String? ?? 
                   json['name'] as String? ?? 
                   json['employee_name'] as String?;
    }

    // Try to extract date from various possible fields
    // New API structure uses birthday_date or joining_date
    String? dateStr = json['birthday_date'] as String? ??
                      json['joining_date'] as String? ??
                      json['date'] as String? ??
                      json['event_date'] as String? ??
                      json['start_date'] as String? ??
                      json['end_date'] as String?;

    // Determine event type from context or explicit field
    String? eventType = json['event_type'] as String? ??
                        json['type'] as String?;
    
    // If event type is not explicit, infer from available fields
    if (eventType == null) {
      if (json['birthday_date'] != null) {
        eventType = 'Birthday';
      } else if (json['joining_date'] != null) {
        eventType = 'Anniversary';
      } else {
        eventType = json['title'] as String?;
      }
    }

    return UpcomingEventModel(
      id: json['user_id'] as int? ?? json['id'] as int?,
      eventType: eventType,
      title: json['title'] as String?,
      description: json['description'] as String?,
      personName: personName,
      date: dateStr,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      eventDate: dateStr,
      user: json['user'] as Map<String, dynamic>?,
      employee: json['employee'] as Map<String, dynamic>?,
      imageUrl: json['image_url'] as String?,        // yeh add karo
      profileColor: json['profile_color'] as String?, // yeh add karo
    );
  }

  /// Get formatted date string
  /// Converts UTC time to local timezone
  String get formattedDate {
    if (date != null && date!.isNotEmpty) {
      try {
        final utcDateTime = DateTime.parse(date!);
        final localDateTime = utcDateTime.toLocal();
        return _formatDate(localDateTime);
      } catch (e) {
        return date!;
      }
    } else if (eventDate != null && eventDate!.isNotEmpty) {
      try {
        final utcDateTime = DateTime.parse(eventDate!);
        final localDateTime = utcDateTime.toLocal();
        return _formatDate(localDateTime);
      } catch (e) {
        return eventDate!;
      }
    } else if (startDate != null && startDate!.isNotEmpty) {
      try {
        final utcDateTime = DateTime.parse(startDate!);
        final localDateTime = utcDateTime.toLocal();
        return _formatDate(localDateTime);
      } catch (e) {
        return startDate!;
      }
    }
    return 'Date TBD';
  }

  String _formatDate(DateTime dateTime) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    return '$weekday, $month ${dateTime.day}';
  }

  /// Get icon based on event type
  String get iconName {
    final type = (eventType ?? title ?? '').toLowerCase();
    if (type.contains('birthday') || type.contains('birth')) {
      return 'cake';
    } else if (type.contains('anniversary') || type.contains('work')) {
      return 'card_giftcard';
    } else if (type.contains('holiday')) {
      return 'celebration';
    }
    return 'event';
  }
}

/// Upcoming Events Response Model
class UpcomingEventsResponse {
  final bool success;
  final String? message;
  final List<UpcomingEventModel>? data;

  UpcomingEventsResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory UpcomingEventsResponse.fromJson(Map<String, dynamic> json) {
    List<UpcomingEventModel> events = [];
    
    // Handle new API structure with upcomingBirthdays and upcomingAnniversaries
    if (json['upcomingBirthdays'] != null && json['upcomingBirthdays'] is List) {
      final birthdays = (json['upcomingBirthdays'] as List)
          .map((item) {
            final eventJson = item as Map<String, dynamic>;
            eventJson['event_type'] = 'Birthday';
            return UpcomingEventModel.fromJson(eventJson);
          })
          .toList();
      events.addAll(birthdays);
    }
    
    if (json['upcomingAnniversaries'] != null && json['upcomingAnniversaries'] is List) {
      final anniversaries = (json['upcomingAnniversaries'] as List)
          .map((item) {
            final eventJson = item as Map<String, dynamic>;
            eventJson['event_type'] = 'Anniversary';
            return UpcomingEventModel.fromJson(eventJson);
          })
          .toList();
      events.addAll(anniversaries);
    }
    
    // Handle old API structure with data array
    if (events.isEmpty && json['data'] != null) {
      if (json['data'] is List) {
        events = (json['data'] as List)
            .map((item) => UpcomingEventModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['data'] is Map && json['data']['events'] != null) {
        events = (json['data']['events'] as List)
            .map((item) => UpcomingEventModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    
    return UpcomingEventsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: events.isNotEmpty ? events : null,
    );
  }
}

