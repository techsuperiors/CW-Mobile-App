import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/ticket_model.dart';

/// Ticket detail page
class TicketDetailPage extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailPage({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.primary;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.primary;
      case 'in-progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'escalated':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.tickets,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
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
          widget.ticket.id,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.042),
            child: Text(
              widget.ticket.id,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
      body: Column(
        children: [
          // Divider after AppBar
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
            child: CustomPaint(
              painter: DashedLinePainter(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.042),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Ticket Details Card
            Container(
              padding: EdgeInsets.all(screenWidth * 0.042),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.ticket.fullTitle,
                          style: AppTextStyles.heading4(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: screenWidth * 0.05,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          // Handle menu
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Raised By
                  _buildDetailRow(
                    context,
                    'Raised By',
                    widget.ticket.raisedBy ?? 'N/A',
                    showAvatar: true,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  // Ticket Category
                  _buildDetailRow(
                    context,
                    'Ticket Category',
                    widget.ticket.category,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  // Raised Date
                  _buildDetailRow(
                    context,
                    'Raised Date',
                    widget.ticket.raisedDate,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  // Priority
                  Row(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.3,
                        child: Text(
                          'Priority',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: screenWidth * 0.03,
                              height: 2,
                              color: _getPriorityColor(widget.ticket.priority),
                            ),
                            SizedBox(width: screenWidth * 0.015),
                            Text(
                              widget.ticket.priority,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: _getPriorityColor(widget.ticket.priority),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  // Status
                  _buildDetailRow(
                    context,
                    'Status',
                    widget.ticket.status,
                    statusColor: _getStatusColor(widget.ticket.status),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Description
                  Text(
                    'Description',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    widget.ticket.description ??
                        'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (widget.ticket.attachments != null &&
                      widget.ticket.attachments!.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.02),
                    // Attachments
                    Row(
                      children: [
                        // Existing attachment thumbnail
                        Container(
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              AppAssets.placeholderEvent,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image,
                                  size: screenWidth * 0.1,
                                  color: AppColors.textSecondary,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        // Upload button
                        GestureDetector(
                          onTap: () {
                            // Handle file upload
                          },
                          child: Container(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload,
                                  size: screenWidth * 0.06,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  'Upload File',
                                  style: AppTextStyles.labelSmall(context).copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(height: screenHeight * 0.02),
                    // Upload button only
                    GestureDetector(
                      onTap: () {
                        // Handle file upload
                      },
                      child: Container(
                        width: screenWidth * 0.25,
                        height: screenWidth * 0.25,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload,
                              size: screenWidth * 0.06,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              'Upload File',
                              style: AppTextStyles.labelSmall(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Comments Card
            Container(
              padding: EdgeInsets.all(screenWidth * 0.042),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comments',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          // Handle submit comment
                          _commentController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Comment submitted'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Submit',
                        style: AppTextStyles.buttonLarge(context).copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool showAvatar = false,
    Color? statusColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.3,
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showAvatar) ...[
                CircleAvatar(
                  radius: screenWidth * 0.04,
                  backgroundColor: AppColors.backgroundLight,
                  child: Icon(
                    Icons.person,
                    size: screenWidth * 0.04,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
              ],
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: statusColor ?? AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

