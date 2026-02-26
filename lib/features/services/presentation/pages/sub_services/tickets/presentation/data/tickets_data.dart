import '../../domain/models/ticket_model.dart';
import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';

/// Tickets data provider - can be replaced with API call
class TicketsData {
  static List<TicketSummary> getTicketSummaries() {
    return [
      TicketSummary(
        type: 'Open Tickets',
        count: 18,
        icon: Icons.description,
        color: AppColors.primary,
      ),
      TicketSummary(
        type: 'In-Progress Tickets',
        count: 4,
        icon: Icons.access_time,
        color: AppColors.warning,
      ),
      TicketSummary(
        type: 'Resolved Tickets',
        count: 10,
        icon: Icons.check_circle,
        color: AppColors.success,
      ),
      TicketSummary(
        type: 'Escalated Tickets',
        count: 4,
        icon: Icons.priority_high,
        color: AppColors.error,
      ),
    ];
  }

  static List<PriorityTicketCount> getPriorityTicketCounts() {
    return [
      PriorityTicketCount(
        priority: 'Critical',
        count: 1,
        color: AppColors.error,
      ),
      PriorityTicketCount(
        priority: 'High',
        count: 4,
        color: AppColors.primary,
      ),
      PriorityTicketCount(
        priority: 'Medium',
        count: 3,
        color: AppColors.warning,
      ),
      PriorityTicketCount(
        priority: 'Low',
        count: 5,
        color: AppColors.success,
      ),
    ];
  }

  static List<TicketModel> getMyTickets() {
    return [
      TicketModel(
        id: 'TKT1-20',
        title: 'Salary Not Credited...',
        fullTitle: 'Salary Not Credited for march 2025',
        category: 'Finance',
        raisedDate: '16/07/2025',
        priority: 'Medium',
        status: 'Open',
        description: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
        raisedBy: 'Riya Rawat',
        raisedByAvatar: null,
        attachments: ['attachment1.jpg'],
      ),
      TicketModel(
        id: 'TKT3-30',
        title: 'Tax Deduction Error...',
        fullTitle: 'Tax Deduction Error in Salary',
        category: 'Finance',
        raisedDate: '17/07/2025',
        priority: 'Medium',
        status: 'Open',
        description: 'Incorrect tax deduction',
        raisedBy: 'Riya Rawat',
        raisedByAvatar: null,
      ),
      TicketModel(
        id: 'TKT2-45',
        title: 'Incorrect Pay Amount...',
        fullTitle: 'Incorrect Pay Amount Credited',
        category: 'Finance',
        raisedDate: '18/07/2025',
        priority: 'Medium',
        status: 'Open',
        description: 'Pay amount is incorrect',
        raisedBy: 'Riya Rawat',
        raisedByAvatar: null,
      ),
    ];
  }

  static List<TicketModel> getAssignedTickets() {
    return [
      TicketModel(
        id: 'TKT4-50',
        title: 'System Access Issue...',
        fullTitle: 'System Access Issue',
        category: 'IT',
        raisedDate: '15/07/2025',
        priority: 'High',
        status: 'In-Progress',
        description: 'Cannot access system',
        raisedBy: 'Riya Rawat',
      ),
      TicketModel(
        id: 'TKT5-60',
        title: 'Password Reset Request...',
        fullTitle: 'Password Reset Request',
        category: 'IT',
        raisedDate: '14/07/2025',
        priority: 'Low',
        status: 'Resolved',
        description: 'Password reset required',
        raisedBy: 'Riya Rawat',
      ),
    ];
  }

  static List<String> getCategories() {
    return ['Finance', 'IT', 'HR', 'Admin', 'All'];
  }
}

