import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/ticket_model.dart';
import '../pages/ticket_detail_page.dart';

/// Ticket card widget
class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onRefresh;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onRefresh,
  });

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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailPage(ticketId: ticket.ticketId),
          ),
        );
        // If result is true, it means file was uploaded and we should refresh
        if (result == true && context.mounted && onRefresh != null) {
          onRefresh!();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
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
                  '${ticket.id} ${ticket.title}',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          // Ticket Category
          _buildDetailRow(
            context,
            'Ticket Category',
            ticket.category,
          ),
          SizedBox(height: screenHeight * 0.01),
          // Raised Date
          _buildDetailRow(
            context,
            'Raised Date',
            ticket.raisedDate,
          ),
          SizedBox(height: screenHeight * 0.01),
          // Priority and Status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Priority: ',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(ticket.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _capitalizeFirst(ticket.priority),
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: _getPriorityColor(ticket.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.025,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.status,
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: _getStatusColor(ticket.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

