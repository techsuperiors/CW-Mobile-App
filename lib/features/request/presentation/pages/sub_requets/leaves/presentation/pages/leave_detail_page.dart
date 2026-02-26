import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import 'apply_leave_page.dart';
import '../../models/leave_request_model.dart';
import '../widgets/activity_section.dart';
import '../widgets/approvers_section.dart';

/// Leave detail page showing full information about a leave request
class LeaveDetailPage extends StatefulWidget {
  final LeaveRequestModel leaveRequest;

  const LeaveDetailPage({
    super.key,
    required this.leaveRequest,
  });

  @override
  State<LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate number of days
    final numberOfDays = widget.leaveRequest.toDate != null
        ? widget.leaveRequest.toDate!.difference(widget.leaveRequest.fromDate).inDays + 1
        : 1;

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
                  'Back',
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
          widget.leaveRequest.leaveType,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textPrimary,
            ),
            onSelected: (value) {
              if (value == 'Edit') {
                // Navigate to apply leave page with pre-filled data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplyLeavePage(
                      leaveRequest: widget.leaveRequest,
                    ),
                  ),
                );
              } else if (value == 'Withdraw') {
                // Handle withdraw
              } else if (value == 'Activity') {
                _showActivityBottomSheet(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'Withdraw',
                child: Text('Withdraw'),
              ),
              const PopupMenuItem(
                value: 'Activity',
                child: Text('Activity'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Request is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: _buildDetailsContent(context, screenWidth, screenHeight, numberOfDays),
    );
  }

  Widget _buildDetailsContent(BuildContext context, double screenWidth, double screenHeight, int numberOfDays) {
    final statusColor = _getStatusColor(widget.leaveRequest.status);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.022),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave Details Card
          _buildDetailsCard(
            context,
            screenWidth,
            screenHeight,
            numberOfDays,
            statusColor,
            dateFormat,
            dateTimeFormat,
          ),
          SizedBox(height: screenHeight * 0.02),
          // Description Section
          _buildDescriptionSection(context, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.02),
          // Comments Section
          _buildCommentsSection(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    int numberOfDays,
    Color statusColor,
    DateFormat dateFormat,
    DateFormat dateTimeFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            'Leave Type:',
            'Emergency Leave (EL)',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Request Type:',
            widget.leaveRequest.toDate == null ? 'Single Day' : 'Multiple Days',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRowWithAvatar(
            context,
            'Request To:',
            'Riya Rawat',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'No. of Days:',
            numberOfDays.toString().padLeft(2, '0'),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'From:',
            dateFormat.format(widget.leaveRequest.fromDate),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'To:',
            widget.leaveRequest.toDate != null
                ? dateFormat.format(widget.leaveRequest.toDate!)
                : dateFormat.format(widget.leaveRequest.fromDate),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Last Updated At:',
            dateTimeFormat.format(DateTime.now()),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRowWithAvatar(
            context,
            'Last Updated By:',
            'Priya Rawat',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: screenWidth * 0.3,
                child: Text(
                  'Status:',
                  style: AppTextStyles.bodyMediumHeading(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showApproversBottomSheet(context);
                      },
                      child: Icon(
                        Icons.info_outline,
                        size: screenWidth * 0.042,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.016),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.032,
                        vertical: screenHeight * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.leaveRequest.status.displayName,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    double screenWidth,
    double screenHeight,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: screenWidth * 0.3,
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textHeading,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithAvatar(
    BuildContext context,
    String label,
    String value,
    double screenWidth,
    double screenHeight,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: screenWidth * 0.3,
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textHeading,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: screenWidth * 0.032,
                backgroundColor: AppColors.primary,
                child: Text(
                  value.split(' ').map((n) => n[0]).take(2).join(),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.021),
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.heading5(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Text(
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Text(
            'Attachments',
            style: AppTextStyles.heading5(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            children: [
              Container(
                width: screenWidth * 0.16,
                height: screenWidth * 0.16,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: screenWidth * 0.032),
              Expanded(
                child: Container(
                  height: screenWidth * 0.16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Handle file upload
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload,
                            size: screenWidth * 0.042,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: screenHeight * 0.006),
                          Text(
                            'Upload File',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCommentsSection(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: AppTextStyles.heading5(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.032,
                vertical: screenHeight * 0.015,
              ),
            ),
            maxLines: 3,
            style: AppTextStyles.bodyMedium(context),
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
    );
  }

  void _showActivityBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5, // Start at half screen
        minChildSize: 0.3, // Minimum 30% of screen
        maxChildSize: 0.9, // Maximum 90% of screen (can be dragged up)
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ActivitySection(scrollController: scrollController),
        ),
      ),
    );
  }

  void _showApproversBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5, // Start at half screen
        minChildSize: 0.3, // Minimum 30% of screen
        maxChildSize: 0.9, // Maximum 90% of screen (can be dragged up)
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ApproversSection(scrollController: scrollController),
        ),
      ),
    );
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return const Color(0xFF2196F3); // Blue
      case LeaveStatus.approved:
        return const Color(0xFF4CAF50); // Green
      case LeaveStatus.rejected:
        return const Color(0xFFE53935); // Red
    }
  }
}
