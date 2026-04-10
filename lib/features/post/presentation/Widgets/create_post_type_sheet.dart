import 'package:collectivWork/core/constants/app_strings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/common/app_avatar.dart';
import '../../domain/entities/create_post_audience_entity.dart';
import '../../domain/usecases/get_create_post_audience_departments_usecase.dart';
import '../../domain/usecases/get_create_post_audience_users_usecase.dart';
import '../cubit/create_post_audience_cubit.dart';

enum CreatePostType {
  general(
    title: 'General',
    description:
        'Share an important update, announcement, or any information you want your audience to know.',
    icon: Icons.assignment_outlined,
  ),
  praise(
    title: 'Praise',
    description:
        'Give a shoutout to an individual or team for their great work and contributions.',
    icon: Icons.workspace_premium_outlined,
  ),
  poll(
    title: 'Poll',
    description:
        'Ask a question and gather opinions or feedback by creating a poll with multiple options.',
    icon: Icons.bar_chart_rounded,
  );

  final String title;
  final String description;
  final IconData icon;

  const CreatePostType({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class CreatePostFlowResult extends Equatable {
  final CreatePostType type;
  final bool allUsersSelected;
  final List<CreatePostAudienceDepartmentEntity> selectedDepartments;
  final List<CreatePostAudienceUserEntity> selectedUsers;
  final List<CreatePostAudienceUserEntity> availableUsers;

  const CreatePostFlowResult({
    required this.type,
    required this.allUsersSelected,
    required this.selectedDepartments,
    required this.selectedUsers,
    required this.availableUsers,
  });

  @override
  List<Object?> get props => [
    type,
    allUsersSelected,
    selectedDepartments,
    selectedUsers,
    availableUsers,
  ];
}

enum _CreatePostSheetStep { typeSelection, audienceSelection }

Future<CreatePostFlowResult?> showCreatePostTypeSheet(BuildContext context) {
  final departmentsUseCase =
      context.read<GetCreatePostAudienceDepartmentsUseCase>();
  final usersUseCase = context.read<GetCreatePostAudienceUsersUseCase>();

  return showModalBottomSheet<CreatePostFlowResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => BlocProvider(
          create:
              (_) => CreatePostAudienceCubit(
                getCreatePostAudienceDepartmentsUseCase: departmentsUseCase,
                getCreatePostAudienceUsersUseCase: usersUseCase,
              ),
          child: const CreatePostTypeSheet(),
        ),
  );
}

class CreatePostTypeSheet extends StatefulWidget {
  const CreatePostTypeSheet({super.key});

  @override
  State<CreatePostTypeSheet> createState() => _CreatePostTypeSheetState();
}

class _CreatePostTypeSheetState extends State<CreatePostTypeSheet> {
  CreatePostType _selectedType = CreatePostType.general;
  _CreatePostSheetStep _currentStep = _CreatePostSheetStep.typeSelection;

  final TextEditingController _departmentSearchController =
      TextEditingController();
  final TextEditingController _individualSearchController =
      TextEditingController();

  bool _showDepartmentSuggestions = false;
  bool _showIndividualSuggestions = false;
  bool _isPrimaryActionInProgress = false;

  @override
  void dispose() {
    _departmentSearchController.dispose();
    _individualSearchController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    if (_isPrimaryActionInProgress) {
      return;
    }

    setState(() {
      _isPrimaryActionInProgress = true;
    });

    try {
      if (_currentStep == _CreatePostSheetStep.typeSelection) {
        await context.read<CreatePostAudienceCubit>().loadAudienceOptions();
        if (!mounted) return;

        final state = context.read<CreatePostAudienceCubit>().state;
        if (state.status == CreatePostAudienceStatus.error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
          return;
        }

        setState(() {
          _currentStep = _CreatePostSheetStep.audienceSelection;
        });
        return;
      }

      final state = context.read<CreatePostAudienceCubit>().state;
      final selectedUsers = _selectedUsers(state);

      if (selectedUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one audience')),
        );
        return;
      }

      Navigator.of(context).pop(
        CreatePostFlowResult(
          type: _selectedType,
          allUsersSelected: state.allUsersSelected,
          selectedDepartments: _selectedDepartments(state),
          selectedUsers: selectedUsers,
          availableUsers: state.users,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrimaryActionInProgress = false;
        });
      }
    }
  }

