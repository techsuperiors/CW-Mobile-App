import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../../core/widgets/common/app_text_field.dart';
import '../../models/wfh_request_model.dart';

/// Apply WFH form page
class ApplyWfhPage extends StatefulWidget {
  final WfhRequestModel? wfhRequest; // Optional: for editing existing WFH

  const ApplyWfhPage({super.key, this.wfhRequest});

  @override
  State<ApplyWfhPage> createState() => _ApplyWfhPageState();
}

class _ApplyWfhPageState extends State<ApplyWfhPage> {
  static const String _singleDayWfhOption = 'Single Day WFH';
  static const String _multipleDayWfhOption = 'Multiple Day WFH';
  static const String _halfDayWfhOption = 'Half Day WFH';
  static const List<String> _halfDayOptions = ['First Half', 'Second Half'];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;

  String? _selectedWfhDuration = _singleDayWfhOption;
  DateTime? _fromDate;
  String _fromHalfDay = 'First Half';
  DateTime? _toDate;
  String _toHalfDay = 'Second Half';
  bool _isWorkFromAnywhere = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.wfhRequest != null) {
      _initializeFormFromWfhRequest(widget.wfhRequest!);
    }
  }

  void _initializeFormFromWfhRequest(WfhRequestModel wfhRequest) {
    _fromDate = wfhRequest.fromDate;
    _toDate = wfhRequest.toDate;
    switch (wfhRequest.requestType) {
      case 'half_day':
        _selectedWfhDuration = _halfDayWfhOption;
        _toDate = null;
        _fromHalfDay = _apiHalfToDisplay(wfhRequest.startHalf);
        break;
      case 'multiple':
        _selectedWfhDuration = _multipleDayWfhOption;
        _fromHalfDay = _apiHalfToDisplay(wfhRequest.startHalf);
        _toHalfDay = _apiHalfToDisplay(
          wfhRequest.endHalf,
          fallback: 'Second Half',
        );
        break;
      case 'single':
      default:
        _selectedWfhDuration = _singleDayWfhOption;
        _toDate = null;
        break;
    }
    _descriptionController.text = wfhRequest.description ?? wfhRequest.reason;
    _subjectController.text = wfhRequest.subject ?? wfhRequest.reason;
    _isWorkFromAnywhere = wfhRequest.isAnywhere ?? false;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = today.add(const Duration(days: 365));
    final rawInitialDate =
        isFromDate
            ? (_fromDate ?? DateTime.now())
            : (_toDate ?? _fromDate ?? DateTime.now());
    final initialDate = DateUtils.dateOnly(
      rawInitialDate.isBefore(today) ? today : rawInitialDate,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
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

  /// Convert half day display name to API format.
  String _halfDayToApi(String halfDay) {
    return halfDay == 'First Half' ? 'first_half' : 'second_half';
  }

  String _apiHalfToDisplay(String? apiHalf, {String fallback = 'First Half'}) {
    switch (apiHalf?.trim().toLowerCase()) {
      case 'first_half':
        return 'First Half';
      case 'second_half':
        return 'Second Half';
      default:
        return fallback;
    }
  }

  Future<void> _submitWfhRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_selectedWfhDuration == _multipleDayWfhOption && _toDate == null) {
      _showError('Please select an end date');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

      if (!await networkInfo.isConnected) {
        _showError('No internet connection');
        return;
      }

      // 1. Get User ID (Same logic as you have)
      final prefs = await SharedPreferences.getInstance();
      int? userId;
      final token = prefs.getString('auth_token');
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            String jwtPayload = parts[1];
            while (jwtPayload.length % 4 != 0) {
              jwtPayload += '=';
            }
            final decoded = utf8.decode(base64Url.decode(jwtPayload));
            final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
            userId = payloadMap['user_id'] as int?;
          }
        } catch (_) {}
      }

      // 2. Condition-based Payload Construction
      final isSingleDay = _selectedWfhDuration == _singleDayWfhOption;
      final isHalfDay = _selectedWfhDuration == _halfDayWfhOption;
      final isMultipleDay = _selectedWfhDuration == _multipleDayWfhOption;
      final requestType =
          isHalfDay
              ? 'half_day'
              : isMultipleDay
              ? 'multiple'
              : 'single';
      final dateFormat = DateFormat('yyyy-MM-dd');

      final DateTime startDate = _fromDate!;
      final DateTime endDate =
          isMultipleDay ? (_toDate ?? _fromDate!) : _fromDate!;

      if (isMultipleDay && endDate.isBefore(startDate)) {
        _showError('End date cannot be before start date');
        return;
      }

      Map<String, dynamic> payload = {
        'subject': _subjectController.text.trim(),
        'request_type': requestType,
        'description': _descriptionController.text.trim(),
        'user_id': userId,
        'start_date': dateFormat.format(startDate),
        'end_date': dateFormat.format(endDate),
      };

      if (isSingleDay) {
        payload['is_anywhere'] = _isWorkFromAnywhere;
        payload['wfh_request_date'] = startDate.toUtc().toIso8601String();
      } else if (isHalfDay) {
        payload['wfh_request_date'] = startDate.toUtc().toIso8601String();
        if (widget.wfhRequest == null) {
          payload['is_anywhere'] = _isWorkFromAnywhere;
          payload['start_half'] = _halfDayToApi(_fromHalfDay);
        }
      } else {
        payload['is_anywhere'] = _isWorkFromAnywhere;
        payload['wfh_request_date'] = startDate.toUtc().toIso8601String();
        payload['wfh_to_request_date'] = endDate.toUtc().toIso8601String();
        payload['start_half'] = _halfDayToApi(_fromHalfDay);
        payload['end_half'] = _halfDayToApi(_toHalfDay);
      }

      if (widget.wfhRequest != null) {
        final requestId =
            int.tryParse(
              widget.wfhRequest!.attendanceRequestId ?? widget.wfhRequest!.id,
            ) ??
            0;
        payload['request_id'] = requestId;
        payload.remove('is_anywhere');
      }

      debugPrint('WFH final payload: $payload');

      // 3. Encode and Post
      final encodedData = encodeData(payload);
      final response =
          widget.wfhRequest != null
              ? await apiClient.put(
                AppUrls.wfhRequestRaise,
                data: {'payload': encodedData},
                options: Options(headers: {'Content-Type': 'application/json'}),
              )
              : await apiClient.post(
                AppUrls.wfhRequestRaise,
                data: {'payload': encodedData},
                options: Options(headers: {'Content-Type': 'application/json'}),
              );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('WFH request submitted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        _showError(responseData['message'] ?? 'Failed to submit WFH request');
      }
    } catch (e) {
      String errorMessage = 'An unexpected error occurred';

      // Check if it's your custom ServerException
      if (e is ServerException) {
        // Agar aapki class mein 'message' field hai toh:
        errorMessage = e.message;
      }
      // Agar Dio directly error throw kar raha hai
      else if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        } else {
          errorMessage = e.message ?? 'Network Error';
        }
      } else {
        errorMessage = e.toString();
      }

      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 110,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
          widget.wfhRequest != null ? 'Edit WFH Request' : AppStrings.wfh,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
              // Header with icon and description
              // Subject
              AppTextField(
                label: 'Subject',
                hint: 'Enter Subject',
                controller: _subjectController,
                // bgcolor: AppColors.backgroundMedium,
              ),
              SizedBox(height: screenHeight * 0.02),
              // WFH Duration
              _buildDropdownField(
                context,
                label: 'WFH Duration',
                value: _selectedWfhDuration,
                hint: 'Select WFH Duration',
                items: const [
                  _singleDayWfhOption,
                  _multipleDayWfhOption,
                  _halfDayWfhOption,
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWfhDuration = value;
                    if (value != _multipleDayWfhOption) {
                      _toDate = null;
                    }
                    if (value == _singleDayWfhOption) {
                      _fromHalfDay = 'First Half';
                    }
                  });
                },
              ),
              // Show date fields based on WFH Duration selection
              if (_selectedWfhDuration == _singleDayWfhOption) ...[
                SizedBox(height: screenHeight * 0.02),
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
              ] else if (_selectedWfhDuration == _halfDayWfhOption) ...[
                SizedBox(height: screenHeight * 0.02),
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
                      flex: 1,
                      child: _buildDateField(
                        context,
                        value:
                            _fromDate != null
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
                        hint: 'Select Half',
                        value: _fromHalfDay,
                        items: _halfDayOptions,
                        onChanged: (value) {
                          setState(() {
                            _fromHalfDay = value ?? 'First Half';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedWfhDuration == _multipleDayWfhOption) ...[
                SizedBox(height: screenHeight * 0.02),
                // From
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
                        hint: 'Select Half',
                        value: _fromHalfDay,
                        items: _halfDayOptions,
                        onChanged: (value) {
                          setState(() {
                            _fromHalfDay = value ?? 'First Half';
                          });
                        },
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
                            _toDate != null
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
                        hint: 'Select Half',
                        value: _toHalfDay,
                        items: _halfDayOptions,
                        onChanged: (value) {
                          setState(() {
                            _toHalfDay = value ?? 'Second Half';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: screenHeight * 0.02),
              if (widget.wfhRequest == null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _isWorkFromAnywhere,
                        onChanged:
                            _isSubmitting
                                ? null
                                : (value) {
                                  setState(() {
                                    _isWorkFromAnywhere = value ?? false;
                                  });
                                },
                        title: Text(
                          'Work From Anywhere',
                          style: AppTextStyles.labelLarge(
                            context,
                          ).copyWith(color: AppColors.textHeading),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.attendanceTeal,
                        checkColor: AppColors.textWhite,
                        hoverColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
              ],
              // Description
              AppTextField(
                label: 'Description',
                hint: 'Enter Description',
                controller: _descriptionController,
                maxLines: 2,
              ),
              SizedBox(height: screenHeight * 0.03),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitWfhRequest,
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
                  ),
                  child:
                      _isSubmitting
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textWhite,
                            ),
                          )
                          : Text(
                            widget.wfhRequest != null ? 'Update' : 'Submit',
                            style: AppTextStyles.buttonLarge(context).copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                    side: BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.textWhite,
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
            menuMaxHeight: screenHeight * 0.35,

            borderRadius: BorderRadius.circular(12),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
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
}
