/// Upcoming Event Entity
class UpcomingEvent {
  final int? id;
  final String eventType;
  final String personName;
  final String date;
  final String formattedDate;
  final String iconName;
  final String? imageUrl;
  final String? profileColor;

  UpcomingEvent({
    this.id,
    required this.eventType,
    required this.personName,
    required this.date,
    required this.formattedDate,
    required this.iconName,
    this.imageUrl,
    this.profileColor
  });
}

