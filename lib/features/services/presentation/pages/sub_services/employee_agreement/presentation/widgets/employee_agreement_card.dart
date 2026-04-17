import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/employee_agreement_model.dart';
import '../pages/employee_agreement_detail_page.dart';
import '../bloc/agreement_bloc.dart';

/// Card widget for displaying employee agreement information
class EmployeeAgreementCard extends StatelessWidget {
  final EmployeeAgreementModel agreement;
  final bool showDocumentsOnly;

  const EmployeeAgreementCard({
    super.key,
    required this.agreement,
    this.showDocumentsOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("Check:- ${agreement.documentUrl}");
    return InkWell(
      onTap: () async {
        // Navigate to agreement detail page when tapped
        // Pass the bloc using BlocProvider.value so the detail page can access it
        final bloc = context.read<AgreementBloc>();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BlocProvider.value(
                  value: bloc,
                  child: EmployeeAgreementDetailPage(
                    agreement: agreement,
                    showDocumentsOnly: showDocumentsOnly,
                  ),
                ),
          ),
        );

        // If consent was submitted successfully, the refresh is already triggered
        // in the detail page, so we don't need to do anything here
        // The BlocBuilder in the list page will automatically update
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.02,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.backgroundLight.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.042,
          ), // ~4.2% of screen width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                agreement.agreementName,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              // Employee Name
              _buildDetailRow(
                context,
                'Employee Name',
                agreement.employeeName,
                agreement.employeeAvatar,
                agreement.employeeProfileColor,
              ),
              Divider(
                color: AppColors.loginInputBorder,
                height:
                    MediaQuery.of(context).size.height *
                    0.03, // 3% total space (1.5% upar, 1.5% niche)
                thickness: 1, // Line ki motai
              ),
              // Agreement Type
              _buildDetailRow(
                context,
                'Agreement Type',
                agreement.agreementType,
                null,
                null,
              ),
              Divider(
                color: AppColors.loginInputBorder,
                height:
                    MediaQuery.of(context).size.height *
                    0.03, // 3% total space (1.5% upar, 1.5% niche)
                thickness: 1, // Line ki motai
              ), // 1.5% of screen height
              // Assigned By
              _buildDetailRow(
                context,
                'Assigned By',
                agreement.assignedBy,
                agreement.assignedByAvatar,
                agreement.assignedByProfileColor,
              ),
              Divider(
                color: AppColors.loginInputBorder,
                height:
                    MediaQuery.of(context).size.height *
                    0.03, // 3% total space (1.5% upar, 1.5% niche)
                thickness: 1, // Line ki motai
              ), // 1.5% of screen height
              // Expiry Date
              _buildDetailRow(
                context,
                'Expiry Date',
                agreement.expiryDate,
                null,
                null,
              ),
              Divider(
                color: AppColors.loginInputBorder,
                height:
                    MediaQuery.of(context).size.height *
                    0.03, // 3% total space (1.5% upar, 1.5% niche)
                thickness: 1, // Line ki motai
              ), // 1.5% of screen height
              // Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    agreement.status,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(
                        agreement.status,
                      ), // Dynamic colors
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'signed':
        return Colors.green; // Ya AppColors.success agar defined hai
      case 'sent':
        return AppColors.warning; // Yellow/Orange color
      case 'revoked':
        return AppColors.error; // Red color
      default:
        return AppColors.textSecondary; // Default color
    }
  }

  Widget _buildDetailRow(
    context,
    String label,
    String value,
    String? avatarPath,
    String? profileColor,
  )
  {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.267, // ~26.7% of screen width
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // ~4.2% of screen width
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (avatarPath != null) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                _buildAvatar(
                  context: context,
                  name: value,
                  avatarPath: avatarPath,
                  radius: smallerDimension * 0.033,
                  profileColor: profileColor,
                ),
              ],
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color:
                      label == 'Employee Name'
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({
    required BuildContext context,
    required String name,
    required String? avatarPath,
    required double radius,
    String? profileColor,
  }) {
    final avatarSize = radius * 2;
    final trimmedAvatarPath = avatarPath?.trim();

    if (trimmedAvatarPath != null && trimmedAvatarPath.startsWith('http')) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: trimmedAvatarPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorWidget:
                (_, __, ___) => _buildAvatarFallback(
                  context,
                  name,
                  radius,
                  profileColor,
                ),
          ),
        ),
      );
    }

    if (trimmedAvatarPath != null && trimmedAvatarPath.isNotEmpty) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ClipOval(
          child: Image.asset(
            trimmedAvatarPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => _buildAvatarFallback(
                  context,
                  name,
                  radius,
                  profileColor,
                ),
          ),
        ),
      );
    }

    return _buildAvatarFallback(context, name, radius, profileColor);
  }

  Widget _buildAvatarFallback(
    BuildContext context,
    String name,
    double radius,
    String? profileColor,
  ) {
    final trimmedName = name.trim();
    final condensedName = trimmedName.replaceAll(RegExp(r'\s+'), '');
    final initials =
        condensedName.isEmpty
            ? ''
            : condensedName.length == 1
            ? condensedName.substring(0, 1).toUpperCase()
            : '${condensedName.substring(0, 1)}${condensedName.substring(condensedName.length - 1)}'
                .toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: _parseProfileColor(profileColor),
      child:
          initials.isEmpty
              ? Icon(
                Icons.person,
                size: radius,
                color: Colors.white,
              )
              : Text(
                initials,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
    );
  }

  Color _parseProfileColor(String? profileColor) {
    final normalized = profileColor?.trim();
    if (normalized == null || normalized.isEmpty) {
      return AppColors.backgroundMediumLight;
    }

    final hex = normalized.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) {
      return AppColors.backgroundMediumLight;
    }

    final buffer = StringBuffer();
    if (hex.length == 6) {
      buffer.write('FF');
    }
    buffer.write(hex);

    final colorValue = int.tryParse(buffer.toString(), radix: 16);
    if (colorValue == null) {
      return AppColors.backgroundMediumLight;
    }

    return Color(colorValue);
  }
}
