import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common/shimmer.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/entities/notification_entity.dart';
import '../Widgets/notification_card.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Ensure notifications are fetched when opening the page
    context.read<NotificationBloc>().add(FetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048, // 4.8% of screen width
              ),
              Flexible(
                child: Text(
                  'Back',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.notification,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const _NotificationShimmerList();
          } else if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load notifications',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                        FetchNotifications(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Text(
                  'No notifications yet',
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(FetchNotifications());
              },
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: state.notifications.length,
                shrinkWrap: true,
                separatorBuilder:
                    (context, index) => SizedBox(height: screenHeight * 0.016),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return NotificationCard(notification: notification);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationShimmerList extends StatelessWidget {
  const _NotificationShimmerList();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 6, // number of shimmer items
      separatorBuilder: (_, __) => SizedBox(height: screenHeight * 0.016),
      itemBuilder: (context, index) {
        return const _NotificationShimmerCard();
      },
    );
  }
}

class _NotificationShimmerCard extends StatelessWidget {
  const _NotificationShimmerCard();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar shimmer
          AppShimmer.circular(width: screenWidth * 0.1, height: 40),

          SizedBox(width: screenWidth * 0.02),

          // Text shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer.rectangular(
                  height: screenHeight * 0.04,
                  width: double.infinity,
                ),
                SizedBox(height: screenHeight * 0.008),
                AppShimmer.rectangular(
                  height: screenHeight * 0.0088,
                  width: double.infinity,
                ),
                SizedBox(height: screenHeight * 0.008),
                AppShimmer.rectangular(
                  height: screenHeight * 0.008,
                  width: screenWidth * 0.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