  void _handleSecondaryAction() {
    if (_currentStep == _CreatePostSheetStep.typeSelection) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentStep = _CreatePostSheetStep.typeSelection;
      _showDepartmentSuggestions = false;
      _showIndividualSuggestions = false;
      _departmentSearchController.clear();
      _individualSearchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppSpacing.sectionLarge * 16,
            maxHeight: maxHeight,
          ),
          child: Material(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child:
                    _currentStep == _CreatePostSheetStep.typeSelection
                        ? _buildTypeSelectionStep(context)
                        : _buildAudienceStep(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelectionStep(BuildContext context) {
    return Column(
      key: const ValueKey<String>('type-selection-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetHeader(
          icon: Icons.campaign_outlined,
          onClose: () => Navigator.of(context).pop(),
        ),
        AppSpacing.vMd,
        Text(
          'Post',
          style: AppTextStyles.heading3(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        AppSpacing.vXs,
        Text(
          'Share a message to communicate updates, insights, or key information with your audience.',
          style: AppTextStyles.bodyMediumHeading(
            context,
          ).copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        AppSpacing.vLg,
        ...CreatePostType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _PostTypeOptionCard(
              type: type,
              isSelected: type == _selectedType,
              onTap: () => setState(() => _selectedType = type),
            ),
          ),
        ),
        _SheetFooter(
          secondaryLabel: 'Cancel',
          primaryLabel: 'Confirm',
          onSecondaryPressed:
              _isPrimaryActionInProgress ? null : _handleSecondaryAction,
          onPrimaryPressed:
              _isPrimaryActionInProgress ? null : _handlePrimaryAction,
          isPrimaryLoading: _isPrimaryActionInProgress,
        ),
      ],
    );
  }

  Widget _buildAudienceStep(BuildContext context) {
    return BlocBuilder<CreatePostAudienceCubit, CreatePostAudienceState>(
      builder: (context, state) {
        final selectedUsers = _selectedUsers(state);
        final departmentSuggestions = _filteredDepartments(state);
        final userSuggestions = _filteredUsers(state);

        return Column(
          key: const ValueKey<String>('audience-selection-step'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              icon: _selectedType.icon,
              onClose: () => Navigator.of(context).pop(),
            ),
            AppSpacing.vMd,
            Text(
              _selectedType.title,
              style: AppTextStyles.heading3(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.vXs,
            Text(
              _selectedType.description,
              style: AppTextStyles.bodyMediumHeading(
                context,
              ).copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            AppSpacing.vXl,
            Text(
             AppStrings.selectAudience,
              style: AppTextStyles.heading3(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.vMd,
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _AudienceScopeToggle(
                  label: 'All Users',
                  value: state.allUsersSelected,
                  onChanged: (value) {
                    setState(() {
                      _showDepartmentSuggestions = false;
                      _showIndividualSuggestions = false;
                      _departmentSearchController.clear();
                      _individualSearchController.clear();
                    });
                    context.read<CreatePostAudienceCubit>().setAllUsersSelected(
                      value,
                    );
                  },
                ),
                _AudienceScopeToggle(
                  label: 'Departments',
                  value: state.departmentsSelected,
                  onChanged: (value) {
                    setState(() {
                      _showDepartmentSuggestions = value;
                      _showIndividualSuggestions = false;
                      _individualSearchController.clear();
                      if (!value) {
                        _departmentSearchController.clear();
                      }
                    });
                    context
                        .read<CreatePostAudienceCubit>()
                        .setDepartmentsSelected(value);
                  },
                ),
                _AudienceScopeToggle(
                  label: 'Individuals',
                  value: state.individualsSelected,
                  onChanged: (value) {
                    setState(() {
                      _showIndividualSuggestions = value;
                      _showDepartmentSuggestions = false;
                      _departmentSearchController.clear();
                      if (!value) {
                        _individualSearchController.clear();
                      }
                    });
                    context
                        .read<CreatePostAudienceCubit>()
                        .setIndividualsSelected(value);
                  },
                ),
              ],
            ),
            AppSpacing.vSm,
            Container(
              width: double.infinity,
              height: AppSpacing.sectionLarge * 5,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildAudienceSelectionContent(
                context: context,
                state: state,
                selectedUsers: selectedUsers,
                departmentSuggestions: departmentSuggestions,
                userSuggestions: userSuggestions,
              ),
            ),
            AppSpacing.vLg,
            _SheetFooter(
              secondaryLabel: 'Back',
              primaryLabel: 'Confirm',
              onSecondaryPressed:
                  _isPrimaryActionInProgress ? null : _handleSecondaryAction,
              onPrimaryPressed:
                  _isPrimaryActionInProgress ? null : _handlePrimaryAction,
              isPrimaryLoading: _isPrimaryActionInProgress,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudienceSelectionContent({
    required BuildContext context,
    required CreatePostAudienceState state,
    required List<CreatePostAudienceUserEntity> selectedUsers,
    required List<CreatePostAudienceDepartmentEntity> departmentSuggestions,
    required List<CreatePostAudienceUserEntity> userSuggestions,
  }) {
    if (state.status == CreatePostAudienceStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CreatePostAudienceStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            ElevatedButton(
              onPressed:
                  () =>
                      context
                          .read<CreatePostAudienceCubit>()
                          .loadAudienceOptions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
              ),
              child: Text('Retry', style: AppTextStyles.buttonMedium(context)),
            ),
          ],
        ),
      );
    }

    final showAudiencePlaceholder =
        !state.allUsersSelected &&
        !state.departmentsSelected &&
        !state.individualsSelected;

    if (showAudiencePlaceholder) {
      return Center(
        child: Text(
          'Select Audience',
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    if (state.allUsersSelected) {
      return _SelectedAudienceUsersList(
        users: selectedUsers,
        onRemove:
            (userId) => context
                .read<CreatePostAudienceCubit>()
                .removeSelectedUser(userId),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.departmentsSelected) ...[
          _SelectionSearchField(
            controller: _departmentSearchController,
            hintText: 'Select Departments',
            showSuggestions: _showDepartmentSuggestions,
            onToggleSuggestions:
                () => setState(
                  () =>
                      _showDepartmentSuggestions = !_showDepartmentSuggestions,
                ),
            onChanged: (_) => setState(() => _showDepartmentSuggestions = true),
          ),
          if (_selectedDepartments(state).isNotEmpty) ...[
            AppSpacing.vSm,
            _SelectionChipsWrap(
              labels: _selectedDepartments(state)
                  .map(
                    (department) => _SelectionChipData(
                      label: department.name,
                      onRemove:
                          () => context
                              .read<CreatePostAudienceCubit>()
                              .removeDepartment(department.id),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_showDepartmentSuggestions) ...[
            AppSpacing.vSm,
            _SuggestionsList<CreatePostAudienceDepartmentEntity>(
              items: departmentSuggestions,
              itemLabel: (department) => department.name,
              onSelected: (department) {
                context.read<CreatePostAudienceCubit>().addDepartment(
                  department,
                );
                setState(() {
                  _departmentSearchController.clear();
                  _showDepartmentSuggestions = false;
                });
              },
              emptyText: 'No departments found',
            ),
          ],
          AppSpacing.vMd,
        ],
        if (state.individualsSelected) ...[
          _SelectionSearchField(
            controller: _individualSearchController,
            hintText: 'Select Individuals',
            showSuggestions: _showIndividualSuggestions,
            onToggleSuggestions:
                () => setState(
                  () =>
                      _showIndividualSuggestions = !_showIndividualSuggestions,
                ),
            onChanged: (_) => setState(() => _showIndividualSuggestions = true),
          ),
          if (_selectedIndividualUsers(state).isNotEmpty) ...[
            AppSpacing.vSm,
            _SelectionChipsWrap(
              labels: _selectedIndividualUsers(state)
                  .map(
                    (user) => _SelectionChipData(
                      label: user.fullName,
                      onRemove:
                          () => context
                              .read<CreatePostAudienceCubit>()
                              .removeSelectedUser(user.id),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_showIndividualSuggestions) ...[
            AppSpacing.vSm,
            _SuggestionsList<CreatePostAudienceUserEntity>(
              items: userSuggestions,
              itemLabel: (user) => '${user.fullName} • ${user.email}',
              onSelected: (user) {
                context.read<CreatePostAudienceCubit>().addIndividualUser(user);
                setState(() {
                  _individualSearchController.clear();
                  _showIndividualSuggestions = false;
                });
              },
              emptyText: 'No individuals found',
            ),
          ],
          AppSpacing.vMd,
        ],
        Expanded(
          child:
              selectedUsers.isEmpty
                  ? Center(
                    child: Text(
                      'Select Audience',
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(color: AppColors.textTertiary),
                    ),
                  )
                  : _SelectedAudienceUsersList(
                    users: selectedUsers,
                    onRemove:
                        (userId) => context
                            .read<CreatePostAudienceCubit>()
                            .removeSelectedUser(userId),
                  ),
        ),
      ],
    );
  }

  List<CreatePostAudienceDepartmentEntity> _selectedDepartments(
    CreatePostAudienceState state,
  ) {
    final selectedDepartmentIds = state.selectedDepartmentIds.toSet();
    final selectedDepartments = state.departments
        .where((department) => selectedDepartmentIds.contains(department.id))
        .toList(growable: false);

    return selectedDepartments;
  }

  List<CreatePostAudienceUserEntity> _selectedIndividualUsers(
    CreatePostAudienceState state,
  ) {
    final selectedIds = state.selectedIndividualUserIds.toSet();
    return state.users
        .where((user) => selectedIds.contains(user.id))
        .toList(growable: false);
  }

  List<CreatePostAudienceUserEntity> _selectedUsers(
    CreatePostAudienceState state,
  ) {
    final selectedUsersById = <int, CreatePostAudienceUserEntity>{};
    final excludedUserIds = state.excludedUserIds.toSet();

    void addUser(CreatePostAudienceUserEntity user) {
      if (excludedUserIds.contains(user.id)) {
        return;
      }
      selectedUsersById[user.id] = user;
    }

    if (state.allUsersSelected) {
      for (final user in state.users) {
        addUser(user);
      }
    } else {
      if (state.departmentsSelected) {
        for (final department in _selectedDepartments(state)) {
          for (final member in department.members) {
            addUser(member);
          }
        }
      }

      if (state.individualsSelected) {
        for (final user in _selectedIndividualUsers(state)) {
          addUser(user);
        }
      }
    }

    final selectedUsers = selectedUsersById.values.toList(
      growable: false,
    )..sort(
      (first, second) =>
          first.fullName.toLowerCase().compareTo(second.fullName.toLowerCase()),
    );
    return selectedUsers;
  }

  List<CreatePostAudienceDepartmentEntity> _filteredDepartments(
    CreatePostAudienceState state,
  ) {
    final query = _departmentSearchController.text.trim().toLowerCase();
    final selectedDepartmentIds = state.selectedDepartmentIds.toSet();

    return state.departments
        .where((department) => !selectedDepartmentIds.contains(department.id))
        .where(
          (department) =>
              query.isEmpty || department.name.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<CreatePostAudienceUserEntity> _filteredUsers(
    CreatePostAudienceState state,
  ) {
    final query = _individualSearchController.text.trim().toLowerCase();
    final selectedUserIds =
        _selectedUsers(state).map((user) => user.id).toSet();

    return state.users
        .where((user) => !selectedUserIds.contains(user.id))
        .where((user) {
          if (query.isEmpty) {
            return true;
          }

          return user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              (user.department?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }
}

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final VoidCallback onClose;

  const _SheetHeader({required this.icon, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: AppSpacing.sectionLarge,
          height: AppSpacing.sectionLarge,
          decoration: BoxDecoration(
            color: AppColors.attendanceLightBlueBg,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Icon(icon, color: AppColors.info, size: AppSpacing.xl),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
      ],
    );
  }
}

class _SheetFooter extends StatelessWidget {
  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onPrimaryPressed;
  final bool isPrimaryLoading;

  const _SheetFooter({
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondaryPressed,
    required this.onPrimaryPressed,
    this.isPrimaryLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondaryPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Text(
              secondaryLabel,
              style: AppTextStyles.buttonMedium(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
        AppSpacing.hMd,
        Expanded(
          child: ElevatedButton(
            onPressed: onPrimaryPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
            ),
            child:
                isPrimaryLoading
                    ? SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textWhite,
                        ),
                      ),
                    )
                    : Text(
                      primaryLabel,
                      style: AppTextStyles.buttonMedium(context),
                    ),
          ),
        ),
      ],
    );
  }
}

class _PostTypeOptionCard extends StatelessWidget {
  final CreatePostType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _PostTypeOptionCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            border: Border.all(
              color: isSelected ? AppColors.info : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          type.icon,
                          color:
                              isSelected
                                  ? AppColors.info
                                  : AppColors.textSecondary,
                          size: AppSpacing.xl,
                        ),
                        AppSpacing.hMd,
                        Text(
                          type.title,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected
                                    ? AppColors.info
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSm,
                    Text(
                      type.description,
                      style: AppTextStyles.bodyMediumHeading(context).copyWith(
                        color:
                            isSelected
                                ? AppColors.info
                                : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hMd,
              Container(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.info : AppColors.textSecondary,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.xs),
                child:
                    isSelected
                        ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceScopeToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AudienceScopeToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: AppColors.info,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            AppSpacing.hSm,
            Text(
              label,
              style: AppTextStyles.bodyMediumHeading(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool showSuggestions;
  final VoidCallback onToggleSuggestions;
  final ValueChanged<String> onChanged;

  const _SelectionSearchField({
    required this.controller,
    required this.hintText,
    required this.showSuggestions,
    required this.onToggleSuggestions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium(context),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium(
          context,
        ).copyWith(color: AppColors.textTertiary),
        suffixIcon: IconButton(
          onPressed: onToggleSuggestions,
          icon: Icon(
            showSuggestions
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
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
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SelectionChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppSpacing.sectionLarge * 4),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSpacing.hXs,
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: AppSpacing.iconSmallWidth,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionChipData {
  final String label;
  final VoidCallback onRemove;

  const _SelectionChipData({required this.label, required this.onRemove});
}

class _SelectionChipsWrap extends StatelessWidget {
  final List<_SelectionChipData> labels;

  const _SelectionChipsWrap({required this.labels});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: AppSpacing.sectionLarge * 1.6),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: labels
              .map(
                (chip) =>
                    _SelectionChip(label: chip.label, onRemove: chip.onRemove),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SuggestionsList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onSelected;
  final String emptyText;

  const _SuggestionsList({
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Text(
          emptyText,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: AppSpacing.sectionLarge * 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder:
            (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => onSelected(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Text(
                itemLabel(item),
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textPrimary),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedAudienceUsersList extends StatelessWidget {
  final List<CreatePostAudienceUserEntity> users;
  final ValueChanged<int> onRemove;

  const _SelectedAudienceUsersList({
    required this.users,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => AppSpacing.vMd,
      itemBuilder: (context, index) {
        final user = users[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              imageUrl: user.imageUrl,
              firstName: user.firstName,
              lastName: user.lastName,
              name: user.fullName,
              radius: AppSpacing.lg,
              backgroundColor: _profileBackgroundColor(user.profileColor),
            ),
            AppSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(
                    user.email,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            AppSpacing.hSm,
            TextButton(
              onPressed: () => onRemove(user.id),
              child: Text(
                'Remove',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _profileBackgroundColor(String? hexColor) {
  final normalizedValue = (hexColor ?? '').replaceAll('#', '').trim();
  if (normalizedValue.length == 6) {
    final colorValue = int.tryParse('FF$normalizedValue', radix: 16);
    if (colorValue != null) {
      return Color(colorValue);
    }
  }
  return AppColors.backgroundMedium;
}
