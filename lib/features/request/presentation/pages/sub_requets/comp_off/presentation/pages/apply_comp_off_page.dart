import 'package:collectivWork/core/constants/app_strings.dart';
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
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../bloc/apply_comp_off_bloc.dart';
import '../../bloc/apply_comp_off_event.dart';
import '../../bloc/apply_comp_off_state.dart';
import '../../data/datasources/comp_off_remote_datasource.dart';
import '../../data/repositories/comp_off_repository_impl.dart';
import '../../domain/usecases/create_comp_off_request.dart';
import '../../domain/usecases/update_comp_off_request.dart';
import '../../models/comp_off_request_model.dart';

class ApplyCompOffPage extends StatefulWidget {
  final CompOffRequestModel? compOffRequest;

  const ApplyCompOffPage({super.key, this.compOffRequest});

  @override
  State<ApplyCompOffPage> createState() => _ApplyCompOffPageState();
}

class _ApplyCompOffPageState extends State<ApplyCompOffPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _reasonController;
  late final TextEditingController _durationController;
  late final ApplyCompOffBloc _bloc;

  String _type = 'Day';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.compOffRequest?.subject ?? '',
    );
    _reasonController = TextEditingController(
      text: widget.compOffRequest?.reason ?? '',
    );
    _durationController = TextEditingController(
      text: widget.compOffRequest?.duration ?? '',
    );

    _type = widget.compOffRequest?.type ?? 'Day';
    _selectedDate = widget.compOffRequest?.date;

    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remote = CompOffRemoteDataSourceImpl(apiClient: apiClient);
    final repo = CompOffRepositoryImpl(remoteDataSource: remote);
    _bloc = ApplyCompOffBloc(
      createCompOffRequestUseCase: CreateCompOffRequestUseCase(repo),
      updateCompOffRequestUseCase: UpdateCompOffRequestUseCase(repo),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _reasonController.dispose();
    _durationController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isEdit = widget.compOffRequest != null;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ApplyCompOffBloc, ApplyCompOffState>(
        listener: (context, state) {
          if (state is ApplyCompOffSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is ApplyCompOffError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<ApplyCompOffBloc, ApplyCompOffState>(
          builder: (context, state) {
            final isSubmitting = state is ApplyCompOffSubmitting;
            return Stack(
              children: [
                ResponsiveScaffold(
                  appBar: AppBar(
                    forceMaterialTransparency: true,
                    elevation: 0,
                    leadingWidth: 110,

                    leading: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                      isEdit ? 'Edit Comp-Off' : 'Apply Comp-Off',
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
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.004,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Subject',
                            hint: 'Enter subject',
                            controller: _subjectController,
                            validator:
                                (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Subject is required'
                                        : null,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            AppStrings.lockdurationin,
                            style: AppTextStyles.labelLarge(context).copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildTypeDropdown(context),
                          SizedBox(height: screenHeight * 0.02),
                          _buildDatePicker(context),
                          SizedBox(height: screenHeight * 0.02),
                          // Duration field: hidden for Day, visible for Hours
                          if (_type == 'Hours') ...[
                            _buildDurationField(context),
                            SizedBox(height: screenHeight * 0.02),
                          ],
                          AppTextField(
                            label: 'Reason',
                            hint: 'Enter reason',
                            controller: _reasonController,
                            maxLines: 3,
                            validator:
                                (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Reason is required'
                                        : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _handleSubmit,
                              child: Text(isEdit ? 'Update' : 'Submit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isSubmitting)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.04,
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width * 0.01,
            vertical: MediaQuery.sizeOf(context).height * 0.01,
          ),
        ),
        value: _type,
        items: const [
          DropdownMenuItem(value: 'Day', child: Text('Full Day')),
          DropdownMenuItem(value: 'Hours', child: Text('Hours')),
        ],
        onChanged: (value) {
          setState(() {
            _type = value ?? 'Day';
            // Reset duration when switching type
            _durationController.clear();
          });
        },
        // decoration: const InputDecoration(labelText: 'Type'),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final display =
        _selectedDate != null
            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
            : 'Select date';
    return GestureDetector(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Date'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(display, style: AppTextStyles.bodyMedium(context)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationField(BuildContext context) {
    return AppTextField(
      label: 'Duration (hours)',
      hint: 'Enter hours (e.g. 2, 4.5)',
      controller: _durationController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Duration is required';
        }
        return null;
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now, // Restrict to today so future dates cannot be selected
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    final userState = context.read<UserProfileBloc>().state;
    if (userState is! UserProfileLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User profile not loaded')));
      return;
    }

    final requestToId = userState.profile.reportingManager;
    final userId = userState.profile.userId;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    // For Day type, duration is always 'fullday'; for Hours, use what user entered
    final duration =
        _type == 'Day' ? 'fullday' : _durationController.text.trim();

    if (widget.compOffRequest == null) {
      _bloc.add(
        CreateCompOffEvent(
          type: _type,
          date: dateStr,
          duration: duration,
          reason: _reasonController.text.trim(),
          subject: _subjectController.text.trim(),
          requestTo: requestToId,
          userId: userId,
        ),
      );
    } else {
      _bloc.add(
        UpdateCompOffEvent(
          compOffId: int.tryParse(widget.compOffRequest!.id) ?? 0,
          subject: _subjectController.text.trim(),
          date: dateStr,
          duration: duration,
          reason: _reasonController.text.trim(),
        ),
      );
    }
  }
}
