import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../models/regularize_request_model.dart';
import '../../../leaves/presentation/widgets/activity_section.dart';
import '../../../leaves/presentation/widgets/approvers_section.dart';
import 'apply_regularize_page.dart';

/// Regularize detail page showing full information about a regularize request
class RegularizeDetailPage extends StatefulWidget {
  final RegularizeRequestModel regularizeRequest;

  const RegularizeDetailPage({
    super.key,
    required this.regularizeRequest,
  });

  @override
  State<RegularizeDetailPage> createState() => _RegularizeDetailPageState();
}

class _RegularizeDetailPageState extends State<RegularizeDetailPage> {
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
          'Regularize',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplyRegularizePage(
                      regularizeRequest: widget.regularizeRequest,
                    ),
                  ),
                );
              } else if (value == 'Withdraw') {
                // Handle withdraw
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
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Request is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: _buildDetailsContent(context, screenWidth, screenHeight),
    );
  }

  Widget _buildDetailsContent(BuildContext context, double screenWidth, double screenHeight) {
    final statusColor = _getStatusColor(widget.regularizeRequest.status);
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final dateTimeFormat = DateFormat('dd-MMM-yyyy HH:mm');
    
    // Calculate number of days
    final numberOfDays = widget.regularizeRequest.toDate != null
        ? widget.regularizeRequest.toDate!.difference(widget.regularizeRequest.fromDate).inDays + 1
        : 1;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.022),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Card with green left border
          Container(
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
            clipBehavior: Clip.none,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Colored left border
                  Container(
                    width: screenWidth * 0.032, // 3.2% of screen width
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.042),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.regularizeRequest.reason,
                              style: AppTextStyles.heading4(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: statusColor, // Green color for title
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // Regularize Details Card
          _buildDetailsCard(
            context,
            screenWidth,
            screenHeight,
            statusColor,
            dateFormat,
            dateTimeFormat,
            numberOfDays,
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
    Color statusColor,
    DateFormat dateFormat,
    DateFormat dateTimeFormat,
    int numberOfDays,
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
            widget.regularizeRequest.reason,
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Request Type:',
            widget.regularizeRequest.toDate == null ? 'Single Day' : 'Multiple Days',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Request For:',
            widget.regularizeRequest.requestType.displayName,
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
            dateFormat.format(widget.regularizeRequest.fromDate),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'To:',
            widget.regularizeRequest.toDate != null
                ? dateFormat.format(widget.regularizeRequest.toDate!)
                : dateFormat.format(widget.regularizeRequest.fromDate),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  widget.regularizeRequest.status.displayName,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
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
      width: double.infinity,
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
            widget.regularizeRequest.reason,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
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

  Color _getStatusColor(RegularizeStatus status) {
    switch (status) {
      case RegularizeStatus.pending:
        return const Color(0xFF2196F3); // Blue
      case RegularizeStatus.approved:
        return const Color(0xFF4CAF50); // Green
      case RegularizeStatus.rejected:
        return const Color(0xFFE53935); // Red
    }
  }
}
