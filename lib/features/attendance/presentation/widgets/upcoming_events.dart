import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_section_header.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../events/domain/entities/upcoming_event.dart' as domain;

/// Event data model for widget
class UpcomingEventWidget {
  final String eventType;
  final String personName;
  final String date;
  final IconData celebratoryIcon;

  const UpcomingEventWidget({
    required this.eventType,
    required this.personName,
    required this.date,
    required this.celebratoryIcon,
  });
}

/// Upcoming events widget
class UpcomingEvents extends StatelessWidget {
  final List<domain.UpcomingEvent> events;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  const UpcomingEvents({
    super.key,
    required this.events,
    required this.isLoading,
    this.errorMessage,
    this.onRefresh,
  });

  /// Convert entities to widget models
  List<UpcomingEventWidget> _convertToWidgetEvents(List<domain.UpcomingEvent> eventEntities) {
    return eventEntities.map((entity) {
      return UpcomingEventWidget(
        eventType: entity.eventType,
        personName: entity.personName,
        date: entity.formattedDate,
        celebratoryIcon: _getIconFromName(entity.iconName),
      );
    }).toList();
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'cake':
        return Icons.cake;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard;
      case 'celebration':
        return Icons.celebration;
      case 'event':
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: AppStrings.upcomingEvents),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02, // 2% of screen height
          ),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      errorMessage!,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (onRefresh != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (_convertToWidgetEvents(events).isEmpty)
            Container(
              height: MediaQuery.of(context).size.height * 0.25, // Fixed height for consistency
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No upcoming events',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Container(
              height: MediaQuery.of(context).size.height * 0.3, // Fixed height to show 2-3 events
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemCount: _convertToWidgetEvents(events).length,
                separatorBuilder: (context, index) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
                ),
                itemBuilder: (context, index) {
                  final widgetEvents = _convertToWidgetEvents(events);
                  return _buildEventCard(context, widgetEvents[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, UpcomingEventWidget event) {
    final tealColor = AppColors.serviceTeal;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tealColor,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
      child: Row(
        children: [
          // User icon in square with rounded corners
          Container(
            width: smallerDimension * 0.133, // ~13.3% of smaller dimension
            height: smallerDimension * 0.133,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.textSecondary,
              size: smallerDimension * 0.067, // ~6.7% of smaller dimension
            ),
          ),
          SizedBox(
            width: screenWidth * 0.03, // 3% of screen width
          ),
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event type in teal
                Text(
                  event.eventType,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: tealColor,
                    height: 1.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: screenHeight * 0.005, // 0.5% of screen height
                ),
                // Person name in bold dark gray
                Text(
                  event.personName,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: screenHeight * 0.005, // 0.5% of screen height
                ),
                // Date with clock icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: smallerDimension * 0.039, // ~3.9% of smaller dimension
                      color: tealColor,
                    ),
                    SizedBox(
                      width: screenWidth * 0.01, // 1% of screen width
                    ),
                    Flexible(
                      child: Text(
                        event.date,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: screenWidth * 0.03, // 3% of screen width
          ),
          // Celebratory icon in circular teal background
          Container(
            width: smallerDimension * 0.111, // ~11.1% of smaller dimension
            height: smallerDimension * 0.111,
            decoration: BoxDecoration(
              color: tealColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.celebratoryIcon,
              size: smallerDimension * 0.056, // ~5.6% of smaller dimension
              color: AppColors.attendanceTealDark,
            ),
          ),
        ],
      ),
    );
  }
}

