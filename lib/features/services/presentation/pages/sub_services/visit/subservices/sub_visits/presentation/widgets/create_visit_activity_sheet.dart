import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';

class CreateVisitActivitySheet extends StatefulWidget {
  final VisitModel visit;

  const CreateVisitActivitySheet({super.key, required this.visit});

  @override
  State<CreateVisitActivitySheet> createState() =>
      _CreateVisitActivitySheetState();
}

class _CreateVisitActivitySheetState extends State<CreateVisitActivitySheet> {
  static const List<String> _activityTypeOptions = [
    'Installation',
    'Repair',
    'Consultation',
    'Sales',
    'Delivery',
    'Other',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _activityTypeController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  VisitCustomerModel? _selectedCustomer;
  VisitAddressModel? _selectedAddress;

  bool get _isCustomerVisit => widget.visit.type == VisitType.customer;

  bool get _isAddressVisit => widget.visit.type == VisitType.address;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<VisitBloc>();
    bloc.add(const LoadVisitAddresses());
    bloc.add(const LoadVisitCustomers());
  }

  @override
  void dispose() {
    _activityTypeController.dispose();
    _areaController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _resolveEstimatedTime() {
    final visitStartTime = widget.visit.startTime?.trim() ?? '';
    if (visitStartTime.isNotEmpty) {
      try {
        final parsed = DateFormat('hh:mm a').parseStrict(visitStartTime);
        return DateFormat('HH:mm:ss').format(parsed);
      } catch (_) {
        final rawMatch = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
        if (rawMatch.hasMatch(visitStartTime)) {
          return visitStartTime.length == 5
              ? '$visitStartTime:00'
              : visitStartTime;
        }
      }
    }
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  void _handleAddressSelection(VisitAddressModel? address) {
    setState(() {
      _selectedAddress = address;
      _areaController.text = address?.city ?? '';
    });
  }

  void _handleCustomerSelection(VisitCustomerModel? customer) {
    setState(() {
      _selectedCustomer = customer;
    });
  }

  void _handleActivityTypeSelection(String? activityType) {
    setState(() {
      _activityTypeController.text = activityType ?? '';
    });
  }

  void _submit(VisitState state) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service address is required')),
      );
      return;
    }

