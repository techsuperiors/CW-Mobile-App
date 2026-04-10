import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../../core/widgets/common/app_text_field.dart';
import '../../../../../../../leaves/data/datasources/leave_types_remote_datasource.dart';
import '../../../../../../../leaves/data/models/leave_policy_model.dart';
import '../../../../../../../leaves/data/repositories/leave_types_repository_impl.dart';
import '../../../../../../../leaves/domain/usecases/get_leave_types_usecase.dart';
import '../../../../../../../leaves/domain/usecases/apply_leave_usecase.dart';
import '../../../../../../../leaves/domain/usecases/delete_leave_file_usecase.dart';
import '../../../../../../../leaves/domain/usecases/update_leave_usecase.dart';
import '../../../../../../../leaves/domain/usecases/upload_leave_files_usecase.dart';
import '../../../../../../../leaves/presentation/bloc/leave_types_bloc.dart';
import '../../../../../../../leaves/presentation/bloc/leave_types_event.dart';
import '../../../../../../../leaves/presentation/bloc/leave_types_state.dart';
import '../../../../../../../services/presentation/pages/sub_services/leave/presentation/bloc/leave_request_bloc.dart';
import '../../../../../../../services/presentation/pages/sub_services/leave/presentation/bloc/leave_request_event.dart';
import '../../../../../../../services/presentation/pages/sub_services/leave/presentation/bloc/leave_request_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../domain/entities/leave_entity.dart';

/// Apply Leave form page
class ApplyLeavePage extends StatefulWidget {
  final LeaveEntity? leaveRequest; // Optional: for editing existing leave

  const ApplyLeavePage({super.key, this.leaveRequest});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  static const List<String> _reasonOptions = [
    'Personal',
    'Medical',
    'Family',
    'Other',
  ];
  static const String _singleDayOption = 'Single Day';
  static const String _multipleDaysOption = 'Multiple Days';
  static const String _halfDayOption = 'Half Day';
  static const String _shortLeaveOption = 'Short Leave';
  static const List<String> _halfDayOptions = ['First Half', 'Second Half'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final LeaveRequestBloc _leaveRequestBloc;
  late final LeaveTypesRemoteDataSource _leaveRemoteDataSource;

  String? _selectedLeaveType;
  String? _selectedLeaveDuration;
  DateTime? _fromDate;
  String _fromHalfDay = 'First Half';
  DateTime? _selectedToDate;
  String _toHalfDay = 'Second Half';
  bool _clubLeave = false; // Default to false to match payload
  int? _requestToId; // Store the reporting manager ID
  String? _selectedReason;
  bool _isSubmitting = false;

  ///For image picking
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingImage =
      false; //To restrcit the multiple instance of imagepicker
  List<File> _selectedFiles = [];
  List<LeaveAttachmentRef> _existingAttachments = [];
  bool _isUploadingFiles = false;
  String? _deletingExistingFileId;
  bool _hasDeletedExistingAttachment = false;
  UpdateLeave? _pendingUpdateEvent;
  Map<String, LeavePolicyModel> _leavePoliciesByType = {};
  WorkingHoursModel? _workingHours;
  bool _isLoadingLeavePolicies = false;
  bool _isLoadingWorkingHours = false;
  TimeOfDay? _leaveStartTime;
  TimeOfDay? _leaveEndTime;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();

    // Initialize BLoC (only for applying - leave types come from LeaveTypesBloc/dashboard)
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo,onTokenExpired: () {
      AppNavigator.pushAndRemoveAll(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    },);
    _leaveRemoteDataSource = LeaveTypesRemoteDataSourceImpl(apiClient);
    final repository = LeaveTypesRepositoryImpl(
      remoteDataSource: _leaveRemoteDataSource,
      networkInfo: networkInfo,
    );
    _leaveRequestBloc = LeaveRequestBloc(
      getLeaveTypesUseCase: GetLeaveTypesUseCase(repository),
      applyLeaveUseCase: ApplyLeaveUseCase(repository),
      updateLeaveUseCase: UpdateLeaveUseCase(repository),
      uploadLeaveFilesUseCase: UploadLeaveFilesUseCase(repository),
      deleteLeaveFileUseCase: DeleteLeaveFileUseCase(repository),
    );

    // If editing, pre-fill the form
    if (widget.leaveRequest != null) {
      _initializeFormFromLeaveRequest(widget.leaveRequest!);
    }

    final profileState = context.read<UserProfileBloc>().state;
    _hydrateRequestToFromProfileState(profileState);
    _loadLeavePoliciesFromProfileState(profileState);
  }

