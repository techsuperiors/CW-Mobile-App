import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';

class CreateVisitSheet extends StatefulWidget {
  const CreateVisitSheet({super.key});

  @override
  State<CreateVisitSheet> createState() => _CreateVisitSheetState();
}

class _CreateVisitSheetState extends State<CreateVisitSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  VisitType? _selectedVisitType;
  VisitEmployeeModel? _selectedEmployee;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    context.read<VisitBloc>().add(const LoadVisitEmployees());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  String? _formatApiTime(TimeOfDay? time) {
    if (time == null) return null;
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  void _submit(VisitState state) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit date is required')),
      );
      return;
    }
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assign employee is required')),
      );
      return;
    }

    context.read<VisitBloc>().add(
      CreateVisitRequested(
        CreateVisitParams(
          type: _selectedVisitType!,
          visitTitle: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          scheduledDate: _selectedDate!,
          startTime: _formatApiTime(_selectedTime),
          userId: _selectedEmployee!.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<VisitBloc, VisitState>(
      listenWhen:
          (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.actionError != current.actionError,
      listener: (context, state) {
        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
          context.read<VisitBloc>().add(const ClearVisitFeedback());
        } else if (state.actionError != null && state.actionError!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<VisitBloc>().add(const ClearVisitFeedback());
        }
      },
      builder: (context, state) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.55,
            maxChildSize: 0.94,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl + keyboardInset,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.borderDark,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          AppSpacing.vSm,
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.serviceBlueBg,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              AppAssets.iconVisit,
                              width: AppSpacing.iconSmallWidth,
                              height: AppSpacing.iconSmallHeight,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          AppSpacing.vMd,
                          Text(
                            'New Visit',
                            style: AppTextStyles.heading4(context).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.vSm,
                          Text(
                            'Create and manage a scheduled field visit for your team.',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.vMd,
                          _buildDropdownField<VisitType>(
                            context,
                            label: 'Visit Type',
                            hint: 'Select',
                            value: _selectedVisitType,
                            items: VisitType.values,
                            itemLabelBuilder: (item) => item.label,
                            onChanged:
                                state.isCreatingVisit
                                    ? null
                                    : (value) => setState(
                                      () => _selectedVisitType = value,
                                    ),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Visit type is required'
                                        : null,
                          ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Visit Title',
                            hint: 'Enter',
                            controller: _titleController,
                            enabled: !state.isCreatingVisit,
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Visit title is required'
                                        : null,
                          ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Description',
                            hint: 'Enter',
                            controller: _descriptionController,
                            enabled: !state.isCreatingVisit,
                            minLines: 3,
                            maxLines: 4,
                          ),
                          AppSpacing.vLg,
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(context),
                              ),
                              AppSpacing.hMd,
                              Expanded(
                                child: _buildTimeField(context),
                              ),
                            ],
                          ),
                          AppSpacing.vLg,
                          _buildDropdownField<VisitEmployeeModel>(
                            context,
                            label: 'Assign Employee',
                            hint:
                                state.isEmployeesLoading
                                    ? 'Loading...'
                                    : 'Select',
                            value: _selectedEmployee,
                            items: state.employees,
                            itemLabelBuilder: (item) => item.fullName,
                            onChanged:
                                state.isCreatingVisit
                                    ? null
                                    : (value) => setState(
                                      () => _selectedEmployee = value,
                                    ),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Assign employee is required'
                                        : null,
                          ),
                          if (state.employeesError != null) ...[
                            AppSpacing.vSm,
                            Text(
                              state.employeesError!,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                          AppSpacing.vXl,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  state.isCreatingVisit ? null : () => _submit(state),
                              style: ElevatedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  state.isCreatingVisit
                                      ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textWhite,
                                        ),
                                      )
                                      : Text(
                                        'Create Visit',
                                        style: AppTextStyles.buttonLarge(context),
                                      ),
                            ),
                          ),
                          AppSpacing.vMd,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  state.isCreatingVisit
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool enabled,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
        AppSpacing.vSm,
        TextFormField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium(context),
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    final text =
        _selectedDate == null
            ? 'Select'
            : DateFormat('dd/MM/yyyy').format(_selectedDate!);
    final color =
        _selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visit Date', style: AppTextStyles.labelLarge(context)),
        AppSpacing.vSm,
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyMedium(context).copyWith(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(BuildContext context) {
    final text = _selectedTime == null ? 'Enter' : _selectedTime!.format(context);
    final color =
        _selectedTime == null ? AppColors.textSecondary : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start Time', style: AppTextStyles.labelLarge(context)),
        AppSpacing.vSm,
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.access_time_outlined),
            ),
            child: Text(
              text,
              style: AppTextStyles.bodyMedium(context).copyWith(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(
    BuildContext context, {
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabelBuilder,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
        AppSpacing.vSm,
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          decoration: InputDecoration(hintText: hint),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabelBuilder(item),
                        style: AppTextStyles.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
          onChanged: onChanged,
          validator: validator,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
