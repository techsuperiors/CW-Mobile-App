import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/common/app_text_field.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../attendance/data/datasources/attendance_details_remote_datasource.dart';
import '../../../../../../../attendance/data/models/attendance_day_detail_model.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../bloc/apply_overtime_bloc.dart';
import '../../bloc/apply_overtime_event.dart';
import '../../bloc/apply_overtime_state.dart';
import '../../data/datasources/overtime_remote_datasource.dart';
import '../../data/repositories/overtime_repository_impl.dart';
import '../../domain/entities/overtime_detail.dart';
import '../../domain/usecases/create_overtime_request.dart';
import '../../domain/usecases/update_overtime_request.dart';
import '../../models/overtime_request_model.dart';

class ApplyOvertimePage extends StatefulWidget {
  final OvertimeRequestModel? overtimeRequest;
  final OvertimeDetail? overtimeDetail;

  const ApplyOvertimePage({
    super.key,
    this.overtimeRequest,
    this.overtimeDetail,
  });

  @override
  State<ApplyOvertimePage> createState() => _ApplyOvertimePageState();
}

class _ApplyOvertimePageState extends State<ApplyOvertimePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final ApplyOvertimeBloc _applyOvertimeBloc;
  late final AttendanceDetailsRemoteDataSourceImpl _attendanceDataSource;

  DateTime? _requestDate;

  // Auto-filled from API (read-only)
  DateTime? _checkInDateTime;
  DateTime? _checkOutDateTime;
  int? _overtimeTotalSeconds; // over_time.total from API

  bool _isLoadingAttendance = false;
  String? _attendanceError;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.overtimeRequest?.subject,
    );
    _descriptionController = TextEditingController(
      text: widget.overtimeDetail?.description ?? '',
    );

    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

    _attendanceDataSource = AttendanceDetailsRemoteDataSourceImpl(apiClient);

    final remoteDataSource = OvertimeRemoteDataSourceImpl(apiClient: apiClient);
    final repository = OvertimeRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    _applyOvertimeBloc = ApplyOvertimeBloc(
      createOvertimeRequestUseCase: CreateOvertimeRequestUseCase(repository),
      updateOvertimeRequestUseCase: UpdateOvertimeRequestUseCase(repository),
    );

    // If editing, pre-fill with existing data
    if (widget.overtimeRequest != null) {
      _requestDate = widget.overtimeRequest!.requestDate;
      if (widget.overtimeDetail?.checkIn != null) {
        _checkInDateTime = widget.overtimeDetail!.checkIn;
      }
      if (widget.overtimeDetail?.checkOut != null) {
        _checkOutDateTime = widget.overtimeDetail!.checkOut;
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _applyOvertimeBloc.close();
    super.dispose();
  }

  /// Called when user picks a date — fetches attendance detail for that day
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
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
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _requestDate = picked;
      _checkInDateTime = null;
      _checkOutDateTime = null;
      _overtimeTotalSeconds = null;
      _attendanceError = null;
    });

    // Fetch attendance data for the picked date
    final userState = context.read<UserProfileBloc>().state;
    if (userState is! UserProfileLoaded) return;
    final userId = userState.profile.userId;
    _fetchAttendanceForDate(userId, picked);
  }

  /// Converts a local date to the API's expected UTC ISO string:
  /// e.g. 2026-03-05 → "2026-03-04T18:30:00.000Z" (previous day 18:30 UTC = midnight IST)
  String _toApiDate(DateTime date) {
    final prev = date.subtract(const Duration(days: 1));
    return '${DateFormat('yyyy-MM-dd').format(prev)}T18:30:00.000Z';
  }

  Future<void> _fetchAttendanceForDate(int userId, DateTime date) async {
    setState(() => _isLoadingAttendance = true);
    try {
      final apiDate = _toApiDate(date);
      final AttendanceDayDetailModel model = await _attendanceDataSource
          .getAttendanceDayDetail(userId: userId, date: apiDate);

      final effectivePunchIn =
          (model.regularizePunchIn?.trim().isNotEmpty ?? false)
              ? model.regularizePunchIn
              : model.punchIn;
      final effectivePunchOut =
          (model.regularizePunchOut?.trim().isNotEmpty ?? false)
              ? model.regularizePunchOut
              : model.punchOut;

      final punchIn = DateTime.tryParse(effectivePunchIn ?? '')?.toLocal();
      final punchOut = DateTime.tryParse(effectivePunchOut ?? '')?.toLocal();

      setState(() {
        _checkInDateTime = punchIn;
        _checkOutDateTime = punchOut;
        _overtimeTotalSeconds = model.overTime?.total;
        _isLoadingAttendance = false;
        _attendanceError = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingAttendance = false;
        _attendanceError = 'Could not load attendance data for this date';
        _checkInDateTime = null;
        _checkOutDateTime = null;
        _overtimeTotalSeconds = null;
      });
    }
  }

  /// Format DateTime to display time (e.g. "10:26 AM")
  String _formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  /// Format total overtime seconds to "Xh Ym"
  String _formatOvertimeDuration(int? totalSeconds) {
    if (totalSeconds == null) return '-- h -- m';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_requestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a request date')),
      );
      return;
    }
    if (_checkInDateTime == null || _checkOutDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check-in/out data not available for the selected date',
          ),
        ),
      );
      return;
    }

    final userState = context.read<UserProfileBloc>().state;
    if (userState is! UserProfileLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User profile not loaded')));
      return;
    }
    final userId = userState.profile.userId;

    final requestDate = DateFormat('yyyy-MM-dd').format(_requestDate!);
    final checkIn = _checkInDateTime!.toUtc().toIso8601String();
    final checkOut = _checkOutDateTime!.toUtc().toIso8601String();

    if (widget.overtimeRequest == null) {
      _applyOvertimeBloc.add(
        CreateOvertime(
          requestDate: requestDate,
          checkIn: checkIn,
          checkOut: checkOut,
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
          userId: userId,
        ),
      );
    } else {
      _applyOvertimeBloc.add(
        UpdateOvertime(
          requestId: int.tryParse(widget.overtimeRequest!.id) ?? 0,
          requestDate: requestDate,
          checkIn: checkIn,
          checkOut: checkOut,
          userId: userId,
          description: _descriptionController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isEdit = widget.overtimeRequest != null;

    return BlocProvider.value(
      value: _applyOvertimeBloc,
      child: BlocListener<ApplyOvertimeBloc, ApplyOvertimeState>(
        listener: (context, state) {
          if (state is ApplyOvertimeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is ApplyOvertimeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<ApplyOvertimeBloc, ApplyOvertimeState>(
          builder: (context, state) {
            final isSubmitting = state is ApplyOvertimeSubmitting;
            return Stack(
              children: [
                ResponsiveScaffold(
                  backgroundColor: AppColors.backgroundLight,
                  appBar: AppBar(
                    forceMaterialTransparency: true,
                    elevation: 0,
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
                      isEdit ? 'Edit Overtime' : 'Apply Overtime',
                      style: AppTextStyles.heading4(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                          // ── Attendance Day* label ──
                          Text(
                            'Attendance Day',
                            style: AppTextStyles.labelLarge(context),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          // Date picker field
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              width: double.infinity,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _requestDate != null
                                        ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_requestDate!)
                                        : 'Select date',
                                    style: AppTextStyles.bodyMedium(
                                      context,
                                    ).copyWith(
                                      color:
                                          _requestDate != null
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
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // ── Check In & Check Out (read-only, auto-filled) ──
                          if (_isLoadingAttendance) ...[
                            const Center(child: CircularProgressIndicator()),
                            SizedBox(height: screenHeight * 0.025),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReadOnlyTimeField(
                                    context,
                                    label: 'Check-In Time',
                                    value:
                                        _checkInDateTime != null
                                            ? _formatTime(_checkInDateTime!)
                                            : '--',
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: _buildReadOnlyTimeField(
                                    context,
                                    label: 'Check-Out Time',
                                    value:
                                        _checkOutDateTime != null
                                            ? _formatTime(_checkOutDateTime!)
                                            : '--',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // ── Total Overtime hours ──
                            Row(
                              children: [
                                Text(
                                  'Total Overtime hours: ',
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatOvertimeDuration(_overtimeTotalSeconds),
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(
                                    color: AppColors.attendanceTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),

                            // Error message if attendance couldn't load
                            if (_attendanceError != null) ...[
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                _attendanceError!,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.error),
                              ),
                            ],
                            SizedBox(height: screenHeight * 0.02),
                          ],

                          // ── Subject ──
                          if (!isEdit) ...[
                            AppTextField(
                              label: 'Subject',
                              hint: 'Enter subject',
                              controller: _subjectController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a subject';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            _buildReadOnlyLabeledField(
                              context,
                              label: 'Subject',
                              value: _subjectController.text,
                            ),
                          ],
                          SizedBox(height: screenHeight * 0.02),

                          // ── Description ──
                          AppTextField(
                            label: 'Description',
                            hint: 'Enter description',
                            controller: _descriptionController,
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // ── Submit Button ──
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _handleSubmit,
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
                                disabledBackgroundColor:
                                    AppColors.textSecondary,
                              ),
                              child:
                                  isSubmitting
                                      ? SizedBox(
                                        height: screenHeight * 0.02,
                                        width: screenHeight * 0.02,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.textWhite,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        isEdit ? 'Update' : 'Apply',
                                        style: AppTextStyles.buttonLarge(
                                          context,
                                        ).copyWith(color: AppColors.textWhite),
                                      ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),

                          // ── Cancel Button ──
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
                ),
                if (isSubmitting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Read-only time display field (with clock icon)
  Widget _buildReadOnlyTimeField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
        SizedBox(height: screenHeight * 0.01),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.018,
          ),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color:
                      value == '--'
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
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
      ],
    );
  }

  /// Labeled read-only text display (for subject in edit mode)
  Widget _buildReadOnlyLabeledField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
        SizedBox(height: screenHeight * 0.01),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.018,
          ),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            value,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
