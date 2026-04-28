import 'package:collectivWork/core/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../../../core/widgets/common/app_card.dart';
import '../../../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/account_model.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class CustomerDetailsPage extends StatefulWidget {
  final int customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountBloc>().add(LoadAccountCustomerDetails(widget.customerId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                size: AppTextStyles.bodyMedium(context).fontSize,
              ),
              Flexible(
                child: Text(
                  'Back',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          'Customer Details',
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          final detail = state.customerDetail;
          final isCurrentDetail = detail != null && detail.id == widget.customerId;

          if (state.isCustomerDetailLoading && !isCurrentDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.customerDetailError != null && !isCurrentDetail) {
            return ApiErrorState(
              title: 'Unable to load customer details',
              rawMessage: state.customerDetailError,
              onRetry:
                  () => context.read<AccountBloc>().add(
                    LoadAccountCustomerDetails(
                      widget.customerId,
                      forceRefresh: true,
                    ),
                  ),
            );
          }

          if (!isCurrentDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AccountBloc>().add(
                LoadAccountCustomerDetails(
                  widget.customerId,
                  forceRefresh: true,
                ),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, detail),
                  AppSpacing.vLg,
                  if (detail.addresses.isNotEmpty) ...[
                    Text(
                      'Addresses',
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.vSm,
                    ...detail.addresses.map(
                      (address) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _AddressCard(address: address),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    AccountCustomerDetailModel detail,
  ) {
    final primaryAddress = detail.primaryAddress;
    final primaryContact = detail.primaryContact;
    final statusColor = _statusColor(detail.status);

    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context, detail),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.customerName.trim().isEmpty
                          ? '--'
                          : detail.customerName.trim(),
                      style: AppTextStyles.heading4(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vXs,
                    Text(
                      detail.customerCode.trim().isEmpty
                          ? '--'
                          : detail.customerCode.trim(),
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: detail.status, color: statusColor),
            ],
          ),
          AppSpacing.vLg,
          _InfoRow(label: 'Customer Code', value: detail.customerCode),
          _buildDivider(),
          _InfoRow(
            label: 'Created At',
            value: _formatDetailDate(detail.createdAt),
          ),
          _buildDivider(),
          _InfoRow(
            label: 'Location',
            value: primaryAddress?.subtitleLabel ?? '--',
          ),
          _buildDivider(),
          _InfoRow(
            label: 'Contact Person',
            value: _contactSummary(primaryContact),
            maxLines: 3,
          ),
          _buildDivider(),
          _InfoRow(label: 'Customer Type', value: detail.customerType),
          _buildDivider(),
          _InfoRow(label: 'Business Domain', value: detail.businessDomain),
          _buildDivider(),
          Text(
            'Purpose',
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vSm,
          Text(
            detail.description.trim().isEmpty ? '--' : detail.description.trim(),
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    AccountCustomerDetailModel detail,
  ) {
    final background = _parseHexColor(
      detail.createdBy?.profileColor,
      AppColors.primary.withValues(alpha: 0.12),
    );
    final initials = _initials(detail.customerName);

    return Container(
      width: AppSpacing.section,
      height: AppSpacing.section,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.bodyMediumHeading(
          context,
        ).copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border.withValues(alpha: 0.7),
      ),
    );
  }

  String _initials(String value) {
    final parts =
        value
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList(growable: false);
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _contactSummary(AccountContactModel? contact) {
    if (contact == null) return '--';
    final parts = <String>[
      if (contact.name.trim().isNotEmpty) contact.name.trim(),
      if (contact.email.trim().isNotEmpty) contact.email.trim(),
    ];
    final value = parts.join('\n');
    return value.isEmpty ? '--' : value;
  }

  String _formatDetailDate(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('dd-MMM-yyyy').format(value);
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.serviceOrangeDark;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _parseHexColor(String? value, Color fallback) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return fallback;
    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    if (normalized.length != 6) return fallback;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return fallback;
    return Color(0xFF000000 | parsed);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w500,color: AppColors.textPrimary),
          ),
        ),
        AppSpacing.hMd,
        Expanded(
          child: Text(
            value.trim().isEmpty ? '--' : value.trim(),
            maxLines: maxLines,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatefulWidget {
  final AccountCustomerDetailAddressModel address;

  const _AddressCard({required this.address});

  @override
  State<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<_AddressCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final primaryContact = widget.address.primaryContact;
    final typeLabel = widget.address.type.trim().isEmpty
        ? '--'
        : widget.address.type.trim().replaceAll('_', ' ');

    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address.titleLabel,
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vXs,
                    Text(
                      widget.address.subtitleLabel,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              AppSpacing.hSm,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.serviceBlueBg,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: Text(
                  _titleCase(typeLabel),
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(color: AppColors.primary),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            AppSpacing.vMd,
            _AddressMetaRow(
              leftLabel: 'City',
              leftValue: widget.address.city,
              rightLabel: 'Pin',
              rightValue: widget.address.pincode,
            ),
            if (primaryContact != null) ...[
              AppSpacing.vMd,
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPaddingSmall,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Point Of Contact',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    AppSpacing.vSm,
                    Text(
                      primaryContact.name.trim().isEmpty
                          ? '--'
                          : primaryContact.name.trim(),
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (primaryContact.phone.trim().isNotEmpty) ...[
                      AppSpacing.vXs,
                      Text(
                        primaryContact.phone.trim(),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.primary),
                      ),
                    ],
                    if (primaryContact.email.trim().isNotEmpty) ...[
                      AppSpacing.vXs,
                      Text(
                        primaryContact.email.trim(),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '--';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((segment) {
          final lower = segment.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}

class _AddressMetaRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _AddressMetaRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$leftLabel : ',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: leftValue.trim().isEmpty ? '--' : leftValue.trim(),
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.hMd,
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$rightLabel : ',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: rightValue.trim().isEmpty ? '--' : rightValue.trim(),
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        _normalizedStatusLabel(label),
        style: AppTextStyles.bodySmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _normalizedStatusLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '--';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }
}