    if (_isCustomerVisit && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name is required')),
      );
      return;
    }

    final estimatedDuration = int.tryParse(_durationController.text.trim());
    if (estimatedDuration == null || estimatedDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid estimated duration')),
      );
      return;
    }

    final selectedAddress = _selectedAddress!;
    final customerDetails =
        _isCustomerVisit
            ? VisitActivityCustomerDetails(
              customerName: _selectedCustomer!.customerName,
              customerContactNumber: _customerPhoneController.text.trim(),
              customerAddress: _customerAddressController.text.trim(),
            )
            : null;
    final customerAddress =
        _isCustomerVisit
            ? VisitActivityCustomerAddress(
              label: selectedAddress.addressName,
              address: selectedAddress.addressName,
              city: selectedAddress.city,
              pincode: selectedAddress.pincode,
              latitude: selectedAddress.latitude ?? '',
              longitude: selectedAddress.longitude ?? '',
            )
            : null;
    final addressId = _isAddressVisit ? selectedAddress.id : null;

    context.read<VisitBloc>().add(
      CreateVisitActivityRequested(
        CreateVisitActivityParams(
          visitId: widget.visit.id,
          userId: context.read<VisitBloc>().currentUserId,
          activityType: _activityTypeController.text.trim(),
          customerId: _isCustomerVisit ? _selectedCustomer!.id : null,
          customerDetails: customerDetails,
          customerAddress: customerAddress,
          addressId: addressId,
          areaId: null,
          estimatedTime: _resolveEstimatedTime(),
          estimatedDuration: estimatedDuration,
          purpose: _descriptionController.text.trim(),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
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
            initialChildSize: 0.82,
            minChildSize: 0.58,
            maxChildSize: 0.95,
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
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg + keyboardInset,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.serviceBlueBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.primaryLight,
                              size: 24,
                            ),
                          ),
                          AppSpacing.vLg,
                          Text(
                            'Add Activity',
                            style: AppTextStyles.heading4(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vSm,
                          Text(
                            'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                            style: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                          AppSpacing.vLg,
                          _buildActivityTypeDropdown(context, state),
                          AppSpacing.vLg,
                          _buildAddressDropdown(context, state),
                          if (state.addressesError != null) ...[
                            AppSpacing.vSm,
                            _buildErrorText(context, state.addressesError!),
                          ],
                          AppSpacing.vLg,
                          _buildAreaField(
                            context,
                            label: 'Area',
                            hint: 'Select',
                            controller: _areaController,
                          ),
                          if (_isCustomerVisit) ...[
                            AppSpacing.vLg,
                            _buildCustomerDropdown(context, state),
                            if (state.customersError != null) ...[
                              AppSpacing.vSm,
                              _buildErrorText(context, state.customersError!),
                            ],
                            AppSpacing.vLg,
                            _buildTextField(
                              context,
                              label: 'Customer Phone No.',
                              hint: 'Enter',
                              controller: _customerPhoneController,
                              enabled: !state.isCreatingVisitActivity,
                              keyboardType: TextInputType.phone,
                              validator:
                                  (value) =>
                                      _isCustomerVisit &&
                                              (value == null ||
                                                  value.trim().isEmpty)
                                          ? 'Customer phone number is required'
                                          : null,
                            ),
                            AppSpacing.vLg,
                            _buildTextField(
                              context,
                              label: 'Customer Address',
                              hint: 'Enter',
                              controller: _customerAddressController,
                              enabled: !state.isCreatingVisitActivity,
                              minLines: 3,
                              maxLines: 3,
                              validator:
                                  (value) =>
                                      _isCustomerVisit &&
                                              (value == null ||
                                                  value.trim().isEmpty)
                                          ? 'Customer address is required'
                                          : null,
                            ),
                          ],
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Estimated Duration',
                            hint: 'Enter',
                            controller: _durationController,
                            enabled: !state.isCreatingVisitActivity,
                            keyboardType: TextInputType.number,
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Estimated duration is required'
                                        : null,
                          ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Description',
                            hint: 'Enter',
                            controller: _descriptionController,
                            enabled: !state.isCreatingVisitActivity,
                            minLines: 4,
                            maxLines: 4,
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Description is required'
                                        : null,
                          ),
                          AppSpacing.vXl,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  state.isCreatingVisitActivity
                                      ? null
                                      : () => _submit(state),
                              style: ElevatedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  state.isCreatingVisitActivity
                                      ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textWhite,
                                        ),
                                      )
                                      : Text(
                                        'Add Activity',
                                        style: AppTextStyles.buttonLarge(
                                          context,
                                        ),
                                      ),
                            ),
                          ),
                          AppSpacing.vMd,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  state.isCreatingVisitActivity
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.buttonLarge(
                                  context,
                                ).copyWith(color: AppColors.textPrimary),
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

  Widget _buildAddressDropdown(BuildContext context, VisitState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Address',
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(color: AppColors.textHeading),
        ),
        SizedBox(height: AppTextStyles.getSpacing(context, mobile: 8)),
        DropdownButtonFormField<VisitAddressModel>(
          initialValue: _selectedAddress,
          isExpanded: true,
          items: state.addresses
              .map(
                (address) => DropdownMenuItem<VisitAddressModel>(
                  value: address,
                  child: Text(
                    address.locationLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMediumHeading(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged:
              state.isCreatingVisitActivity || state.isAddressesLoading
                  ? null
                  : _handleAddressSelection,
          validator:
              (value) => value == null ? 'Service address is required' : null,
          decoration: InputDecoration(
            hintText: state.isAddressesLoading ? 'Loading...' : 'Select',
            hintStyle: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown(BuildContext context, VisitState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Name',
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(color: AppColors.textHeading),
        ),
        SizedBox(height: AppTextStyles.getSpacing(context, mobile: 8)),
        DropdownButtonFormField<VisitCustomerModel>(
          initialValue: _selectedCustomer,
          isExpanded: true,
          items: state.customers
              .map(
                (customer) => DropdownMenuItem<VisitCustomerModel>(
                  value: customer,
                  child: Text(
                    customer.customerName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMediumHeading(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged:
              state.isCreatingVisitActivity || state.isCustomersLoading
                  ? null
                  : _handleCustomerSelection,
          validator:
              (value) =>
                  _isCustomerVisit && value == null
                      ? 'Customer name is required'
                      : null,
          decoration: InputDecoration(
            hintText: state.isCustomersLoading ? 'Loading...' : 'Enter',
            hintStyle: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(color: AppColors.textHeading),
        ),
        SizedBox(height: AppTextStyles.getSpacing(context, mobile: 8)),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: AppTextStyles.bodyMediumHeading(
            context,
          ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.background,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    bool enabled = true,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(color: AppColors.textHeading),
        ),
        SizedBox(height: AppTextStyles.getSpacing(context, mobile: 8)),
        TextFormField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyMediumHeading(
            context,
          ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTypeDropdown(BuildContext context, VisitState state) {
    final selectedValue =
        _activityTypeController.text.trim().isEmpty
            ? null
            : _activityTypeController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Type',
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(color: AppColors.textHeading),
        ),
        SizedBox(height: AppTextStyles.getSpacing(context, mobile: 8)),
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          isExpanded: true,
          items: _activityTypeOptions
              .map(
                (activityType) => DropdownMenuItem<String>(
                  value: activityType,
                  child: Text(
                    activityType,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMediumHeading(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged:
              state.isCreatingVisitActivity
                  ? null
                  : _handleActivityTypeSelection,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Activity type is required'
                      : null,
          icon: const Icon(
            Icons.arrow_drop_down_sharp,
            color: AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: 'Select',
            hintStyle: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorText(BuildContext context, String message) {
    return Text(
      message,
      style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.error),
    );
  }
}
