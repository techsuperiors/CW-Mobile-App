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
import '../../../../../../../leaves/data/datasources/leave_types_remote_datasource.dart';
import '../../../../../../../leaves/data/repositories/leave_types_repository_impl.dart';
import '../../../../../../../leaves/domain/usecases/get_leave_types_usecase.dart';
import '../../../../../../../leaves/domain/usecases/apply_leave_usecase.dart';
import '../../../../../../../leaves/presentation/bloc/leave_types_bloc.dart';
import '../../../../../../../leaves/presentation/bloc/leave_types_event.dart';
import '../../../../../../../leaves/presentation/bloc/leave_types_state.dart';
import '../../../../../../../services/presentation/pages/sub_services/leave/presentation/bloc/leave_request_bloc.dart';
import '../../../../../../../services/presentation/pages/sub_services/leave/presentation/bloc/leave_request_event.dart';
import '../../../../../../../services/presentation/pages/sub_services/leave/presentation/bloc/leave_request_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../models/leave_request_model.dart';

/// Apply Leave form page
class ApplyLeavePage extends StatefulWidget {
  final LeaveRequestModel? leaveRequest; // Optional: for editing existing leave

  const ApplyLeavePage({super.key, this.leaveRequest});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final LeaveRequestBloc _leaveRequestBloc;
  
  String? _selectedLeaveType;
  String? _selectedLeaveDuration;
  DateTime? _fromDate;
  String _fromHalfDay = 'First Half';
  DateTime? _toDate;
  String _toHalfDay = 'Second Half';
  bool _clubLeave = false; // Default to false to match payload
  String? _selectedClubLeaveType;
  String? _requestTo;
  int? _requestToId; // Store the reporting manager ID
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // Initialize BLoC (only for applying - leave types come from LeaveTypesBloc/dashboard)
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final repository = LeaveTypesRepositoryImpl(
      remoteDataSource: LeaveTypesRemoteDataSourceImpl(apiClient),
      networkInfo: networkInfo,
    );
    _leaveRequestBloc = LeaveRequestBloc(
      getLeaveTypesUseCase: GetLeaveTypesUseCase(repository),
      applyLeaveUseCase: ApplyLeaveUseCase(repository),
    );
    
