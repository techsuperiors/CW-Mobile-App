import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  
  String? _selectedWfhDuration;
  DateTime? _fromDate;
  String _fromHalfDay = 'First Half';
  DateTime? _toDate;
  String _toHalfDay = 'Second Half';
  String? _requestTo = 'Riya Rawat';

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // If editing, pre-fill the form
    if (widget.wfhRequest != null) {
      _initializeFormFromWfhRequest(widget.wfhRequest!);
    }
  }

  void _initializeFormFromWfhRequest(WfhRequestModel wfhRequest) {
    // Pre-fill dates
    _fromDate = wfhRequest.fromDate;
    _toDate = wfhRequest.toDate;
    
    // Determine WFH duration
    _selectedWfhDuration = wfhRequest.toDate == null ? 'Single Day WFH' : 'Multiple Day WFH';
    
    // Pre-fill description
    _descriptionController.text = wfhRequest.reason;
    _subjectController.text = wfhRequest.reason; // Use reason as subject
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          AppStrings.wfh,
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
                      Icons.home, // House icon for WFH
                      color: AppColors.attendanceTeal,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    widget.wfhRequest != null ? 'Edit WFH Request' : AppStrings.wfh,
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
              // WFH Duration
              _buildDropdownField(
                context,
                label: 'WFH Duration',
                value: _selectedWfhDuration,
                hint: 'Select WFH Duration',
                items: ['Single Day WFH', 'Multiple Day WFH'],
                onChanged: (value) {
                  setState(() {
                    _selectedWfhDuration = value;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
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
                      hint: 'Select Half',
                      value: _fromHalfDay,
                      items: ['First Half', 'Second Half'],
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
                      hint: 'Select Half',
                      value: _toHalfDay,
                      items: ['First Half', 'Second Half'],
                      onChanged: (value) {
                        setState(() {
                          _toHalfDay = value ?? 'Second Half';
                        });
                      },
                    ),
                  ),
                ],
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
                    widget.wfhRequest != null ? 'Update' : 'Submit',
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
}
