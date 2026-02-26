import 'package:flutter/material.dart';

/// Ticket model
class TicketModel {
  final String id;
  final String title;
  final String fullTitle;
  final String category;
  final String raisedDate;
  final String priority;
  final String status;
  final String? description;
  final String? raisedBy;
  final String? raisedByAvatar;
  final List<String>? attachments;

  TicketModel({
    required this.id,
    required this.title,
    required this.fullTitle,
    required this.category,
    required this.raisedDate,
    required this.priority,
    required this.status,
    this.description,
    this.raisedBy,
    this.raisedByAvatar,
    this.attachments,
  });
}

/// Ticket summary model
class TicketSummary {
  final String type;
  final int count;
  final IconData icon;
  final Color color;

  TicketSummary({
    required this.type,
    required this.count,
    required this.icon,
    required this.color,
  });
}

/// Priority ticket count model
class PriorityTicketCount {
  final String priority;
  final int count;
  final Color color;

  PriorityTicketCount({
    required this.priority,
    required this.count,
    required this.color,
  });
}

