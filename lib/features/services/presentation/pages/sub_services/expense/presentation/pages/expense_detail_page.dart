import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../data/expense_remote_data.dart';
import '../../data/models/expense_detail_model.dart';
import '../../data/models/expense_item_model.dart';

class ExpenseDetailPage extends StatefulWidget {
  final ExpenseItemModel expense;

  const ExpenseDetailPage({super.key, required this.expense});

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late final ExpenseRemoteData _remoteData;
  late Future<ExpenseDetailModel> _detailFuture;
  final Set<int> _expandedIndices = <int>{0};

  @override
  void initState() {
    super.initState();
    _remoteData = ExpenseRemoteData(
      apiClient: ApiClient(
        dio: Dio(),
        networkInfo: NetworkInfoImpl(Connectivity()),
      ),
    );
    _detailFuture = _remoteData.getExpenseDetails(expenseId: widget.expense.id);
  }

  void _reload() {
    setState(() {
      _detailFuture = _remoteData.getExpenseDetails(expenseId: widget.expense.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
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
          'Reimbursement',
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: FutureBuilder<ExpenseDetailModel>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ApiErrorState(
              rawMessage: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final detail = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Column(
              children: [
                _DetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              detail.expenseName,
                              style: AppTextStyles.heading4(context).copyWith(
                                color: AppColors.attendanceTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.more_vert, color: AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _RequestByRow(user: detail.requestUser),
                      const Divider(height: 28),
                      _InfoRow(
                        label: 'Amount',
                        value: NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 0,
                        ).format(detail.amount),
                      ),
                      _InfoRow(
                        label: 'Invoice Number',
                        value: detail.invoiceNumber ?? '—',
                      ),
                      _InfoRow(
                        label: 'Reimbursement Policy Name',
                        value: detail.policy.policyName.isEmpty
                            ? '—'
                            : detail.policy.policyName,
                      ),
                      _InfoRow(
                        label: 'Status',
                        valueWidget: _StatusChip(status: detail.approvalStatus),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Description',
                        style: AppTextStyles.bodyMediumHeading(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (detail.description?.trim().isNotEmpty ?? false)
                            ? detail.description!.trim()
                            : 'No description available.',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(height: 28),
                      Text(
                        'Attachment',
                        style: AppTextStyles.bodyMediumHeading(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (detail.documents.isEmpty)
                        Text(
                          'No attachments',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: detail.documents
                              .map((doc) => _AttachmentTile(document: doc))
                              .toList(),
                        ),
                      const Divider(height: 28),
                      Text(
                        'Levels',
                        style: AppTextStyles.bodyMediumHeading(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configure different components and their respective limits or requirements.',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(
                        detail.approvals.length,
                        (index) => _ApprovalLevelTile(
                          approval: detail.approvals[index],
                          index: index,
                          isExpanded: _expandedIndices.contains(index),
                          onToggle: () {
                            setState(() {
                              if (_expandedIndices.contains(index)) {
                                _expandedIndices.remove(index);
                              } else {
                                _expandedIndices.add(index);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments',
                        style: AppTextStyles.bodyMediumHeading(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: detail.comments?.isNotEmpty == true
                                      ? detail.comments
                                      : 'Add a comment...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.send_outlined,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RequestByRow extends StatelessWidget {
  final ExpenseRequester user;

  const _RequestByRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Request By',
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _Avatar(user: user, size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            user.fullName.isEmpty ? '—' : user.fullName,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.attendanceTeal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: AppTextStyles.bodyMediumHeading(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '—',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF12B76A);
      case 'rejected':
      case 'withdrawn':
        return const Color(0xFFF04438);
      default:
        return const Color(0xFF0086C9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ExpenseDocument document;

  const _AttachmentTile({required this.document});

  bool get _isPdf => document.url.toLowerCase().endsWith('.pdf');

  void _open(BuildContext context) {
    if (_isPdf) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                  height: 50,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PDF Preview', style: TextStyle(color: Colors.white)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SfPdfViewer.network(document.url)),
              ],
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: document.url,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _isPdf
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        document.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                )
              : CachedNetworkImage(
                  imageUrl: document.url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined),
                ),
        ),
      ),
    );
  }
}

class _ApprovalLevelTile extends StatelessWidget {
  final ExpenseApprovalDetail approval;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ApprovalLevelTile({
    required this.approval,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                Icon(Icons.account_circle_outlined, color: AppColors.border, size: 26),
                if (!isExpanded)
                  Container(
                    width: 2,
                    height: 32,
                    color: AppColors.border,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Level ${index + 1}',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          _StatusChip(status: approval.approvalStatus),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFE9EDF2))),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _ApprovalInfoRow(
                            label: 'Approver Name',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Avatar(user: approval.assignee, size: 24),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    approval.assignee.fullName.isEmpty
                                        ? '—'
                                        : approval.assignee.fullName,
                                    style: AppTextStyles.bodyMedium(context).copyWith(
                                      color: AppColors.attendanceTeal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ApprovalInfoRow(
                            label: 'Approve Date',
                            value: approval.actionTakenAt == null
                                ? '—'
                                : DateFormat('dd-MMM-yyyy').format(
                                    approval.actionTakenAt!,
                                  ),
                          ),
                          _ApprovalInfoRow(
                            label: 'Remark',
                            value: (approval.remarks?.trim().isNotEmpty ?? false)
                                ? approval.remarks!.trim()
                                : '—',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalInfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _ApprovalInfoRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodyMediumHeading(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '—',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ExpenseRequester user;
  final double size;

  const _Avatar({required this.user, required this.size});

  Color _parseColor() {
    final raw = user.profileColor?.replaceFirst('#', '');
    if (raw == null || raw.isEmpty) return AppColors.attendanceTeal;
    final normalized = raw.length == 6 ? 'FF$raw' : raw;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF0DC5C1);
  }

  @override
  Widget build(BuildContext context) {
    if (user.imageUrl?.isNotEmpty == true) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.imageUrl!),
      );
    }
    final initials = user.fullName.isEmpty
        ? '?'
        : user.fullName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _parseColor(),
      child: Text(
        initials,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
