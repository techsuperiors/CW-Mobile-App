import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../domain/usecases/create_announcement_usecase.dart';
import '../cubit/create_announcement_cubit.dart';
import 'create_post_type_sheet.dart';

Future<String?> showPollPostComposerSheet(
  BuildContext context, {
  required CreatePostFlowResult audience,
  required int createdBy,
}) {
  final createAnnouncementUseCase = context.read<CreateAnnouncementUseCase>();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => BlocProvider(
          create:
              (_) => CreateAnnouncementCubit(
                createAnnouncementUseCase: createAnnouncementUseCase,
              ),
          child: PollPostComposerSheet(
            audience: audience,
            createdBy: createdBy,
          ),
        ),
  );
}

class PollPostComposerSheet extends StatefulWidget {
  final CreatePostFlowResult audience;
  final int createdBy;

  const PollPostComposerSheet({
    super.key,
    required this.audience,
    required this.createdBy,
  });

  @override
  State<PollPostComposerSheet> createState() => _PollPostComposerSheetState();
}

class _PollPostComposerSheetState extends State<PollPostComposerSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _repostEnabled = true;
  bool _shareEnabled = true;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initialDate = _scheduledAt?.toLocal() ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (selectedDate == null || !mounted) {
      return;
    }

    final initialTime = TimeOfDay.fromDateTime(_scheduledAt?.toLocal() ?? now);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    final scheduledLocal = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledLocal.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date and time')),
      );
      return;
    }

    setState(() {
      _scheduledAt = scheduledLocal;
    });
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      return;
    }

    final controller = _optionControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  void _submit() {
    final question = _questionController.text.trim();
    final optionValues = _optionControllers
        .map((controller) => controller.text.trim())
        .toList(growable: false);
    final options = optionValues
        .where((option) => option.isNotEmpty)
        .toList(growable: false);

    if (question.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question is required')));
      return;
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 poll options')),
      );
      return;
    }

    if (optionValues.any((option) => option.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill or remove any empty poll options'),
        ),
      );
      return;
    }

    if (options.toSet().length != options.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll options must be unique')),
      );
      return;
    }

    context.read<CreateAnnouncementCubit>().createPollAnnouncement(
      selectedDepartments: widget.audience.selectedDepartments,
      selectedIndividuals:
          widget.audience.allUsersSelected ||
                  widget.audience.selectedDepartments.isNotEmpty
              ? const []
              : widget.audience.selectedUsers,
      selectedUsers: widget.audience.selectedUsers,
      scheduleAnnouncement:
          (_scheduledAt ?? DateTime.now()).toUtc().toIso8601String(),
      question: question,
      options: options,
      likesEnabled: _likesEnabled,
      commentsEnabled: _commentsEnabled,
      repostEnabled: _repostEnabled,
      shareEnabled: _shareEnabled,
      createdBy: widget.createdBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return BlocListener<CreateAnnouncementCubit, CreateAnnouncementState>(
      listener: (context, state) {
        if (state.status == CreateAnnouncementStatus.success) {
          Navigator.of(context).pop(state.message);
          return;
        }

        if (state.status == CreateAnnouncementStatus.error &&
            state.message.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppSpacing.sectionLarge * 16,
              maxHeight: maxHeight,
            ),
            child: Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.xl),
              clipBehavior: Clip.antiAlias,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: BlocBuilder<
                    CreateAnnouncementCubit,
                    CreateAnnouncementState
                  >(
                    builder: (context, createState) {
                      final isSubmitting =
                          createState.status ==
                          CreateAnnouncementStatus.submitting;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: AppSpacing.sectionLarge,
                                height: AppSpacing.sectionLarge,
                                decoration: BoxDecoration(
                                  color: AppColors.attendanceLightBlueBg,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.md,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.poll_outlined,
                                  color: AppColors.info,
                                  size: AppSpacing.xl,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    isSubmitting
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          AppSpacing.vMd,
                          Text(
                            'Poll',
                            style: AppTextStyles.heading3(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vXs,
                          Text(
                            'Ask a question and gather opinions or feedback by creating a poll with multiple options.',
                            style: AppTextStyles.bodyMediumHeading(
                              context,
                            ).copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          AppSpacing.vXl,
                          _PollField(
                            label: 'Question',
                            placeholder: 'Ask something',
                            controller: _questionController,
                            enabled: !isSubmitting,
                            requiredField: true,
                          ),
                          AppSpacing.vMd,
                          ..._buildOptionFields(isSubmitting: isSubmitting),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isSubmitting ? null : _addOption,
                              child: Text(
                                '+ Add new option',
                                style: AppTextStyles.bodyMediumHeading(
                                  context,
                                ).copyWith(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.vLg,
                          Wrap(
                            spacing: AppSpacing.xl,
                            runSpacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _ActionIconButton(
                                icon: Icons.schedule_rounded,
                                onTap: isSubmitting ? null : _pickSchedule,
                              ),
                              Container(
                                width: 1,
                                height: AppSpacing.sectionLarge,
                                color: AppColors.border,
                              ),
                              _ConfigurationCheckbox(
                                label: 'Likes',
                                value: _likesEnabled,
                                onChanged:
                                    isSubmitting
                                        ? null
                                        : (value) => setState(
                                          () => _likesEnabled = value,
                                        ),
                              ),
                              _ConfigurationCheckbox(
                                label: 'Comments',
                                value: _commentsEnabled,
                                onChanged:
                                    isSubmitting
                                        ? null
                                        : (value) => setState(
                                          () => _commentsEnabled = value,
                                        ),
                              ),
                              _ConfigurationCheckbox(
                                label: 'Repost',
                                value: _repostEnabled,
                                onChanged:
                                    isSubmitting
                                        ? null
                                        : (value) => setState(
                                          () => _repostEnabled = value,
                                        ),
                              ),
                              _ConfigurationCheckbox(
                                label: 'Share',
                                value: _shareEnabled,
                                onChanged:
                                    isSubmitting
                                        ? null
                                        : (value) => setState(
                                          () => _shareEnabled = value,
                                        ),
                              ),
                            ],
                          ),
                          if (_scheduledAt != null) ...[
                            AppSpacing.vMd,
                            _ComposerMetaChip(
                              icon: Icons.schedule_rounded,
                              label: DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(_scheduledAt!),
                              onRemove:
                                  isSubmitting
                                      ? null
                                      : () =>
                                          setState(() => _scheduledAt = null),
                            ),
                          ],
                          AppSpacing.vLg,
                          const Divider(color: AppColors.border),
                          AppSpacing.vLg,
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      isSubmitting
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.md,
                                      ),
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    'Back',
                                    style: AppTextStyles.buttonMedium(
                                      context,
                                    ).copyWith(color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              AppSpacing.hMd,
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.md,
                                      ),
                                    ),
                                  ),
                                  child:
                                      isSubmitting
                                          ? SizedBox(
                                            width:
                                                AppSpacing.xl - AppSpacing.xs,
                                            height:
                                                AppSpacing.xl - AppSpacing.xs,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth:
                                                      AppSpacing.xs / 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.textWhite),
                                                ),
                                          )
                                          : Text(
                                            'Post',
                                            style: AppTextStyles.buttonMedium(
                                              context,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields({required bool isSubmitting}) {
    return List<Widget>.generate(_optionControllers.length, (index) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == _optionControllers.length - 1 ? 0 : AppSpacing.md,
        ),
        child: _PollField(
          label: 'Option ${index + 1}',
          placeholder: 'Option ${index + 1}',
          controller: _optionControllers[index],
          enabled: !isSubmitting,
          requiredField: true,
          trailing:
              _optionControllers.length > 2
                  ? IconButton(
                    onPressed: isSubmitting ? null : () => _removeOption(index),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  )
                  : null,
        ),
      );
    });
  }
}

class _PollField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool enabled;
  final bool requiredField;
  final Widget? trailing;

  const _PollField({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.enabled,
    this.requiredField = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: AppSpacing.section),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (requiredField)
                    Text(
                      '*',
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.hLg,
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: placeholder,
                  hintStyle: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const Divider(color: AppColors.border),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, color: AppColors.textSecondary, size: AppSpacing.xl),
      ),
    );
  }
}

class _ConfigurationCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ConfigurationCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged:
                onChanged == null ? null : (checked) => onChanged!(checked!),
            activeColor: AppColors.info,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(
            label,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ComposerMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onRemove;

  const _ComposerMetaChip({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundMediumLight,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.lg, color: AppColors.info),
          AppSpacing.hSm,
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMediumHeading(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ),
          AppSpacing.hSm,
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: const Icon(
              Icons.close_rounded,
              size: AppSpacing.lg,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
