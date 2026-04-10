import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/utils/app_spacing.dart';
import '../../../../../core/widgets/common/app_avatar.dart';
import '../../../domain/entities/announcement_entity.dart';

class EditPostDialog extends StatefulWidget {
  final AnnouncementEntity announcement;

  const EditPostDialog({
    super.key,
    required this.announcement,
  });

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool get _isRepostEdit => widget.announcement.repostedBy != null;
  bool get _isPollEdit =>
      !_isRepostEdit &&
      (widget.announcement.type?.trim().toLowerCase() == 'poll');
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _repostThoughtController;
  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.announcement.subject.trim(),
    );
    _descriptionController = TextEditingController(
      text: widget.announcement.description.trim(),
    );
    _repostThoughtController = TextEditingController(
      text: widget.announcement.repostThought?.trim() ?? '',
    );
    _questionController = TextEditingController(
      text: widget.announcement.question?.trim() ?? '',
    );
    final initialOptions =
        widget.announcement.options?.map((option) => option.trim()).toList() ??
        const <String>[];
    _optionControllers =
        (initialOptions.isNotEmpty ? initialOptions : const <String>['', ''])
            .map((option) => TextEditingController(text: option))
            .toList(growable: true);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _repostThoughtController.dispose();
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      EditPostDialogResult(
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        repostThought: _repostThoughtController.text.trim(),
        question: _isPollEdit ? _questionController.text.trim() : null,
        options:
            _isPollEdit
                ? _optionControllers
                    .map((controller) => controller.text.trim())
                    .toList(growable: false)
                : null,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final author =
        _isRepostEdit
            ? widget.announcement.repostedByUser ??
                widget.announcement.createdByUser
            : widget.announcement.createdByUser;
    final formattedDate = _formatDate(
      widget.announcement.scheduleAnnouncement ?? widget.announcement.createdAt,
    );

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
          maxWidth: 720,
          maxHeight: mediaQuery.size.height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: AppSpacing.cardPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      imageUrl: author?.imageUrl,
                      firstName: author?.firstName,
                      lastName: author?.lastName,
                      name: author?.fullName,
                      radius: AppSpacing.lg,
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author?.fullName.trim().isNotEmpty == true
                                ? author!.fullName.trim()
                                : 'User',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          AppSpacing.vXs,
                          Text(
                            formattedDate,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vXl,
                if (_isRepostEdit)
                  _buildRepostThoughtField(context)
                else if (_isPollEdit)
                  _buildPollEditSection(context)
                else ...[
                  _EditFieldRow(
                    label: 'Subject*',
                    child: TextFormField(
                      controller: _subjectController,
                      maxLines: 1,
                      textInputAction: TextInputAction.next,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Subject is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.vLg,
                  _EditFieldRow(
                    label: 'Description*',
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                AppSpacing.vXl,
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submit,
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
                      'Update',
                      style: AppTextStyles.buttonMedium(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollEditSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PollEditField(
          label: 'Question*',
          trailing: Text(
            '${_questionController.text.trim().length} / 200',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          child: TextFormField(
            controller: _questionController,
            minLines: 2,
            maxLines: 4,
            maxLength: 200,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => const SizedBox.shrink(),
            textInputAction: TextInputAction.next,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: 'Ask something',
              hintStyle: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
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
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Question is required';
              }
              return null;
            },
          ),
        ),
        AppSpacing.vLg,
        _PollEditField(
          label: 'Options*',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildPollOptionFields(context),
              TextButton(
                onPressed: _addOption,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Add New Option',
                  style: AppTextStyles.bodyMediumHeading(context).copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPollOptionFields(BuildContext context) {
    return List<Widget>.generate(_optionControllers.length, (index) {
      final controller = _optionControllers[index];

      return Padding(
        padding: EdgeInsets.only(
          bottom: index == _optionControllers.length - 1 ? AppSpacing.sm : AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                textInputAction:
                    index == _optionControllers.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Option ${index + 1}',
                  hintStyle: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option ${index + 1} is required';
                  }

                  final normalizedValue = value.trim().toLowerCase();
                  final duplicateCount =
                      _optionControllers
                          .map((optionController) => optionController.text.trim().toLowerCase())
                          .where((option) => option == normalizedValue)
                          .length;

                  if (duplicateCount > 1) {
                    return 'Options must be unique';
                  }

                  return null;
                },
              ),
            ),
            if (_optionControllers.length > 2) ...[
              AppSpacing.hSm,
              IconButton(
                onPressed: () => _removeOption(index),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _formatDate(String rawDate) {
    try {
      final dateTime = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy | hh:mm a').format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }

  Widget _buildRepostThoughtField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share your thoughts*',
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vSm,
        TextFormField(
          controller: _repostThoughtController,
          minLines: 4,
          maxLines: 6,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.textPrimary,
            height: 1.45,
          ),
          decoration: InputDecoration(
            hintText: 'Share your thoughts',
            hintStyle: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
            ),
            filled: false,
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
          validator: (value) {
            if (_isRepostEdit && (value == null || value.trim().isEmpty)) {
              return 'Share your thoughts is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _EditFieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _EditFieldRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppSpacing.hLg,
            Expanded(flex: 4, child: child),
          ],
        ),
        AppSpacing.vMd,
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _PollEditField extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;

  const _PollEditField({
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        AppSpacing.vSm,
        child,
      ],
    );
  }
}

class EditPostDialogResult {
  final String subject;
  final String description;
  final String? repostThought;
  final String? question;
  final List<String>? options;

  const EditPostDialogResult({
    required this.subject,
    required this.description,
    this.repostThought,
    this.question,
    this.options,
  });
}
