import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../domain/entities/create_post_audience_entity.dart';
import '../../domain/usecases/create_announcement_usecase.dart';
import '../../domain/usecases/generate_announcement_content_usecase.dart';
import '../cubit/create_announcement_cubit.dart';
import '../cubit/generate_announcement_content_cubit.dart';
import 'create_post_type_sheet.dart';

enum _ComposerAttachmentType {
  image(label: 'Image', icon: Icons.image_outlined),
  video(label: 'Video', icon: Icons.play_circle_outline_rounded);

  final String label;
  final IconData icon;

  const _ComposerAttachmentType({required this.label, required this.icon});
}

class _SelectedComposerAttachment {
  final String path;
  final String name;
  final _ComposerAttachmentType type;

  const _SelectedComposerAttachment({
    required this.path,
    required this.name,
    required this.type,
  });
}

Future<String?> showPraisePostComposerSheet(
  BuildContext context, {
  required CreatePostFlowResult audience,
  required int createdBy,
}) {
  final createAnnouncementUseCase = context.read<CreateAnnouncementUseCase>();
  final generateAnnouncementContentUseCase =
      context.read<GenerateAnnouncementContentUseCase>();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create:
                  (_) => CreateAnnouncementCubit(
                    createAnnouncementUseCase: createAnnouncementUseCase,
                  ),
            ),
            BlocProvider(
              create:
                  (_) => GenerateAnnouncementContentCubit(
                    generateAnnouncementContentUseCase:
                        generateAnnouncementContentUseCase,
                  ),
            ),
          ],
          child: PraisePostComposerSheet(
            audience: audience,
            createdBy: createdBy,
          ),
        ),
  );
}

class PraisePostComposerSheet extends StatefulWidget {
  final CreatePostFlowResult audience;
  final int createdBy;

  const PraisePostComposerSheet({
    super.key,
    required this.audience,
    required this.createdBy,
  });

  @override
  State<PraisePostComposerSheet> createState() => _PraisePostComposerSheetState();
}

