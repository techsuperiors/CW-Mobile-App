import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../../core/widgets/common/app_text_field.dart';

/// Regularize form page
class RegularizePage extends StatefulWidget {
  final DateTime? selectedDate;

  const RegularizePage({
    super.key,
    this.selectedDate,
  });

  @override
  State<RegularizePage> createState() => _RegularizePageState();
}

class _RegularizePageState extends State<RegularizePage> {
  final _formKey = GlobalKey<FormState>();
  final _punchInTimeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _attendanceDay;
  String? _requestTo = 'Riya Rawat';
  String? _requestFor = 'Punch-In';
  String? _captureMode;
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    _attendanceDay = widget.selectedDate ?? DateTime(2025, 12, 30);
  }

  @override
  void dispose() {
    _punchInTimeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _attendanceDay ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
        _attendanceDay = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        final now = DateTime.now();
        final dateTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _punchInTimeController.text = DateFormat('hh:mm a').format(dateTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
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
              SizedBox(width: screenWidth * 0.048),
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
          AppStrings.regularize,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {},
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
                      Icons.edit,
                      color: AppColors.attendanceTeal,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    AppStrings.regularize,
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
              // Attendance Day
              Text(
                'Attendance Day',
                style: AppTextStyles.labelLarge(context),
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildDateField(
                context,
                value: _attendanceDay != null
                    ? DateFormat('dd/MM/yyyy').format(_attendanceDay!)
                    : null,
                hint: 'Select Date',
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Request To
              _buildDropdownField(
                context,
                label: 'Request To',
                value: _requestTo,
                items: ['Riya Rawat', 'Manager 1', 'Manager 2'],
                onChanged: (value) {
                  setState(() {
                    _requestTo = value;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Request for
              _buildDropdownField(
                context,
                label: 'Request for',
                value: _requestFor,
                items: ['Punch-In', 'Punch-Out'],
                onChanged: (value) {
                  setState(() {
                    _requestFor = value;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Capture Mode
              _buildDropdownField(
                context,
                label: 'Capture Mode',
                value: _captureMode,
                hint: 'Select',
                items: ['Manual', 'Biometric', 'QR Code'],
                onChanged: (value) {
                  setState(() {
                    _captureMode = value;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              // Punch-In
              Text(
                'Punch-In',
                style: AppTextStyles.labelLarge(context),
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildTimeField(
                context,
                controller: _punchInTimeController,
                hint: 'Enter Time',
                onTap: () => _selectTime(context),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Reason
              _buildDropdownField(
                context,
                label: 'Reason',
                value: _selectedReason,
                hint: 'Select Reason',
                items: ['Forgot to Punch', 'System Error', 'Network Issue', 'Other'],
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
              SizedBox(height: screenHeight * 0.03),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle submit
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.attendanceTeal,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit',
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
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String? label,
    required String? value,
    String? hint,
    required List<String> items,
    required Function(String?) onChanged,
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

  Widget _buildTimeField(
    BuildContext context, {
    required TextEditingController controller,
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
              controller.text.isEmpty ? hint : controller.text,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: controller.text.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
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
}

