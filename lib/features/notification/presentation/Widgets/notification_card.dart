import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';

class NotificationCard extends StatefulWidget {
  final NotificationEntity notification;

  const NotificationCard({Key? key, required this.notification})
    : super(key: key);

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded(BuildContext context) {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        if (!widget.notification.isRead) {
          context.read<NotificationBloc>().add(
            ReadSingleNotification(widget.notification.id),
          );
        }
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !widget.notification.isRead;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(widget.notification.createdAt);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.016,
        horizontal: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color:
            isUnread
                ? AppColors.attendanceTeal.withOpacity(0.05)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? AppColors.attendanceTeal : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image or Initials Logic
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.006),
            child: CircleAvatar(
              backgroundColor: Color(
                int.parse(
                  widget.notification.sentByNotifications.profileColor
                      .replaceAll('#', '0xff'),
                ),
              ).withOpacity(0.1),
              backgroundImage:
                  (widget.notification.sentByNotifications.imageUrl != null &&
                          widget
                              .notification
                              .sentByNotifications
                              .imageUrl!
                              .isNotEmpty)
                      ? NetworkImage(
                        widget.notification.sentByNotifications.imageUrl!,
                      )
                      : null,
              child:
                  (widget.notification.sentByNotifications.imageUrl == null ||
                          widget
                              .notification
                              .sentByNotifications
                              .imageUrl!
                              .isEmpty)
                      ? Text(
                        widget.notification.sentByNotifications.firstName[0]
                            .toUpperCase(),
                        style: TextStyle(
                          color: Color(
                            int.parse(
                              widget
                                  .notification
                                  .sentByNotifications
                                  .profileColor
                                  .replaceAll('#', '0xff'),
                            ),
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          ),

          SizedBox(width: screenWidth * 0.03),

          // 2. Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with unread dot + down arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.notification.title,
                        style: AppTextStyles.bodyMediumHeading(
                          context,
                        ).copyWith(
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Unread indicator dot
                        if (isUnread)
                          GestureDetector(
                            onTap: () {
                              context.read<NotificationBloc>().add(
                                ReadSingleNotification(widget.notification.id),
                              );
                            },
                            child: Container(
                              height: MediaQuery.sizeOf(context).height * 0.06,
                              width: MediaQuery.sizeOf(context).height * 0.06,
                              padding: EdgeInsets.all(
                                MediaQuery.sizeOf(context).width * 0.01,
                              ),
                              child: Image.asset(
                                AppAssets.iconnotificationteal,
                              ),
                            ),
                          ),

                        if (isUnread) SizedBox(width: screenWidth * 0.015),

                        // Animated down arrow toggle
                        GestureDetector(
                          onTap: () => _toggleExpanded(context),
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color:
                                  isUnread
                                      ? AppColors.attendanceTeal
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Full message — only shown when expanded
                if (_isExpanded)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Html(
                      data: widget.notification.message,
                      style: {
                        "body": Style(
                          fontSize: FontSize(13),
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          color:
                              isUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                        "b": Style(fontWeight: FontWeight.bold),
                        "strong": Style(fontWeight: FontWeight.bold),
                      },
                    ),
                  ),

                SizedBox(height: screenHeight * 0.005),
                Text(
                  formattedDate,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
