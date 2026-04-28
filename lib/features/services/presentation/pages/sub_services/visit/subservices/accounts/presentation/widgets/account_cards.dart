import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/widgets/common/app_card.dart';
import '../../domain/models/account_model.dart';

class AccountCustomerCard extends StatelessWidget {
  final AccountCustomerModel customer;
  final VoidCallback? onTap;

  const AccountCustomerCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(customer.status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border(
          left: BorderSide(color: statusColor, width: AppSpacing.xs),
        ),
      ),
      child: AppCard(
        onTap: onTap,
        borderRadius: AppSpacing.lg,
        elevation: 1,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    customer.titleLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                AppSpacing.hSm,
                _StatusChip(label: customer.status, color: statusColor),
              ],
            ),
            AppSpacing.vSm,
            _DetailLine(
              label: 'Business Domain : ',
              value: customer.businessDomainLabel,
            ),
            AppSpacing.vXs,
            _DetailLine(
              label: 'Created Date ',
              value: _formatDate(customer.createdAt),
            ),
          ],
        ),
      ),
    );
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
}



class AccountAddressCard extends StatelessWidget {
  final AccountAddressModel address;
  final VoidCallback? onTap;

  const AccountAddressCard({super.key, required this.address, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: AppSpacing.xs),
        ),
      ),
      child: AppCard(
        onTap: onTap,
        borderRadius: AppSpacing.lg,
        elevation: 1,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address.titleLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.vSm,
            _DetailLine(label: 'Location : ', value: address.locationLabel),
            AppSpacing.vXs,
            _DetailLine(
              label: 'Pincode : ',
              value: address.pincode.trim().isEmpty ? '--' : address.pincode,
            ),
            AppSpacing.vXs,
            _DetailLine(
              label: 'Created Date ',
              value: _formatDate(address.createdAt),
            ),
          ],
        ),
      ),
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
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Text(
        _normalizedStatusLabel(label),
        style: AppTextStyles.labelSmall(
          context,
        ).copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _normalizedStatusLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '--';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.bodySmall(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: baseStyle.copyWith(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value.trim().isEmpty ? '--' : value,
            style: baseStyle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      softWrap: true,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}
String _formatDate(DateTime? value) {
  if (value == null) return '--';
  return DateFormat('dd MMM, yyyy').format(value);
}
