import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../domain/models/employee_directory_model.dart';
import '../bloc/employee_directory_bloc.dart';
import '../bloc/employee_directory_event.dart';
import '../bloc/employee_directory_state.dart';
import 'employee_directory_card.dart';

class EmployeeDirectoryDetailDialog extends StatelessWidget {
  final EmployeeDirectoryModel employee;

  const EmployeeDirectoryDetailDialog({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          color: AppColors.background,
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child:
                    BlocBuilder<EmployeeDirectoryBloc, EmployeeDirectoryState>(
                      builder: (context, state) {
                        final detail =
                            state.employeeDetailsByUserId[employee.userId];
                        final isLoading = state.loadingEmployeeDetailUserIds
                            .contains(employee.userId);
                        final shouldShowError =
                            state.selectedEmployeeDetailUserId ==
                                employee.userId &&
                            state.employeeDetailError != null &&
                            detail == null;

                        if (shouldShowError) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: ApiErrorState(
                              rawMessage: state.employeeDetailError,
                              title: 'Unable to load employee details',
                              onRetry:
                                  () =>
                                      context.read<EmployeeDirectoryBloc>().add(
                                        LoadEmployeeDirectoryDetail(
                                          userId: employee.userId,
                                          forceRefresh: true,
                                        ),
                                      ),
                            ),
                          );
                        }

                        if (detail == null || isLoading) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  AppSpacing.vLg,
                                  Text(
                                    'Loading employee details...',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyMedium(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return _buildContent(context, detail);
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Employee Details',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EmployeeDirectoryDetailModel detail,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmployeeDirectoryAvatar(
                    name: detail.fullName,
                    imageUrl: detail.imageUrl,
                    profileColor: detail.profileColor,
                    radius: AppSpacing.xxl + AppSpacing.xs,
                  ),
                  AppSpacing.vSm,
                  SizedBox(
                    width: AppSpacing.sectionLarge * 2,
                    child: Column(
                      children: [
                        Text(
                          detail.fullName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMediumHeading(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        AppSpacing.vXxs,
                        Text(
                          detail.employeeCodeLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMediumHeading(
                            context,
                          ).copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  width: 1,
                  height: AppSpacing.sectionLarge * 2,
                  color: AppColors.border,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.email_outlined,
                      iconColor: AppColors.info,
                      value: detail.email.trim().isEmpty ? '--' : detail.email,
                      svgpath: AppAssets.email_Icon,
                    ),
                    AppSpacing.vSm,
                    _buildInfoRow(
                      context,
                      icon: Icons.female_outlined,
                      iconColor: AppColors.serviceOrangeDark,
                      value: detail.genderLabel,
                      svgpath: AppAssets.gender_Icon,
                    ),
                    AppSpacing.vSm,
                    _buildInfoRow(
                      context,
                      icon: Icons.account_tree_outlined,
                      iconColor: AppColors.serviceOrange,
                      value: detail.departmentLabel,
                      svgpath: AppAssets.department_Icon,
                    ),
                    AppSpacing.vSm,
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.error,
                      value: detail.locationLabel,
                      svgpath: AppAssets.location_Icon,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vLg,
          if (detail.reportingManager != null)
            _buildSectionCard(
              context,
              title: 'Reports To',
              backgroundColor: AppColors.serviceBlueBg,
              people: [detail.reportingManager!],
            ),
          if (detail.reportingManager != null) AppSpacing.vSm,
          if (detail.reportingHr != null)
            _buildSectionCard(
              context,
              title: 'HR Manager',
              backgroundColor: AppColors.servicePinkDarkBg,
              people: [detail.reportingHr!],
            ),
          if (detail.reportingHr != null)  AppSpacing.vSm,
          if (detail.l2Manager != null)
            _buildSectionCard(
              context,
              title: 'L2 Manager',
              backgroundColor: AppColors.serviceOrangeBg,
              people: [detail.l2Manager!],
            ),
          if (detail.l2Manager != null) AppSpacing.vSm,
          if (detail.associateManagers.isNotEmpty)
            _buildSectionCard(
              context,
              title: 'Associate Manager',
              backgroundColor: AppColors.servicePurpleBg,
              people: detail.associateManagers,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String svgpath,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: AppSpacing.iconSmallHeight,
          width: AppSpacing.iconSmallWidth,
          child: SvgPicture.asset(svgpath),
        ),
        AppSpacing.hSm,
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Color backgroundColor,
    required List<EmployeeDirectoryPersonModel> people,
  }) {
    final gradientColors = _sectionGradientColors(backgroundColor);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            gradientColors[0],
            gradientColors[1],
            gradientColors[2],
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.vMd,
          ...List.generate(people.length, (index) {
            final person = people[index];
            final isLast = index == people.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmployeeDirectoryAvatar(
                    name: person.fullName,
                    imageUrl: person.imageUrl,
                    profileColor: person.profileColor,
                    radius: AppSpacing.xl,
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMediumHeading(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        AppSpacing.vXxs,
                        Text(
                          person.secondaryLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _sectionGradientColors(Color baseColor) {
    return [
      _lighten(baseColor, 0.07),
      _lighten(baseColor, 0.08),
      baseColor,
    ];
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