    // If editing, pre-fill the form
    if (widget.leaveRequest != null) {
      _initializeFormFromLeaveRequest(widget.leaveRequest!);
    }
  }

  void _initializeFormFromLeaveRequest(LeaveRequestModel leaveRequest) {
    // Pre-fill leave type
    _selectedLeaveType = leaveRequest.leaveType;
    
    // Pre-fill dates
    _fromDate = leaveRequest.fromDate;
    _toDate = leaveRequest.toDate;
    
    // Determine leave duration
    _selectedLeaveDuration = leaveRequest.toDate == null ? 'Single Day' : 'Multiple Days';
    
    // Pre-fill reason/description
    _descriptionController.text = leaveRequest.reason;
    _subjectController.text = leaveRequest.leaveType; // Use leave type as subject
    
    // Set default values for other fields
    _selectedReason = 'Personal'; // Default, can be enhanced if reason is stored separately
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _leaveRequestBloc.close();
    super.dispose();
  }

  /// Get short code from leave type
  String _getShortCode(String? leaveType) {
    if (leaveType == null) return '';
    switch (leaveType) {
      case 'Sick Leave':
        return 'SL';
      case 'Casual Leave':
        return 'CL';
      case 'Earned Leave':
        return 'EL';
      case 'Emergency Leave':
        return 'EL';
      default:
        return leaveType.substring(0, 2).toUpperCase();
    }
  }

  /// Convert half day string to API format
  String _convertHalfDay(String halfDay) {
    if (halfDay == 'First Half') {
      return 'first_half';
    } else if (halfDay == 'Second Half') {
      return 'second_half';
    }
    return 'first_half';
  }

  /// Format date to yyyy-MM-dd
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Handle form submission
  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a leave type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a start date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedLeaveDuration == 'Multiple Days' && _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an end date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a subject'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Determine dates based on leave duration
    DateTime startDate;
    DateTime endDate;
    
    if (_selectedLeaveDuration == 'Single Day') {
      // For Single Day: start_date and end_date must be the same
      startDate = _fromDate!;
      endDate = _fromDate!; // Same date for single day
    } else {
      // For Multiple Days: start_date and end_date should be different
      startDate = _fromDate!;
      endDate = _toDate!;
      
      // Validate that end date is not before start date
      if (endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('End date cannot be before start date'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Determine day type
    final dayType = _selectedLeaveDuration == 'Single Day' ? 'single' : 'multiple';

    // Validate request_to is selected
    if (_requestToId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a manager to request to'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Dispatch apply leave event
    _leaveRequestBloc.add(
      ApplyLeave(
        leaveType: _selectedLeaveType!,
        clubing: '', // Always send empty string as per requirement
        isClubbing: _clubLeave, // true if Yes, false if No
        startDate: _formatDate(startDate),
        endDate: _formatDate(endDate),
        subject: _subjectController.text.trim(),
        reason: _selectedReason ?? '',
        startHalf: _convertHalfDay(_fromHalfDay),
        endHalf: _convertHalfDay(_toHalfDay),
        dayType: dayType,
        description: _descriptionController.text.trim(),
        shortCode: _getShortCode(_selectedLeaveType),
        requestTo: _requestToId!,
        rHDates: [],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime initialDate = isFromDate
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider.value(
      value: _leaveRequestBloc,
      child: BlocListener<LeaveRequestBloc, LeaveRequestState>(
        listener: (context, state) {
          if (state is LeaveRequestApplying) {
            setState(() {
              _isSubmitting = true;
            });
          } else if (state is LeaveRequestApplied) {
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
          } else if (state is LeaveRequestError) {
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
            if (profileState is UserProfileLoaded) {
              final profile = profileState.profile;
              // Initialize reporting manager when profile is loaded
              if (_requestToId == null && profile.reportingManagerInfo != null) {
                setState(() {
                  _requestTo = profile.reportingManagerInfo!.fullName;
                  _requestToId = profile.reportingManager;
                });
              }
              // Load leave types if not yet loaded (e.g. user opened Apply Leave before dashboard)
              final leaveTypesState = context.read<LeaveTypesBloc>().state;
              if (leaveTypesState is LeaveTypesInitial) {
                context.read<LeaveTypesBloc>().add(LoadLeaveTypes(profile.userId));
              }
            }
          },
          child: ResponsiveScaffold(
            appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: screenWidth * 0.048,),
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: screenWidth * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.attendance,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
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
          AppStrings.applyLeave,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: NavigationHelper.getBottomNavHandler(context),
            ),
            body: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.020),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header with icon and description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.attendanceTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppColors.attendanceTeal,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    widget.leaveRequest != null ? 'Edit Leave Request' : AppStrings.applyLeave,
                    style: AppTextStyles.heading3(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              // Subject
              AppTextField(
                label: 'Subject',
                hint: 'Enter Subject',
                controller: _subjectController,
              ),
              SizedBox(height: screenHeight * 0.02),
              // Leave Type (from dashboard LeaveTypesBloc - no API call here)
              BlocBuilder<LeaveTypesBloc, LeaveTypesState>(
                builder: (context, leaveTypesState) {
                  final leaveTypeItems = leaveTypesState is LeaveTypesLoaded
                      ? leaveTypesState.leaveTypes.leaveTypes
                          .map((lt) => lt.leaveType)
                          .toList()
                      : <String>[];
                  final isLoading = leaveTypesState is LeaveTypesLoading ||
                      leaveTypesState is LeaveTypesInitial;
                  final hasError = leaveTypesState is LeaveTypesError;

                  return _buildDropdownField(
                    context,
                    label: 'Leave Type',
                    value: _selectedLeaveType,
                    hint: isLoading
                        ? 'Loading...'
                        : hasError
                            ? 'Visit dashboard first to load leave types'
                            : 'Select Leave Type',
                    items: leaveTypeItems,
                    onChanged: isLoading || hasError
                        ? null
                        : (value) {
                            setState(() => _selectedLeaveType = value);
                          },
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Leave Duration
              _buildDropdownField(
                context,
                label: 'Leave Duration (Day or Days)',
                value: _selectedLeaveDuration,
                hint: 'Select Day Type',
                items: ['Single Day', 'Multiple Days'],
                onChanged: (value) {
                  setState(() {
                    _selectedLeaveDuration = value;
                    // Clear toDate when switching to Single Day
                    if (value == 'Single Day') {
                      _toDate = null;
                    }
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Date fields - Show different layout based on Single Day or Multiple Days
              if (_selectedLeaveDuration == 'Single Day') ...[
                // Single Day - Show only one date field (no half-day dropdown)
                Text(
                  'Date',
                  style: AppTextStyles.labelLarge(context),
                ),
                SizedBox(height: screenHeight * 0.01),
                _buildDateField(
                  context,
                  value: _fromDate != null
                      ? DateFormat('dd MMM yyyy').format(_fromDate!)
                      : null,
                  hint: 'Select Date',
                  onTap: () => _selectDate(context, true),
                ),
              ] else ...[
                // Multiple Days - Show From and To fields
                // From
                Text(
                  'From',
                  style: AppTextStyles.labelLarge(context),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildDateField(
                        context,
                        value: _fromDate != null
                            ? DateFormat('dd MMM yyyy').format(_fromDate!)
                            : null,
                        hint: 'Select Date',
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      flex: 1,
                      child: _buildDropdownField(
                        context,
                        value: _fromHalfDay,
                        items: ['First Half', 'Second Half'],
                        label: '',
                        onChanged: (value) {
                          setState(() {
                            _fromHalfDay = value ?? 'First Half';
                          });
                        },
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                // To
                Text(
                  'To',
                  style: AppTextStyles.labelLarge(context),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildDateField(
                        context,
                        value: _toDate != null
                            ? DateFormat('dd MMM yyyy').format(_toDate!)
                            : null,
                        hint: 'Select Date',
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      flex: 1,
                      child: _buildDropdownField(
                        context,
                        value: _toHalfDay,
                        items: ['First Half', 'Second Half'],
                        onChanged: (value) {
                          setState(() {
                            _toHalfDay = value ?? 'Second Half';
                          });
                        },
                        showLabel: false,
                        label: '',
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: screenHeight * 0.02),
              // Club Leave
              Text(
                'Club Leave',
                style: AppTextStyles.labelLarge(context),
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      context,
                      label: 'Yes',
                      value: true,
                      groupValue: _clubLeave,
                      onChanged: (value) {
                        setState(() {
                          _clubLeave = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildRadioOption(
                      context,
                      label: 'No',
                      value: false,
                      groupValue: _clubLeave,
                      onChanged: (value) {
                        setState(() {
                          _clubLeave = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              // Club Leave Type dropdown is disabled - always send empty string
              // The dropdown is kept hidden as per requirement
              SizedBox(height: screenHeight * 0.02),
              // Request To - Get from user profile
              BlocBuilder<UserProfileBloc, UserProfileState>(
                builder: (context, profileState) {
                  List<String> managerItems = [];
                  
                  if (profileState is UserProfileLoaded) {
                    final profile = profileState.profile;
                    if (profile.reportingManagerInfo != null) {
                      final managerName = profile.reportingManagerInfo!.fullName;
                      managerItems = [managerName];
                    }
                  }
                  
                  // Show loading or placeholder if profile not loaded
                  if (managerItems.isEmpty) {
                    managerItems = ['Loading...'];
                  }
                  
                  return _buildDropdownField(
                    context,
                    label: 'Request To',
                    value: _requestTo,
                    items: managerItems,
                    onChanged: (value) {
                      setState(() {
                        _requestTo = value;
                        // Update ID when profile is loaded
                        if (profileState is UserProfileLoaded) {
                          _requestToId = profileState.profile.reportingManager;
                        }
                      });
                    },
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Reason
              _buildDropdownField(
                context,
                label: 'Reason',
                value: _selectedReason,
                hint: 'Select Reason',
                items: ['Personal', 'Medical', 'Family', 'Other'],
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Description
              AppTextField(
                label: 'Description',
                hint: 'Enter Description',
                controller: _descriptionController,
                maxLines: 4,
              ),
              SizedBox(height: screenHeight * 0.02),
              // Upload
              Text(
                'Upload',
                style: AppTextStyles.labelLarge(context),
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildUploadButton(context),
              SizedBox(height: screenHeight * 0.03),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.attendanceTeal,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.textSecondary,
                  ),
                  child: _isSubmitting
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
                          widget.leaveRequest != null ? 'Update' : 'Submit',
                          style: AppTextStyles.buttonLarge(context).copyWith(
                            color: AppColors.textWhite,
                          ),
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
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancel,
                    style: AppTextStyles.buttonLarge(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
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
        if (showLabel && label != null) ...[
          Text(
            label,
            style: AppTextStyles.labelLarge(context),
          ),
          SizedBox(height: screenHeight * 0.01),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.018,
              ),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: AppTextStyles.bodyMedium(context),
                ),
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
                color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
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

  Widget _buildRadioOption(
    BuildContext context, {
    required String label,
    required bool value,
    required bool? groupValue,
    required Function(bool) onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.05,
            height: screenWidth * 0.05,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: groupValue == value
                    ? AppColors.attendanceTeal
                    : AppColors.border,
                width: 2,
              ),
            ),
            child: groupValue == value
                ? Center(
                    child: Container(
                      width: screenWidth * 0.025,
                      height: screenWidth * 0.025,
                      decoration: BoxDecoration(
                        color: AppColors.attendanceTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            label,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        // Handle file upload
      },
      child: Container(
        width: screenWidth * 0.25,
        height: screenWidth * 0.25,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload,
              size: screenWidth * 0.06,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: screenHeight * 0.005),
            Text(
              'Upload File',
              style: AppTextStyles.labelSmall(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