  void _initializeFormFromLeaveRequest(LeaveEntity leaveRequest) {
    // Pre-fill leave type
    _selectedLeaveType = leaveRequest.leaveType;

    // Pre-fill dates
    _fromDate = leaveRequest.fromDate;
    _selectedToDate = leaveRequest.toDate;

    // Determine leave duration
    _selectedLeaveDuration =
        leaveRequest.toDate == null ? 'Single Day' : 'Multiple Days';

    // Pre-fill reason/description
    _descriptionController.text = leaveRequest.reason;
    _subjectController.text = leaveRequest.subject ?? leaveRequest.leaveType;
    _existingAttachments = List<LeaveAttachmentRef>.from(
      leaveRequest.fileAttachments,
    );

    // Keep the existing reason selected when possible.
    _selectedReason =
        _reasonOptions.contains(leaveRequest.reason)
            ? leaveRequest.reason
            : null;
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

  String _formatApiTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes:00';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final value = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('hh:mm a').format(value);
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  LeavePolicyModel? get _selectedLeavePolicy {
    final selectedLeaveType = _selectedLeaveType;
    if (selectedLeaveType == null) return null;
    return _leavePoliciesByType[selectedLeaveType];
  }

  bool get _supportsHalfDay => _selectedLeavePolicy?.allowHalfDayLeave == true;

  bool get _supportsShortLeave => _selectedLeavePolicy?.allowShortLeave == true;

  bool get _supportsClubLeave => _selectedLeavePolicy?.allowClubLeave == true;

  bool get _isShortLeave => _selectedLeaveDuration == _shortLeaveOption;

  bool get _isHalfDay => _selectedLeaveDuration == _halfDayOption;

  bool get _isSingleDay => _selectedLeaveDuration == _singleDayOption;

  bool get _isMultipleDays => _selectedLeaveDuration == _multipleDaysOption;

  List<String> _leaveDurationOptions() {
    final options = <String>[_singleDayOption, _multipleDaysOption];
    if (_supportsHalfDay) {
      options.add(_halfDayOption);
    }
    if (_supportsShortLeave) {
      options.add(_shortLeaveOption);
    }
    return options;
  }

  void _syncDurationWithPolicy() {
    final allowedOptions = _leaveDurationOptions();
    if (_selectedLeaveDuration != null &&
        !allowedOptions.contains(_selectedLeaveDuration)) {
      _selectedLeaveDuration = null;
    }

    if (!_supportsClubLeave) {
      _clubLeave = false;
    }

    if (!_isHalfDay) {
      _fromHalfDay = _halfDayOptions.first;
      _toHalfDay = _halfDayOptions.last;
    }

    if (!_isShortLeave) {
      _leaveStartTime = null;
      _leaveEndTime = null;
      _workingHours = null;
    }

    if (!_isMultipleDays) {
      _selectedToDate = null;
    }
  }

  Future<void> _loadLeavePoliciesFromProfileState(
    UserProfileState profileState,
  ) async {
    if (profileState is! UserProfileLoaded || _isLoadingLeavePolicies) return;

    setState(() {
      _isLoadingLeavePolicies = true;
    });

    try {
      final policies = await _leaveRemoteDataSource.getLeavePolicies(
        profileState.profile.userId,
      );
      if (!mounted) return;
      setState(() {
        _leavePoliciesByType = {
          for (final policy in policies) policy.leaveTypeName: policy,
        };
        _syncDurationWithPolicy();
        _isLoadingLeavePolicies = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLeavePolicies = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load leave policy: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadWorkingHoursForDate(DateTime date) async {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is! UserProfileLoaded) return;

    setState(() {
      _isLoadingWorkingHours = true;
    });

    try {
      final workingHours = await _leaveRemoteDataSource.getWorkingHours(
        userId: profileState.profile.userId,
        date: _formatDate(date),
      );
      if (!mounted) return;
      setState(() {
        _workingHours = workingHours;
        _isLoadingWorkingHours = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWorkingHours = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load working hours: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Handle form submission
  void _handleSubmit() {
    _hydrateRequestToFromProfileState(context.read<UserProfileBloc>().state);

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

    if (_selectedLeaveDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a leave duration'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isMultipleDays && _selectedToDate == null) {
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

    if (_isShortLeave) {
      if (_leaveStartTime == null || _leaveEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select leave start and end time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final startDateTime = _combineDateAndTime(_fromDate!, _leaveStartTime!);
      final endDateTime = _combineDateAndTime(_fromDate!, _leaveEndTime!);
      if (!endDateTime.isAfter(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Leave end time must be after start time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final fullDayHours = _workingHours?.fullDayHours ?? 0;
      final shortDayHours = _workingHours?.shortDayHours ?? 0;
      final maxShortLeaveSeconds = fullDayHours - shortDayHours;
      if (maxShortLeaveSeconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Working hours are not available for the selected date',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final selectedSeconds = endDateTime.difference(startDateTime).inSeconds;
      if (selectedSeconds > maxShortLeaveSeconds) {
        final allowedDuration = Duration(seconds: maxShortLeaveSeconds);
        final hours = allowedDuration.inHours;
        final minutes = allowedDuration.inMinutes.remainder(60);
        final allowedText =
            minutes == 0 ? '$hours hour(s)' : '$hours hour(s) $minutes min';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Short leave cannot exceed $allowedText for the selected date',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Determine dates based on leave duration
    DateTime startDate;
    DateTime endDate;
    String dayType;
    String? startHalf;
    String? endHalf;
    String? leaveStartTime;
    String? leaveEndTime;

    if (_isSingleDay) {
      startDate = _fromDate!;
      endDate = _fromDate!;
      dayType = 'single';
      startHalf = 'first_half';
      endHalf = 'second_half';
    } else if (_isHalfDay) {
      startDate = _fromDate!;
      endDate = _fromDate!;
      dayType = 'half';
      startHalf = _convertHalfDay(_fromHalfDay);
      endHalf = startHalf;
    } else if (_isShortLeave) {
      startDate = _fromDate!;
      endDate = _fromDate!;
      dayType = 'short';
      startHalf = null;
      endHalf = null;
      leaveStartTime = _formatApiTime(_leaveStartTime!);
      leaveEndTime = _formatApiTime(_leaveEndTime!);
    } else {
      startDate = _fromDate!;
      endDate = _selectedToDate!;
      dayType = 'multiple';
      startHalf = _convertHalfDay(_fromHalfDay);
      endHalf = _convertHalfDay(_toHalfDay);

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

    if (widget.leaveRequest != null) {
      final updateEvent = UpdateLeave(
        leaveId: int.tryParse(widget.leaveRequest!.id) ?? 0,
        leaveType: _selectedLeaveType!,
        clubing: const [null],
        isClubbing: _clubLeave,
        startDate: _formatDate(startDate),
        endDate: dayType == 'single' ? null : _formatDate(endDate),
        subject: _subjectController.text.trim(),
        reason: _selectedReason ?? '',
        startHalf: startHalf ?? 'first_half',
        endHalf: endHalf ?? 'second_half',
        dayType: dayType,
        description: _descriptionController.text.trim(),
        requestTo: _requestToId!,
      );

      if (_selectedFiles.isNotEmpty) {
        _pendingUpdateEvent = updateEvent;
        _leaveRequestBloc.add(
          UploadLeaveFiles(leaveId: updateEvent.leaveId, files: _selectedFiles),
        );
      } else {
        _leaveRequestBloc.add(updateEvent);
      }
      return;
    }

    _leaveRequestBloc.add(
      ApplyLeave(
        leaveType: _selectedLeaveType!,
        clubing: '',
        isClubbing: _clubLeave,
        startDate: _formatDate(startDate),
        endDate: _formatDate(endDate),
        subject: _subjectController.text.trim(),
        reason: _selectedReason ?? '',
        startHalf: startHalf,
        endHalf: endHalf,
        dayType: dayType,
        description: _descriptionController.text.trim(),
        shortCode: _getShortCode(_selectedLeaveType),
        requestTo: _requestToId!,
        leaveStartTime: leaveStartTime,
        leaveEndTime: leaveEndTime,
        rHDates: [],
        attachmentFiles: _selectedFiles,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime initialDate =
        isFromDate
            ? (_fromDate ?? DateTime.now())
            : (_selectedToDate ?? _fromDate ?? DateTime.now());

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
          if (!_isMultipleDays) {
            _selectedToDate = null;
          }
        } else {
          _selectedToDate = picked;
        }
      });

      if (_isShortLeave) {
        await _loadWorkingHoursForDate(picked);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime =
        isStartTime
            ? (_leaveStartTime ?? const TimeOfDay(hour: 9, minute: 0))
            : (_leaveEndTime ?? const TimeOfDay(hour: 10, minute: 0));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
        if (isStartTime) {
          _leaveStartTime = picked;
        } else {
          _leaveEndTime = picked;
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
          } else if (state is LeaveFilesUploading) {
            setState(() {
              _isUploadingFiles = true;
            });
          } else if (state is LeaveFileDeleting) {
            setState(() {
              _deletingExistingFileId = state.fileId;
            });
          } else if (state is LeaveFileDeleted) {
            setState(() {
              _existingAttachments.removeWhere(
                (file) => file.fileId == state.fileId,
              );
              _deletingExistingFileId = null;
              _hasDeletedExistingAttachment = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is LeaveFilesUploaded) {
            setState(() {
              _isUploadingFiles = false;
            });
            final pendingUpdateEvent = _pendingUpdateEvent;
            _pendingUpdateEvent = null;
            if (pendingUpdateEvent != null) {
              _leaveRequestBloc.add(pendingUpdateEvent);
            }
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
          } else if (state is LeaveRequestUpdated) {
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
              _isUploadingFiles = false;
              _deletingExistingFileId = null;
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
              _hydrateRequestToFromProfileState(profileState);
              unawaited(_loadLeavePoliciesFromProfileState(profileState));
              // Load leave types if not yet loaded (e.g. user opened Apply Leave before dashboard)
              final leaveTypesState = context.read<LeaveTypesBloc>().state;
              if (leaveTypesState is LeaveTypesInitial) {
                context.read<LeaveTypesBloc>().add(
                  LoadLeaveTypes(profile.userId),
                );
              }
            }
          },
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              Navigator.of(context).pop(_hasDeletedExistingAttachment);
            },
            child: ResponsiveScaffold(
              backgroundColor: AppColors.backgroundMedium,
              appBar:
              AppBar(
                forceMaterialTransparency: true,
                elevation: 0,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                leading: GestureDetector(
                  onTap:
                      () => Navigator.of(
                        context,
                      ).pop(_hasDeletedExistingAttachment),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: screenWidth * 0.048,
                      ),
                      Flexible(
                        child: Text(
                          AppStrings.back,
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
                  widget.leaveRequest != null
                      ? 'Edit Leave Request'
                      : AppStrings.applyLeave,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w500,
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

                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          final leaveTypeItems =
                              leaveTypesState is LeaveTypesLoaded
                                  ? leaveTypesState.leaveTypes.leaveTypes
                                      .map((lt) => lt.leaveType)
                                      .where(
                                        (leaveType) =>
                                            leaveType.trim().toUpperCase() !=
                                            'LOP',
                                      )
                                      .toList()
                                  : <String>[];
                          final isLoading =
                              leaveTypesState is LeaveTypesLoading ||
                              leaveTypesState is LeaveTypesInitial;
                          final hasError = leaveTypesState is LeaveTypesError;

                          return _buildDropdownField(
                            context,
                            label: 'Leave Type',
                            value: _selectedLeaveType,
                            hint:
                                isLoading
                                    ? 'Loading...'
                                    : hasError
                                    ? 'Visit dashboard first to load leave types'
                                    : 'Select Leave Type',
                            items: leaveTypeItems,
                            onChanged:
                                isLoading || hasError
                                    ? null
                                    : (value) {
                                      setState(() {
                                        _selectedLeaveType = value;
                                        _syncDurationWithPolicy();
                                      });
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
                        hint:
                            _selectedLeaveType == null
                                ? 'Select leave type first'
                                : _isLoadingLeavePolicies
                                ? 'Loading leave policy...'
                                : 'Select Day Type',
                        items: _leaveDurationOptions(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLeaveDuration = value;
                            if (value != _multipleDaysOption) {
                              _selectedToDate = null;
                            }
                            if (value != _shortLeaveOption) {
                              _leaveStartTime = null;
                              _leaveEndTime = null;
                              _workingHours = null;
                            }
                            if (value != _halfDayOption) {
                              _fromHalfDay = _halfDayOptions.first;
                            }
                          });
                          if (value == _shortLeaveOption && _fromDate != null) {
                            unawaited(_loadWorkingHoursForDate(_fromDate!));
                          }
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Date fields
                      if (_isSingleDay) ...[
                        Text(
                          'Date',
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        _buildDateField(
                          context,
                          value:
                              _fromDate != null
                                  ? DateFormat('dd MMM yyyy').format(_fromDate!)
                                  : null,
                          hint: 'Select Date',
                          onTap: () => _selectDate(context, true),
                        ),
                      ] else if (_isHalfDay) ...[
                        Text(
                          'Date',
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                context,
                                value:
                                    _fromDate != null
                                        ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_fromDate!)
                                        : null,
                                hint: 'Select Date',
                                onTap: () => _selectDate(context, true),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: _buildDropdownField(
                                context,
                                value: _fromHalfDay,
                                items: _halfDayOptions,
                                label: '',
                                showLabel: false,
                                onChanged: (value) {
                                  setState(() {
                                    _fromHalfDay =
                                        value ?? _halfDayOptions.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else if (_isShortLeave) ...[
                        Text(
                          'Date',
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        _buildDateField(
                          context,
                          value:
                              _fromDate != null
                                  ? DateFormat('dd MMM yyyy').format(_fromDate!)
                                  : null,
                          hint: 'Select Date',
                          onTap: () => _selectDate(context, true),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(
                                context,
                                label: 'From Time',
                                value:
                                    _leaveStartTime != null
                                        ? _formatTimeOfDay(_leaveStartTime!)
                                        : null,
                                hint: 'Select Start Time',
                                onTap: () => _selectTime(context, true),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: _buildTimeField(
                                context,
                                label: 'To Time',
                                value:
                                    _leaveEndTime != null
                                        ? _formatTimeOfDay(_leaveEndTime!)
                                        : null,
                                hint: 'Select End Time',
                                onTap: () => _selectTime(context, false),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoadingWorkingHours) ...[
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Loading working hours...',
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                        ] else if (_workingHours != null) ...[
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Max allowed: ${_formatDurationLabel(_workingHours!.fullDayHours - _workingHours!.shortDayHours)}',
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'From',
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildDateField(
                                context,
                                value:
                                    _fromDate != null
                                        ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_fromDate!)
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
                                items: _halfDayOptions,
                                label: '',
                                onChanged: (value) {
                                  setState(() {
                                    _fromHalfDay =
                                        value ?? _halfDayOptions.first;
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
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildDateField(
                                context,
                                value:
                                    _selectedToDate != null
                                        ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_selectedToDate!)
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
                                items: _halfDayOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _toHalfDay = value ?? _halfDayOptions.last;
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
                      if (_supportsClubLeave) ...[
                        Text(
                          'Club Leave',
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        SizedBox(height: screenHeight * 0.02),
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
                        SizedBox(height: screenHeight * 0.02),
                      ],

                      _buildDropdownField(
                        context,
                        label: 'Reason',
                        value: _selectedReason,
                        hint: 'Select Reason',
                        items: _reasonOptions,
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
                        maxLines: 3,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Upload
                      Text(
                        'Upload',
                        style: AppTextStyles.labelLarge(
                          context,
                        ).copyWith(color: AppColors.textHeading),
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
                                    widget.leaveRequest != null
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
                            Navigator.of(
                              context,
                            ).pop(_hasDeletedExistingAttachment);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            side: BorderSide(color: AppColors.border),
                            backgroundColor: AppColors.background,
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
      ),
    );
  }

  void _hydrateRequestToFromProfileState(UserProfileState profileState) {
    if (profileState is! UserProfileLoaded) return;

    final profile = profileState.profile;
    if (_requestToId != null || profile.reportingManagerInfo == null) return;

    _requestToId = profile.reportingManager;
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
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(color: AppColors.textHeading),
          ),
          SizedBox(height: screenHeight * 0.01),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),

          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            hint: Text(
              hint ?? '',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400, // 👈 force normal
              ),
            ),
            decoration: InputDecoration(
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.018,
              ),
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: AppTextStyles.bodyMediumHeading(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
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
            Flexible(
              child: Text(
                value ?? hint,
                style: AppTextStyles.bodyMediumHeading(context).copyWith(
                  color:
                      value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
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
    required String label,
    String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
         SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        _buildDateField(context, value: value, hint: hint, onTap: onTap),
      ],
    );
  }

  String _formatDurationLabel(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        final files = images.map((x) => File(x.path)).toList();
        setState(() {
          _selectedFiles = [..._selectedFiles, ...files];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _deleteExistingAttachment(LeaveAttachmentRef attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete file'),
          content: Text('Delete "${attachment.name}" from this leave request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    _leaveRequestBloc.add(
      DeleteLeaveFile(
        leaveFileId: attachment.leaveFileId,
        fileId: attachment.fileId,
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double thumbSize = screenWidth * 0.28;
    final hasAnyAttachments =
        _existingAttachments.isNotEmpty || _selectedFiles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAnyAttachments)
          SizedBox(
            height: thumbSize + 8,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingAttachments.length + _selectedFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isExistingFile = index < _existingAttachments.length;
                final existingAttachment =
                    isExistingFile ? _existingAttachments[index] : null;
                final localFile =
                    !isExistingFile
                        ? _selectedFiles[index - _existingAttachments.length]
                        : null;
                final previewSource =
                    existingAttachment?.url ?? localFile!.path;
                final isPdf = previewSource.toLowerCase().endsWith('.pdf');
                final isDeletingExisting =
                    existingAttachment != null &&
                    _deletingExistingFileId == existingAttachment.fileId;

                return Stack(
                  children: [
                    GestureDetector(
                      onTap:
                          isDeletingExisting
                              ? null
                              : isExistingFile
                              ? () => _previewNetworkFile(
                                context,
                                url: existingAttachment!.url,
                              )
                              : () =>
                                  _previewLocalFile(context, file: localFile!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            isPdf
                                ? Container(
                                  width: thumbSize,
                                  height: thumbSize,
                                  color: AppColors.background,
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red,
                                        size: screenWidth * 0.09,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _fileNameFromSource(previewSource),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.labelSmall(
                                          context,
                                        ).copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : isExistingFile
                                ? Image.network(
                                  existingAttachment!.url,
                                  width: thumbSize,
                                  height: thumbSize,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        width: thumbSize,
                                        height: thumbSize,
                                        color: AppColors.background,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppColors.textSecondary,
                                          size: screenWidth * 0.06,
                                        ),
                                      ),
                                )
                                : Image.file(
                                  localFile!,
                                  width: thumbSize,
                                  height: thumbSize,
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                    if (isExistingFile)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Existing',
                            style: AppTextStyles.labelSmall(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap:
                            isExistingFile
                                ? isDeletingExisting
                                    ? null
                                    : () => _deleteExistingAttachment(
                                      existingAttachment!,
                                    )
                                : () => setState(
                                  () => _selectedFiles.removeAt(
                                    index - _existingAttachments.length,
                                  ),
                                ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child:
                              isExistingFile && isDeletingExisting
                                  ? SizedBox(
                                    width: screenWidth * 0.032,
                                    height: screenWidth * 0.032,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: screenWidth * 0.035,
                                  ),
                        ),
                      ),
                    ),
                    if (!isExistingFile)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'New',
                            style: AppTextStyles.labelSmall(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        if (hasAnyAttachments) SizedBox(height: screenHeight * 0.02),
        if (_isUploadingFiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: screenWidth * 0.04,
                  height: screenWidth * 0.04,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Uploading files...',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        // Add / Upload button
        GestureDetector(
          onTap: _isUploadingFiles ? null : _pickImage,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasAnyAttachments
                      ? Icons.add_photo_alternate_outlined
                      : Icons.file_upload_outlined,
                  size: screenWidth * 0.06,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  hasAnyAttachments ? 'Add More' : 'Upload File',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                color:
                    groupValue == value
                        ? AppColors.attendanceTeal
                        : AppColors.border,
                width: 2,
              ),
            ),
            child:
                groupValue == value
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
          Text(label, style: AppTextStyles.bodyMediumHeading(context)),
        ],
      ),
    );
  }

  String _fileNameFromSource(String source) {
    final normalized = source.split('?').first;
    if (normalized.contains('/')) {
      return normalized.split('/').last;
    }
    return normalized;
  }

  void _previewNetworkFile(BuildContext context, {required String url}) {
    if (url.toLowerCase().endsWith('.pdf')) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 50,
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PDF Preview',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SfPdfViewer.network(url)),
              ],
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _previewLocalFile(BuildContext context, {required File file}) {
    if (file.path.toLowerCase().endsWith('.pdf')) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 50,
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PDF Preview',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SfPdfViewer.file(file)),
              ],
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(child: Image.file(file, fit: BoxFit.contain)),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