class _PraisePostComposerSheetState extends State<PraisePostComposerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _repostEnabled = true;
  bool _shareEnabled = true;
  bool _isPickingImage = false;
  bool _isPickingVideo = false;
  DateTime? _scheduledAt;
  CreatePostAudienceUserEntity? _praisedToUser;
  final List<_SelectedComposerAttachment> _selectedAttachments = [];

  List<_SelectedComposerAttachment> get _selectedImageAttachments =>
      _selectedAttachments
          .where((attachment) => attachment.type == _ComposerAttachmentType.image)
          .toList(growable: false);

  List<_SelectedComposerAttachment> get _selectedMetaAttachments =>
      _selectedAttachments
          .where((attachment) => attachment.type != _ComposerAttachmentType.image)
          .toList(growable: false);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) {
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty || !mounted) {
        return;
      }

      setState(() {
        final existingPaths =
            _selectedAttachments.map((file) => file.path).toSet();
        final newAttachments = images
            .where((image) => !existingPaths.contains(image.path))
            .map(
              (image) => _SelectedComposerAttachment(
                path: image.path,
                name: image.name,
                type: _ComposerAttachmentType.image,
              ),
            )
            .toList(growable: false);
        _selectedAttachments.addAll(newAttachments);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingVideo) {
      return;
    }

    setState(() => _isPickingVideo = true);

    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) {
        return;
      }

      setState(() {
        _selectedAttachments.removeWhere(
          (attachment) => attachment.type == _ComposerAttachmentType.video,
        );
        _selectedAttachments.add(
          _SelectedComposerAttachment(
            path: video.path,
            name: video.name,
            type: _ComposerAttachmentType.video,
          ),
        );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting video: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingVideo = false);
      }
    }
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

  void _rewriteDescription() {
    final content = _descriptionController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add thoughts first to rewrite with AI')),
      );
      return;
    }

    context.read<GenerateAnnouncementContentCubit>().generate(content: content);
  }

  void _submit() {
    final subject = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (_praisedToUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who you want to praise')),
      );
      return;
    }

    if (subject.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Description is required')));
      return;
    }

    context.read<CreateAnnouncementCubit>().createPraiseAnnouncement(
      selectedDepartments: widget.audience.selectedDepartments,
      selectedIndividuals:
          widget.audience.allUsersSelected ||
                  widget.audience.selectedDepartments.isNotEmpty
              ? const []
              : widget.audience.selectedUsers,
      selectedUsers: widget.audience.selectedUsers,
      scheduleAnnouncement:
          (_scheduledAt ?? DateTime.now()).toUtc().toIso8601String(),
      subject: subject,
      description: description,
      likesEnabled: _likesEnabled,
      commentsEnabled: _commentsEnabled,
      repostEnabled: _repostEnabled,
      shareEnabled: _shareEnabled,
      attachmentFilePaths: _selectedAttachments
          .map((file) => file.path)
          .toList(growable: false),
      praisedToUserId: _praisedToUser!.id,
      createdBy: widget.createdBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return MultiBlocListener(
      listeners: [
        BlocListener<CreateAnnouncementCubit, CreateAnnouncementState>(
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
        ),
        BlocListener<
          GenerateAnnouncementContentCubit,
          GenerateAnnouncementContentState
        >(
          listener: (context, state) {
            if (state.status == GenerateAnnouncementContentStatus.success) {
              _descriptionController
                ..text = state.content
                ..selection = TextSelection.collapsed(
                  offset: state.content.length,
                );
              return;
            }

            if (state.status == GenerateAnnouncementContentStatus.error &&
                state.message.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
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
                      return BlocBuilder<
                        GenerateAnnouncementContentCubit,
                        GenerateAnnouncementContentState
                      >(
                        builder: (context, generateState) {
                          final isSubmitting =
                              createState.status ==
                              CreateAnnouncementStatus.submitting;
                          final isRewriting =
                              generateState.status ==
                              GenerateAnnouncementContentStatus.loading;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      Icons.workspace_premium_outlined,
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
                                'Praise',
                                style: AppTextStyles.heading3(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              AppSpacing.vXs,
                              Text(
                                'Give a shoutout to an individual or team for their great work and contributions.',
                                style: AppTextStyles.bodyMediumHeading(
                                  context,
                                ).copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              AppSpacing.vXl,
                              Row(
                                children: [
                                  Text(
                                    'Praise To',
                                    style: AppTextStyles.bodyLarge(
                                      context,
                                    ).copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '*',
                                    style: AppTextStyles.bodyLarge(
                                      context,
                                    ).copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.vXs,
                              DropdownButtonHideUnderline(
                                child: DropdownButton<CreatePostAudienceUserEntity>(
                                  value: _praisedToUser,
                                  isExpanded: true,
                                  menuMaxHeight: maxHeight * 0.4,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  hint: Text(
                                    'Select recipient',
                                    style: AppTextStyles.bodyLarge(
                                      context,
                                    ).copyWith(color: AppColors.textTertiary),
                                  ),
                                  items: widget.audience.availableUsers
                                      .map(
                                        (user) =>
                                            DropdownMenuItem<CreatePostAudienceUserEntity>(
                                              value: user,
                                              child: Text(
                                                user.fullName,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.bodyLarge(
                                                  context,
                                                ).copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(growable: false),
                                  onChanged:
                                      isSubmitting ||
                                              widget
                                                  .audience
                                                  .availableUsers
                                                  .isEmpty
                                          ? null
                                          : (user) => setState(
                                            () => _praisedToUser = user,
                                          ),
                                ),
                              ),
                              const Divider(color: AppColors.border),
                              AppSpacing.vMd,
                              Row(
                                children: [
                                  Text(
                                    'Title',
                                    style: AppTextStyles.bodyLarge(
                                      context,
                                    ).copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '*',
                                    style: AppTextStyles.bodyLarge(
                                      context,
                                    ).copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.vXs,
                              TextField(
                                controller: _titleController,
                                enabled: !isSubmitting,
                                style: AppTextStyles.bodyMedium(
                                  context,
                                ).copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const Divider(color: AppColors.border),
                              AppSpacing.vXs,
                              TextField(
                                controller: _descriptionController,
                                enabled: !isSubmitting,
                                minLines: 4,
                                maxLines: 12,
                                style: AppTextStyles.bodyMedium(
                                  context,
                                ).copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Share Your Thoughts...',
                                  hintStyle: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              AppSpacing.vLg,
                              Wrap(
                                spacing: AppSpacing.xl,
                                runSpacing: AppSpacing.sm,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed:
                                        isSubmitting || isRewriting
                                            ? null
                                            : _rewriteDescription,
                                    icon:
                                        isRewriting
                                            ? SizedBox(
                                              width: AppSpacing.lg,
                                              height: AppSpacing.lg,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth:
                                                        AppSpacing.xs / 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(AppColors.warning),
                                                  ),
                                            )
                                            : const Icon(
                                              Icons.auto_awesome_outlined,
                                              color: AppColors.warning,
                                            ),
                                    label: Text(
                                      isRewriting
                                          ? 'Rewriting...'
                                          : 'Rewrite with AI',
                                      style: AppTextStyles.bodyMediumHeading(
                                        context,
                                      ).copyWith(color: AppColors.textPrimary),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.xl,
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  _ActionIconButton(
                                    icon: _ComposerAttachmentType.image.icon,
                                    onTap:
                                        isSubmitting || _isPickingImage
                                            ? null
                                            : _pickImage,
                                  ),
                                  _ActionIconButton(
                                    icon: Icons.schedule_rounded,
                                    onTap: isSubmitting ? null : _pickSchedule,
                                  ),
                                  _ActionIconButton(
                                    icon: _ComposerAttachmentType.video.icon,
                                    onTap:
                                        isSubmitting || _isPickingVideo
                                            ? null
                                            : _pickVideo,
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
                              if (_scheduledAt != null ||
                                  _selectedAttachments.isNotEmpty) ...[
                                AppSpacing.vMd,
                                if (_selectedImageAttachments.isNotEmpty) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: _selectedImageAttachments
                                          .map(
                                            (attachment) =>
                                                _ComposerImagePreviewTile(
                                                  filePath: attachment.path,
                                                  fileName: attachment.name,
                                                  onRemove: isSubmitting
                                                      ? null
                                                      : () => setState(
                                                            () => _selectedAttachments
                                                                .removeWhere(
                                                                  (item) =>
                                                                      item.path ==
                                                                      attachment
                                                                          .path,
                                                                ),
                                                          ),
                                                ),
                                          )
                                          .toList(growable: false),
                                    ),
                                  ),
                                  if (_scheduledAt != null ||
                                      _selectedMetaAttachments.isNotEmpty)
                                    AppSpacing.vMd,
                                ],
                                if (_scheduledAt != null ||
                                    _selectedMetaAttachments.isNotEmpty)
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if (_scheduledAt != null)
                                        _ComposerMetaChip(
                                          icon: Icons.schedule_rounded,
                                          label: DateFormat(
                                            'dd MMM yyyy, hh:mm a',
                                          ).format(_scheduledAt!),
                                          onRemove:
                                              isSubmitting
                                                  ? null
                                                  : () => setState(
                                                        () => _scheduledAt = null,
                                                      ),
                                        ),
                                      ..._selectedMetaAttachments.map(
                                        (attachment) => _ComposerMetaChip(
                                          icon: attachment.type.icon,
                                          label:
                                              '${attachment.type.label}: ${attachment.name}',
                                          onRemove:
                                              isSubmitting
                                                  ? null
                                                  : () => setState(
                                                        () => _selectedAttachments
                                                            .removeWhere(
                                                              (item) =>
                                                                  item.path ==
                                                                  attachment.path,
                                                            ),
                                                      ),
                                        ),
                                      ),
                                    ],
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
                                              : () =>
                                                  Navigator.of(context).pop(),
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
                                        ).copyWith(
                                          color: AppColors.textPrimary,
                                        ),
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
                                                    AppSpacing.xl -
                                                    AppSpacing.xs,
                                                height:
                                                    AppSpacing.xl -
                                                    AppSpacing.xs,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth:
                                                          AppSpacing.xs / 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            AppColors.textWhite,
                                                          ),
                                                    ),
                                              )
                                              : Text(
                                                'Post',
                                                style:
                                                    AppTextStyles.buttonMedium(
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

class _ComposerImagePreviewTile extends StatelessWidget {
  static const double _previewSize = AppSpacing.sectionLarge + AppSpacing.xl;

  final String filePath;
  final String fileName;
  final VoidCallback? onRemove;

  const _ComposerImagePreviewTile({
    required this.filePath,
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _previewSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: _previewSize,
                height: _previewSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.backgroundMediumLight,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  File(filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                        size: AppSpacing.xxl,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.close_rounded,
                        size: AppSpacing.lg,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vXs,
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
