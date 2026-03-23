import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/common/app_text_field.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../bloc/raise_on_duty_bloc.dart';
import '../../bloc/raise_on_duty_event.dart';
import '../../bloc/raise_on_duty_state.dart';
import '../../data/datasources/on_duty_remote_datasource.dart';
import '../../data/repositories/on_duty_repository_impl.dart';
import '../../domain/usecases/raise_on_duty_request.dart';

/// Form page to raise an On-Duty request
class OnDutyRequestPage extends StatefulWidget {
  const OnDutyRequestPage({super.key});

  @override
  State<OnDutyRequestPage> createState() => _OnDutyRequestPageState();
}

class _OnDutyRequestPageState extends State<OnDutyRequestPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final RaiseOnDutyRequestBloc _bloc;

  String _requestTo = '';
  String _requestType = 'single'; // 'single' or 'multiple'
  DateTime? _startDate;
  DateTime? _endDate;
  String _startHalf = 'first_half';
  String _endHalf = 'second_half';
  bool _isSubmitting = false;

  static const List<String> _halfDayOptions = ['First Half', 'Second Half'];
  static const List<String> _durationOptions = [
    'Single Day On Duty',
    'Multiple Days On Duty',
  ];

  String _toApiHalf(String displayHalf) =>
      displayHalf == 'First Half' ? 'first_half' : 'second_half';

  String _toDisplayHalf(String apiHalf) =>
      apiHalf == 'first_half' ? 'First Half' : 'Second Half';

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _formatDisplayDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();

    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = OnDutyRemoteDataSourceImpl(apiClient: apiClient);
    final repository = OnDutyRepositoryImpl(remoteDataSource: remoteDataSource);
    _bloc = RaiseOnDutyRequestBloc(
      raiseOnDutyRequestUseCase: RaiseOnDutyRequestUseCase(repository),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _handleSubmit(int userId) {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      _showSnackBar('Please select a start date', isError: true);
      return;
    }

    if (_requestType == 'multiple') {
      if (_endDate == null) {
        _showSnackBar('Please select an end date', isError: true);
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        _showSnackBar('End date cannot be before start date', isError: true);
        return;
      }
    }

    // final startDateStr = _formatDate(_startDate!);
    // // For 'single', API still needs both start & end — use same date
    // final endDateStr =
    //     _requestType == 'single' ? startDateStr : _formatDate(_endDate!);
    // // Debugging request values
    final startDateStr = _formatDate(_startDate!);
    final isSingle = _requestType == 'single';

    final endDateStr = isSingle ? startDateStr : _formatDate(_endDate!);
    final finalStartHalf = isSingle ? 'first_half' : _startHalf;
    final finalEndHalf = isSingle ? 'second_half' : _endHalf;

    _bloc.add(
      SubmitOnDutyRequest(
        subject: _subjectController.text.trim(),
        requestType: _requestType,
        description: _descriptionController.text.trim(),
        startDate: startDateStr,
        endDate: endDateStr,
        startHalf: finalStartHalf,
        // Use overridden value
        endHalf: finalEndHalf,
        // Use overridden value
        userId: userId,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final initial =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      // initialDate: initial,
      // firstDate: DateTime.now().subtract(const Duration(days: 365)),
      // lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate:
          isStart
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? _startDate ?? DateTime.now()),
      // FIX: Agar End Date select kar rahe ho, toh First Date "Start Date" honi chahiye
      firstDate:
          !isStart && _startDate != null
              ? _startDate!
              : DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.attendanceTeal,
                onPrimary: AppColors.textWhite,
                surface: AppColors.background,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Optimization: Agar Start Date change ki aur wo End Date ke baad chali gayi, toh End Date reset kardo
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<RaiseOnDutyRequestBloc, RaiseOnDutyRequestState>(
        listener: (context, state) {
          if (state is RaiseOnDutyRequestSubmitting) {
            setState(() => _isSubmitting = true);
          } else if (state is RaiseOnDutyRequestSuccess) {
            setState(() => _isSubmitting = false);
            _showSnackBar(state.message);
            Navigator.of(context).pop(true);
          } else if (state is RaiseOnDutyRequestFailure) {
            setState(() => _isSubmitting = false);
            _showSnackBar(state.message, isError: true);
          }
        },
        child: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, profileState) {
            final userId =
                profileState is UserProfileLoaded
                    ? profileState.profile.userId
                    : 0;

            return ResponsiveScaffold(
              appBar: AppBar(
                forceMaterialTransparency: true,
                elevation: 0,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: screenWidth * 0.048,
                      ),
                      Flexible(
                        child: Text(
                          'Back',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  'Raise On-Duty Request',
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                centerTitle: true,
              ),
              bottomNavigationBar: BottomNavBar(
                currentIndex: 3,
                onTap: NavigationHelper.getBottomNavHandler(context),
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.002),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      // Header
                      // Row(
                      //   children: [
                      //     Container(
                      //       padding: const EdgeInsets.all(12),
                      //       decoration: BoxDecoration(
                      //         color: AppColors.attendanceTeal.withOpacity(0.1),
                      //         shape: BoxShape.circle,
                      //       ),
                      //       child: Icon(
                      //         Icons.home_outlined,
                      //         color: AppColors.attendanceTeal,
                      //         size: screenWidth * 0.07,
                      //       ),
                      //     ),
                      //     SizedBox(width: screenWidth * 0.04),
                      //     Expanded(
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Text(
                      //             'On-duty',
                      //             style: AppTextStyles.heading3(
                      //               context,
                      //             ).copyWith(
                      //               fontWeight: FontWeight.w600,
                      //               color: AppColors.textPrimary,
                      //             ),
                      //           ),
                      //           SizedBox(height: screenHeight * 0.005),
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // SizedBox(height: screenHeight * 0.035),

                      // Subject
                      AppTextField(
                        label: 'Subject',
                        hint: 'Enter Subject',
                        controller: _subjectController,

                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Subject is required'
                                    : null,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Request To (Manager)
                      Builder(
                        builder: (context) {
                          List<String> managerItems = [];
                          if (profileState is UserProfileLoaded) {
                            final profile = profileState.profile;
                            if (profile.reportingManagerInfo != null) {
                              managerItems = [
                                profile.reportingManagerInfo!.fullName,
                              ];
                            }
                          }
                          if (managerItems.isEmpty)
                            managerItems = ['Loading...'];

                          // Initialize if not set
                          if (!managerItems.contains(_requestTo)) {
                            _requestTo = managerItems.first;
                          }

                          return _buildDropdownField(
                            context,
                            label: 'Request To',
                            value: _requestTo,
                            items: managerItems,
                            onChanged: (val) {
                              if (val != null) setState(() => _requestTo = val);
                            },
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Request Type / Duration
                      _buildDropdownField(
                        context,
                        label: 'On duty duration',
                        value:
                            _requestType == 'single'
                                ? _durationOptions[0]
                                : _durationOptions[1],
                        items: _durationOptions,
                        onChanged: (val) {
                          setState(() {
                            _requestType =
                                val == _durationOptions[0]
                                    ? 'single'
                                    : 'multiple';
                            if (_requestType == 'single') _endDate = null;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Date section — single or multiple
                      if (_requestType == 'single') ...[
                        Text(
                          'On duty (Day or Days)',
                          style: AppTextStyles.labelLarge(context),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        _buildDateField(
                          context,
                          value:
                              _startDate != null
                                  ? _formatDisplayDate(_startDate!)
                                  : null,
                          hint: 'Select date',
                          onTap: () => _selectDate(true),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        if (_requestType == 'multiple') ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  context,
                                  label: 'Start Half',
                                  value: _toDisplayHalf(_startHalf),
                                  items: _halfDayOptions,
                                  onChanged:
                                      (val) => setState(
                                        () => _startHalf = _toApiHalf(val!),
                                      ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: _buildDropdownField(
                                  context,
                                  label: 'End Half',
                                  value: _toDisplayHalf(_endHalf),
                                  items: _halfDayOptions,
                                  onChanged:
                                      (val) => setState(
                                        () => _endHalf = _toApiHalf(val!),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        // From
                        Text(
                          'From (Day or Days)',
                          style: AppTextStyles.labelLarge(context),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                context,
                                value:
                                    _startDate != null
                                        ? _formatDisplayDate(_startDate!)
                                        : null,
                                hint: 'Select date',
                                onTap: () => _selectDate(true),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: _buildDropdownField(
                                context,
                                label: '',
                                value: _toDisplayHalf(_startHalf),
                                items: _halfDayOptions,
                                showLabel: false,
                                onChanged:
                                    (val) => setState(
                                      () => _startHalf = _toApiHalf(val!),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // To
                        Text(
                          'To (Day or Days)',
                          style: AppTextStyles.labelLarge(context),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                context,
                                value:
                                    _endDate != null
                                        ? _formatDisplayDate(_endDate!)
                                        : null,
                                hint: 'Select date',
                                onTap: () => _selectDate(false),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: _buildDropdownField(
                                context,
                                label: '',
                                value: _toDisplayHalf(_endHalf),
                                items: _halfDayOptions,
                                showLabel: false,
                                onChanged:
                                    (val) => setState(
                                      () => _endHalf = _toApiHalf(val!),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.02),

                      // Description
                      AppTextField(
                        label: 'Description',
                        hint: 'Enter Description',
                        controller: _descriptionController,
                        maxLines: 2,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Description is required'
                                    : null,
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () => _handleSubmit(userId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.attendanceTeal,
                            foregroundColor: AppColors.textWhite,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: AppColors.textSecondary,
                          ),
                          child:
                              _isSubmitting
                                  ? SizedBox(
                                    height: screenHeight * 0.02,
                                    width: screenHeight * 0.02,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textWhite,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'Submit Request',
                                    style: AppTextStyles.buttonLarge(
                                      context,
                                    ).copyWith(color: AppColors.textWhite),
                                  ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String? label,
    required String? value,
    String? hint,
    required List<String> items,
    Function(String?)? onChanged,
    bool showLabel = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null && label.isNotEmpty) ...[
          Text(label, style: AppTextStyles.labelLarge(context)),
          SizedBox(height: screenHeight * 0.01),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),

          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.01,
                vertical: screenHeight * 0.01,
              ),
            ),
            items:
                items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.018,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hint,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color:
                    value != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: screenWidth * 0.05,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
