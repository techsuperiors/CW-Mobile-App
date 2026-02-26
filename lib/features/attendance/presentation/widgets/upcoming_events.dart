import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_section_header.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../events/data/datasources/upcoming_events_remote_datasource.dart';
import '../../../events/data/repositories/upcoming_events_repository_impl.dart';
import '../../../events/domain/usecases/get_upcoming_events_usecase.dart';

/// Event data model for widget
class UpcomingEvent {
  final String eventType;
  final String personName;
  final String date;
  final IconData celebratoryIcon;

  const UpcomingEvent({
    required this.eventType,
    required this.personName,
    required this.date,
    required this.celebratoryIcon,
  });
}

/// Upcoming events widget
class UpcomingEvents extends StatefulWidget {
  const UpcomingEvents({super.key});

  @override
  State<UpcomingEvents> createState() => _UpcomingEventsState();
}

class _UpcomingEventsState extends State<UpcomingEvents> {
  List<UpcomingEvent> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize API client and dependencies
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
      final remoteDataSource = UpcomingEventsRemoteDataSourceImpl(apiClient);
      final repository = UpcomingEventsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getUpcomingEventsUseCase = GetUpcomingEventsUseCase(repository);

      // Fetch events from API
      final result = await getUpcomingEventsUseCase();

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (eventEntities) {
          // Convert entities to widget models
          final events = eventEntities.map((entity) {
            return UpcomingEvent(
              eventType: entity.eventType,
              personName: entity.personName,
              date: entity.formattedDate,
              celebratoryIcon: _getIconFromName(entity.iconName),
            );
          }).toList();

          setState(() {
            _events = events;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading events: ${e.toString()}';
        _isLoading = false;
      });
    }
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
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadEvents,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_events.isEmpty)
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
                itemCount: _events.length,
                separatorBuilder: (context, index) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
                ),
                itemBuilder: (context, index) {
                  return _buildEventCard(context, _events[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, UpcomingEvent event) {
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

