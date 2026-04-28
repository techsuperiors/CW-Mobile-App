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

class AddressDetailsPage extends StatefulWidget {
  final int addressId;

  const AddressDetailsPage({super.key, required this.addressId});

  @override
  State<AddressDetailsPage> createState() => _AddressDetailsPageState();
}

class _AddressDetailsPageState extends State<AddressDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountBloc>().add(LoadAccountAddressDetails(widget.addressId));
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
          'Address Details',
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
          final detail = state.addressDetail;
          final isCurrentDetail = detail != null && detail.id == widget.addressId;

          if (state.isAddressDetailLoading && !isCurrentDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.addressDetailError != null && !isCurrentDetail) {
            return ApiErrorState(
              title: 'Unable to load address details',
              rawMessage: state.addressDetailError,
              onRetry:
                  () => context.read<AccountBloc>().add(
                    LoadAccountAddressDetails(
                      widget.addressId,
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
                LoadAccountAddressDetails(
                  widget.addressId,
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
                  if (detail.visitAreas.isNotEmpty) ...[
                    AppSpacing.vLg,
                    Text(
                      'Visit Areas',
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.vSm,
                    ...detail.visitAreas.map(
                      (area) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _VisitAreaCard(area: area),
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
    AccountAddressDetailModel detail,
  ) {
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
              Expanded(
                child: Text(
                  detail.titleLabel,
                  style: AppTextStyles.heading4(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              AppSpacing.hSm,
              _StatusChip(label: detail.status, color: statusColor),
            ],
          ),
          AppSpacing.vLg,
          _InfoRow(label: 'Address Type', value: detail.addressType),
          _buildDivider(),
          _InfoRow(
            label: 'Created At',
            value: _formatDetailDate(detail.createdAt),
          ),
          _buildDivider(),
          _InfoRow(label: 'Location', value: detail.locationLabel, maxLines: 3),
          _buildDivider(),
          _InfoRow(label: 'Pincode', value: detail.pincode),
          _buildDivider(),
          _InfoRow(label: 'Coordinates', value: detail.coordinatesLabel),
        ],
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
}

class _VisitAreaCard extends StatelessWidget {
  final AccountVisitAreaModel area;

  const _VisitAreaCard({required this.area});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(area.status);

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
                child: Text(
                  area.areaName.trim().isEmpty ? '--' : area.areaName.trim(),
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              AppSpacing.hSm,
              _StatusChip(label: area.status, color: statusColor),
            ],
          ),
          if (area.description.trim().isNotEmpty) ...[
            AppSpacing.vSm,
            Text(
              area.description.trim(),
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
          AppSpacing.vMd,
          _InfoRow(
            label: 'Created At',
            value: _formatDate(area.createdAt),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--';
    return DateFormat('dd MMM, yyyy').format(value);
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
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ),
        AppSpacing.hMd,
        Expanded(
          child: Text(
            value.trim().isEmpty ? '--' : value.trim(),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w500),
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
