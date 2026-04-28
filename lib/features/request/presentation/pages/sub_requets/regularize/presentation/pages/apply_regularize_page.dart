import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../../core/widgets/common/app_text_field.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../../../../../../attendance/data/datasources/attendance_regularize_remote_datasource.dart';
import '../../../../../../../attendance/data/repositories/attendance_regularize_repository_impl.dart';
import '../../../../../../../attendance/domain/usecases/apply_attendance_regularize_usecase.dart';
import '../../../../../../../attendance/domain/usecases/update_attendance_regularize_usecase.dart';
import '../../../../../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../bloc/apply_regularize_bloc.dart';
import '../../bloc/apply_regularize_event.dart';
import '../../bloc/apply_regularize_state.dart';
import '../../models/regularize_request_model.dart';

/// Apply Regularize form page
class ApplyRegularizePage extends StatefulWidget {
  final RegularizeRequestModel?
  regularizeRequest; // Optional: for editing existing regularize
  final DateTime? selectedDate; // Optional: pre-fill attendance date

  const ApplyRegularizePage({
    super.key,
    this.regularizeRequest,
    this.selectedDate,
  });

  @override
  State<ApplyRegularizePage> createState() => _ApplyRegularizePageState();
}

class _ApplyRegularizePageState extends State<ApplyRegularizePage> {
  static const List<String> _regularizeReasonOptions = [
    'Forgot to punch-in and punch-out',
    'Network issue',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _reasonController;
  late final TextEditingController _otherReasonController;
  late final ApplyRegularizeBloc _applyRegularizeBloc;
  late final CalendarBloc _calendarBloc;

  DateTime? _attendanceDate;
  int? _requestToId; // Store the reporting manager ID
  RegularizeRequestType _requestType = RegularizeRequestType.both;
  String? _captureMode;
  String? _selectedReason;
  TimeOfDay? _punchInTime;
  TimeOfDay? _punchOutTime;

  String _totalHours = '--';
  bool _isSubmitting = false;

  List<({String label, RegularizeRequestType value})> get _requestTypeOptions {
    return <({String label, RegularizeRequestType value})>[
      (label: 'Punch-in', value: RegularizeRequestType.punchIn),
      (label: 'Punch-out', value: RegularizeRequestType.punchOut),
      (label: 'Both', value: RegularizeRequestType.both),
    ];
  }

  List<String> get _modeTypeOptions {
    final options = <String>{'Remote', 'Web'};
    final currentMode = _captureMode?.trim();
    if (currentMode != null && currentMode.isNotEmpty) {
      options.add(currentMode);
    }
    return options.toList();
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _reasonController = TextEditingController();
    _otherReasonController = TextEditingController();

    // Initialize regularize BLoC
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = AttendanceRegularizeRemoteDataSourceImpl(
      apiClient,
    );
    final repository = AttendanceRegularizeRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    final applyRegularizeUseCase = ApplyAttendanceRegularizeUseCase(repository);
    final updateRegularizeUseCase = UpdateAttendanceRegularizeUseCase(
      repository,
    );
    _applyRegularizeBloc = ApplyRegularizeBloc(
      applyRegularizeUseCase: applyRegularizeUseCase,
      updateRegularizeUseCase: updateRegularizeUseCase,
    );

    // Initialize Calendar BLoC for leave validation
    _calendarBloc = CalendarBloc();
    final now = DateTime.now();
    _calendarBloc.add(LoadCalendarData(month: now.month, year: now.year));

    // Pre-fill attendance date if provided
    if (widget.selectedDate != null) {
      _attendanceDate = widget.selectedDate;
    }

    // If editing, pre-fill the form
    if (widget.regularizeRequest != null) {
      _initializeFormFromRegularizeRequest(widget.regularizeRequest!);
    }
  }

  void _initializeFormFromRegularizeRequest(
    RegularizeRequestModel regularizeRequest,
  ) {
    _attendanceDate = regularizeRequest.fromDate;
    _requestType = regularizeRequest.requestType;
    _captureMode = regularizeRequest.modeType;
    if (_regularizeReasonOptions
        .where((option) => option != 'Other')
        .contains(regularizeRequest.reason)) {
      _selectedReason = regularizeRequest.reason;
      _reasonController.text = regularizeRequest.reason;
    } else {
      _selectedReason = 'Other';
      _reasonController.text = regularizeRequest.reason;
      _otherReasonController.text = regularizeRequest.reason;
    }
    _descriptionController.text = regularizeRequest.description ?? '';
    if (regularizeRequest.checkIn != null) {
      _punchInTime = TimeOfDay.fromDateTime(regularizeRequest.checkIn!);
    }
    if (regularizeRequest.checkOut != null) {
      _punchOutTime = TimeOfDay.fromDateTime(regularizeRequest.checkOut!);
    }
    _calculateTotalHours();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _reasonController.dispose();
    _otherReasonController.dispose();
    _applyRegularizeBloc.close();
    _calendarBloc.close();
    super.dispose();
  }

  /// Convert request type enum to API format
  String _convertRequestType(RegularizeRequestType requestType) {
    switch (requestType) {
      case RegularizeRequestType.punchIn:
        return 'checkIn';
      case RegularizeRequestType.punchOut:
        return 'checkOut';
      case RegularizeRequestType.both:
        return 'both';
    }
  }

  String _convertRequestTypeForUpdate(RegularizeRequestType requestType) {
    switch (requestType) {
      case RegularizeRequestType.punchIn:
        return 'checkIn';
      case RegularizeRequestType.punchOut:
        return 'checkOut';
      case RegularizeRequestType.both:
        return 'both';
    }
  }

  /// Format date to yyyy-MM-dd
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date and time to API format: yyyy-MM-dd HH:mm:ss+05:30
  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    // Format: yyyy-MM-dd HH:mm:ss+05:30
    return '${DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime)}+05:30';
  }

