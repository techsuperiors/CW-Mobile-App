import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/utils/app_spacing.dart';

class ReportPostDialog extends StatefulWidget {
  const ReportPostDialog({super.key});

  @override
  State<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<ReportPostDialog> {
  static const String _otherReason = 'Other';
  static const List<String> _reportReasons = [
    "I just don't like it",
    'Bullying or unwanted contact',
    'Violence, hate or exploitation',
    'Promoting restricted items',
    'Scam, fraud or spam',
    'False information',
    _otherReason,
  ];

  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  bool get _isOtherSelected => _selectedReason == _otherReason;

  bool get _canSubmit {
    if (_selectedReason == null) {
      return false;
    }

    if (_isOtherSelected) {
      return _otherReasonController.text.trim().isNotEmpty;
    }

    return true;
  }

  String get _resolvedReason =>
      _isOtherSelected
          ? _otherReasonController.text.trim()
          : (_selectedReason ?? '').trim();

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width > 900 ? 920.0 : 720.0;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: AppSpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppSpacing.section,
                    height: AppSpacing.section,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FF),
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    child: const Icon(
                      Icons.outlined_flag_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.reportPost,
                          style: AppTextStyles.heading4(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.vXs,
                        Text(
                          AppStrings.reportPostSubtitle,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              AppSpacing.vXl,
              Text(
                AppStrings.reportPostQuestion,
                style: AppTextStyles.heading4(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              AppSpacing.vLg,
              RadioGroup<String>(
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final singleColumn = constraints.maxWidth < 620;
                    final optionWidth =
                        singleColumn
                            ? constraints.maxWidth
                            : (constraints.maxWidth - AppSpacing.xl) / 2;

                    return Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.md,
                      children:
                          _reportReasons.map((reason) {
                            return SizedBox(
                              width: optionWidth,
                              child: RadioListTile<String>(
                                value: reason,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  reason,
                                  style: AppTextStyles.bodyMediumHeading(context).copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(growable: false),
                    );
                  },
                ),
              ),
              if (_isOtherSelected) ...[
                AppSpacing.vMd,
                TextField(
                  controller: _otherReasonController,
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell us why you are reporting this post',
                    hintStyle: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      borderSide: const BorderSide(color: AppColors.info),
                    ),
                  ),
                ),
              ],
              AppSpacing.vXl,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                    ),
                    child: Text(
                      AppStrings.cancel,
                      style: AppTextStyles.buttonMedium(context).copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AppSpacing.hMd,
                  ElevatedButton(
                    onPressed:
                        _canSubmit
                            ? () => Navigator.of(context).pop(_resolvedReason)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                    ),
                    child: Text(
                      AppStrings.report,
                      style: AppTextStyles.buttonMedium(context),
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
}