  /// Handle form submission
  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_attendanceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an attendance date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (widget.regularizeRequest == null && _captureMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a capture mode'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate times based on request type
    if (_requestType == RegularizeRequestType.punchIn ||
        _requestType == RegularizeRequestType.both) {
      if (_punchInTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a punch-in time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_requestType == RegularizeRequestType.punchOut ||
        _requestType == RegularizeRequestType.both) {
      if (_punchOutTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a punch-out time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_punchInTime != null && _punchOutTime != null) {
      final punchInMinutes = _timeOfDayToMinutes(_punchInTime!);
      final punchOutMinutes = _timeOfDayToMinutes(_punchOutTime!);

      if (punchInMinutes >= punchOutMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Punch-in time should be before punch-out time.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final resolvedReason =
        _selectedReason == 'Other'
            ? _otherReasonController.text.trim()
            : (_selectedReason ?? '').trim();

    if (resolvedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedReason == 'Other'
                ? 'Please enter other reason'
                : 'Please select a reason',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _reasonController.text = resolvedReason;

    // Get user profile to get user_id
    final userProfileState = context.read<UserProfileBloc>().state;
    if (userProfileState is! UserProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User profile not loaded. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = userProfileState.profile.userId;
    final statusUpdatedBy =
        _requestToId ?? userProfileState.profile.reportingManager;

    // Format check-in and check-out times
    // Use default times if not provided based on request type
    final checkIn =
        (_requestType == RegularizeRequestType.punchIn ||
                _requestType == RegularizeRequestType.both)
            ? _formatDateTime(_attendanceDate!, _punchInTime!)
            : null;

    final checkOut =
        (_requestType == RegularizeRequestType.punchOut ||
                _requestType == RegularizeRequestType.both)
            ? _formatDateTime(_attendanceDate!, _punchOutTime!)
            : null;

    // Dispatch apply regularize event
    if (widget.regularizeRequest != null) {
      _applyRegularizeBloc.add(
        UpdateRegularize(
          id: int.tryParse(widget.regularizeRequest!.id) ?? 0,
          requestDate: _formatDate(_attendanceDate!),
          requestFor: _convertRequestTypeForUpdate(_requestType),
          checkIn: checkIn,
          checkOut: checkOut,
          statusUpdatedBy: statusUpdatedBy,
          description: _descriptionController.text.trim(),
        ),
      );
      return;
    }

    _applyRegularizeBloc.add(
      ApplyRegularize(
        requestDate: _formatDate(_attendanceDate!),
        requestFor: _convertRequestType(_requestType),
        modeType: _captureMode!,
        checkIn: checkIn,
        checkOut: checkOut,
        reason: _selectedReason == 'Other' ? 'Other' : resolvedReason,
        otherReason:
            _selectedReason == 'Other'
                ? _otherReasonController.text.trim()
                : null,
        description: _descriptionController.text.trim(),
        userId: userId,
        isOther: _selectedReason == 'Other',
      ),
    );
  }

  /// Returns true if [date] is marked as a leave day in the calendar data.
  bool _isLeaveDate(DateTime date) {
    if (_calendarBloc.state is! CalendarLoaded) {
      return false;
    }
    final days = (_calendarBloc.state as CalendarLoaded).days;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return days.any((d) => d.date.startsWith(dateStr) && d.status == 'Leave');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = _attendanceDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.attendanceTeal,
              onPrimary: AppColors.textWhite,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Block dates where user was on leave
      if (_isLeaveDate(picked)) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Cannot Regularize'),
                  content: const Text(
                    'You were on leave on this date. Regularization is not allowed for leave days.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
        return; // Do NOT update the selected date
      }
      setState(() {
        _attendanceDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPunchIn) async {
    final TimeOfDay initialTime =
        isPunchIn
            ? (_punchInTime ?? const TimeOfDay(hour: 9, minute: 0))
            : (_punchOutTime ?? const TimeOfDay(hour: 18, minute: 0));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.attendanceTeal,
              onPrimary: AppColors.textWhite,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isPunchIn) {
          _punchInTime = picked;
        } else {
          _punchOutTime = picked;
        }
        _calculateTotalHours();
      });
    }
  }

  void _calculateTotalHours() {
    if (_punchInTime != null && _punchOutTime != null) {
      final punchInMinutes = _punchInTime!.hour * 60 + _punchInTime!.minute;
      final punchOutMinutes = _punchOutTime!.hour * 60 + _punchOutTime!.minute;

      if (punchOutMinutes > punchInMinutes) {
        final totalMinutes = punchOutMinutes - punchInMinutes;
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        _totalHours = '$hours:${minutes.toString().padLeft(2, '0')}';
      } else {
        _totalHours = '--';
      }
    } else {
      _totalHours = '--';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  bool get _showsPunchInField =>
      _requestType == RegularizeRequestType.punchIn ||
      _requestType == RegularizeRequestType.both;

  bool get _showsPunchOutField =>
      _requestType == RegularizeRequestType.punchOut ||
      _requestType == RegularizeRequestType.both;

  bool get _showsTotalHours => _requestType == RegularizeRequestType.both;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _applyRegularizeBloc),
        BlocProvider.value(value: _calendarBloc),
      ],
      child: BlocListener<ApplyRegularizeBloc, ApplyRegularizeState>(
        listener: (context, state) {
          if (state is ApplyRegularizeApplying) {
            setState(() {
              _isSubmitting = true;
            });
          } else if (state is ApplyRegularizeApplied) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.result.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          } else if (state is ApplyRegularizeError) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocListener<UserProfileBloc, UserProfileState>(
          listener: (context, profileState) {
            // Initialize reporting manager when profile is loaded
            if (profileState is UserProfileLoaded && _requestToId == null) {
              final profile = profileState.profile;
              if (profile.reportingManagerInfo != null) {
                setState(() {
                  _requestToId = profile.reportingManager;
                });
              }
            }
          },
          child: ResponsiveScaffold(
            backgroundColor: AppColors.backgroundMedium,

            appBar: AppBar(
              elevation: 0,
              forceMaterialTransparency: true,
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: screenWidth * 0.048),
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
              leadingWidth: 110,
              title: Text(
                widget.regularizeRequest != null
                    ? 'Edit Regularize Request'
                    : AppStrings.regularize,
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
              padding: EdgeInsets.all(screenWidth * 0.020),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attendance Day
                    Text(
                      'Attendance Day',
                      style: AppTextStyles.labelLarge(context),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    _buildDateField(
                      context,
                      value:
                          _attendanceDate != null
                              ? DateFormat(
                                'dd MMM yyyy',
                              ).format(_attendanceDate!)
                              : null,
                      hint: 'Select Date',
                      onTap: () => _selectDate(context),
                    ),

                    SizedBox(height: screenHeight * 0.02),
                    // Request Type (Radio Buttons)
                    Text(
                      'Request Type',
                      style: AppTextStyles.labelLarge(context),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: List.generate(_requestTypeOptions.length, (
                        index,
                      ) {
                        final option = _requestTypeOptions[index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right:
                                  index == _requestTypeOptions.length - 1
                                      ? 0
                                      : screenWidth * 0.02,
                            ),
                            child: _buildRadioOption(
                              context,
                              label: option.label,
                              value: option.value,
                              groupValue: _requestType,
                              onChanged: (value) {
                                setState(() {
                                  _requestType = value!;
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Capture Mode (Mode Type)
                    _buildDropdownField(
                      context,
                      label: 'Mode Type',
                      value: _captureMode,
                      items: _modeTypeOptions,
                      hint: 'Select Mode Type',
                      onChanged: (value) {
                        setState(() {
                          _captureMode = value;
                        });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Punch In
                    if (_showsPunchInField) ...[
                      Text('Punch In', style: AppTextStyles.labelLarge(context)),
                      SizedBox(height: screenHeight * 0.01),
                      _buildTimeField(
                        context,
                        value:
                            _punchInTime != null
                                ? _formatTimeOfDay(_punchInTime!)
                                : null,
                        hint: 'Enter Punch-in time',
                        onTap: () => _selectTime(context, true),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                    if (_showsPunchOutField) ...[
                      Text(
                        'Punch Out',
                        style: AppTextStyles.labelLarge(context),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      _buildTimeField(
                        context,
                        value:
                            _punchOutTime != null
                                ? _formatTimeOfDay(_punchOutTime!)
                                : null,
                        hint: 'Enter Punch-out time',
                        onTap: () => _selectTime(context, false),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                    if (_showsTotalHours) ...[
                      Row(
                        children: [
                          Text(
                            'Total Hours: ',
                            style: AppTextStyles.labelLarge(context),
                          ),
                          Text(
                            _totalHours,
                            style: AppTextStyles.labelLarge(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.attendanceTeal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                    if (widget.regularizeRequest == null) ...[
                      _buildDropdownField(
                        context,
                        label: 'Reason',
                        value: _selectedReason,
                        items: _regularizeReasonOptions,
                        hint: 'Select Reason',
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value;
                            if (value != 'Other') {
                              _reasonController.text = value ?? '';
                              _otherReasonController.clear();
                            } else {
                              _reasonController.clear();
                            }
                          });
                        },
                      ),
                      if (_selectedReason == 'Other') ...[
                        SizedBox(height: screenHeight * 0.02),
                        AppTextField(
                          label: 'Other Reason',
                          hint: 'Enter Other Reason',
                          controller: _otherReasonController,
                          validator: (value) {
                            if (_selectedReason == 'Other' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter other reason';
                            }
                            return null;
                          },
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.02),
                    ],
                    // Description
                    AppTextField(
                      label: 'Description',
                      hint: 'Enter Description',
                      controller: _descriptionController,
                      maxLines: 4,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
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
                                  widget.regularizeRequest != null
                                      ? 'Update'
                                      : 'Submit',
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
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
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
                          AppStrings.cancel,
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
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    String? label,
    required String? value,
    String? hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
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
            initialValue: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),

            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.01,
                vertical: screenHeight * 0.018,
              ),
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: AppTextStyles.bodyMedium(context)),
                  );
                }).toList(),
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

  Widget _buildTimeField(
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
              Icons.access_time,
              size: screenWidth * 0.05,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context, {
    required String label,
    required RegularizeRequestType value,
    required RegularizeRequestType? groupValue,
    required Function(RegularizeRequestType?) onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSelected = value == groupValue;

    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () => onChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenHeight * 0.015,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.attendanceTeal : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              margin: EdgeInsets.only(top: screenHeight * 0.002),
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color:
                    isSelected
                        ? AppColors.attendanceTeal
                        : AppColors.backgroundMedium,
              ),
              child:
                  isSelected
                      ? Icon(
                        Icons.check,
                        size: screenWidth * 0.04,
                        color: Colors.white,
                      )
                      : Icon(
                        Icons.circle,
                        size: screenWidth * 0.04,
                        color: Colors.white,
                      ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color:
                      isSelected
                          ? AppColors.attendanceTeal
                          : AppColors.textPrimary,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
