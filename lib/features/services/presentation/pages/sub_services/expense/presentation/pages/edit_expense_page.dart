import 'dart:io';

import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/widgets/common/app_text_field.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../data/expense_remote_data.dart';
import '../../data/models/expense_detail_model.dart';

class EditExpensePage extends StatelessWidget {
  final ExpenseDetailModel detail;

  const EditExpensePage({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return ExpenseFormPage(userId: detail.requestUser.id, detail: detail);
  }
}

class ExpenseFormPage extends StatefulWidget {
  final int userId;
  final ExpenseDetailModel? detail;

  const ExpenseFormPage({super.key, required this.userId, this.detail});

  bool get isEdit => detail != null;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  static const List<String> _tripTypeOptions = ['Event', 'Official'];
  static const List<String> _durationOptions = ['Single Day', 'Multiple Days'];

  final _formKey = GlobalKey<FormState>();
  late final ExpenseRemoteData _remoteData;
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _invoiceController;
  late final TextEditingController _descriptionController;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  List<ExpenseDocument> _existingFiles = <ExpenseDocument>[];
  final List<File> _newFiles = <File>[];
  final Set<String> _deletingExistingFileIds = <String>{};

  ExpensePolicySelection? _selectedPolicy;
  List<ExpenseTripOption> _tripOptions = const <ExpenseTripOption>[];
  String? _selectedExpenseType;
  int? _selectedTripId;
  String _selectedTripType = _tripTypeOptions.first;
  String _selectedDurationType = _durationOptions.first;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  bool get _isEdit => widget.isEdit;

  @override
  void initState() {
    super.initState();
    _remoteData = ExpenseRemoteData(
      apiClient: ApiClient(
        dio: Dio(),
        networkInfo: NetworkInfoImpl(Connectivity()),
      ),
    );
    final detail = widget.detail;
    _nameController = TextEditingController(text: detail?.expenseName ?? '');
    _amountController = TextEditingController(
      text:
          detail == null
              ? ''
              : detail.amount % 1 == 0
              ? detail.amount.toInt().toString()
              : detail.amount.toString(),
    );
    _invoiceController = TextEditingController(
      text: detail?.invoiceNumber ?? '',
    );
    _descriptionController = TextEditingController(
      text: detail?.description ?? '',
    );
    _fromDate = detail?.fromDate ?? DateTime.now();
    _toDate = detail?.toDate ?? _fromDate;
    _existingFiles = List<ExpenseDocument>.from(detail?.documents ?? const []);
    _selectedTripType = _normalizeTripType(detail?.tripType);
    _selectedDurationType =
        (_fromDate.year == _toDate.year &&
                _fromDate.month == _toDate.month &&
                _fromDate.day == _toDate.day)
            ? _durationOptions.first
            : _durationOptions.last;
    _loadFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _invoiceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _normalizeTripType(String? value) {
    if ((value ?? '').trim().toLowerCase() == 'official') {
      return 'Official';
    }
    return 'Event';
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _remoteData.getUserExpensePolicy(),
        _remoteData.getUserTrips(userId: widget.userId),
      ]);

      final policy = results[0] as ExpensePolicySelection;
      final trips = results[1] as List<ExpenseTripOption>;
      final detail = widget.detail;
      final selectedExpenseType = detail?.expenseType;
      final selectedTripId = detail?.tripId;

      setState(() {
        _selectedPolicy = policy;
        _tripOptions = trips;
        _selectedExpenseType =
            policy.expenseTypes.contains(selectedExpenseType)
                ? selectedExpenseType
                : (policy.expenseTypes.isNotEmpty
                    ? policy.expenseTypes.first
                    : selectedExpenseType);
        _selectedTripId =
            trips.any((trip) => trip.id == selectedTripId)
                ? selectedTripId
                : null;
        _isLoading = false;
      });
    } on ServerException catch (e) {
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load reimbursement form: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null) return;

    final pickedFiles =
        result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .where(
              (file) =>
                  !_newFiles.any((existing) => existing.path == file.path),
            )
            .toList();

    if (pickedFiles.isEmpty) return;

    setState(() {
      _newFiles.addAll(pickedFiles);
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = isFrom ? _fromDate : _toDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = selected;
        if (_selectedDurationType == _durationOptions.first) {
          _toDate = _fromDate;
        } else if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = selected;
      }
    });
  }

  Future<void> _deleteExistingFile(ExpenseDocument file) async {
    if (!_isEdit || _deletingExistingFileIds.contains(file.id)) return;

    setState(() {
      _deletingExistingFileIds.add(file.id);
    });

    try {
      final message = await _remoteData.deleteExpenseFile(
        fileId: file.id,
        expenseId: widget.detail!.id,
      );

      if (!mounted) return;
      setState(() {
        _existingFiles.remove(file);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete attachment: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingExistingFileIds.remove(file.id);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    if (_toDate.isBefore(_fromDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('To date cannot be before from date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedPolicy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense policy could not be loaded.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedExpenseType == null || _selectedExpenseType!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select reimbursement type.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final message =
          _isEdit
              ? await _remoteData.updateExpense(
                expenseId: widget.detail!.id,
                expenseType: _selectedExpenseType!.trim(),
                expenseName: _nameController.text.trim(),
                amount: _amountController.text.trim(),
                fromDate: _fromDate,
                toDate: _toDate,
                expensePolicyId: _selectedPolicy!.id,
                currency: _selectedPolicy!.currency,
                tripId: _selectedTripId,
                tripType: _selectedTripType,
                existingFiles: _existingFiles,
                newFiles: _newFiles,
                invoiceNumber: _invoiceController.text.trim(),
                description: _descriptionController.text.trim(),
              )
              : await _remoteData.createExpense(
                userId: widget.userId,
                expenseType: _selectedExpenseType!.trim(),
                expenseName: _nameController.text.trim(),
                amount: _amountController.text.trim(),
                fromDate: _fromDate,
                toDate: _toDate,
                expensePolicyId: _selectedPolicy!.id,
                currency: _selectedPolicy!.currency,
                tripId: _selectedTripId,
                tripType: _selectedTripType,
                newFiles: _newFiles,
                invoiceNumber: _invoiceController.text.trim(),
                description: _descriptionController.text.trim(),
              );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    } on ServerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reimbursement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _isEdit ? 'Edit Reimbursement' : 'Claim Reimbursement',
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _buildBody(sw, sh),
    );
  }

  Widget _buildBody(double sw, double sh) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ApiErrorState(rawMessage: _loadError!, onRetry: _loadFormData);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(sw * 0.002),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _FormCard(
              child: Column(
                children: [

                  AppTextField(
                    controller: _nameController,
                    label: 'Expense Name',
                    hint: "Enter Reimbursment name",
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Reimbursment name is required'
                                : null,
                  ),
                  SizedBox(height: sw * 0.035),
                  _DropdownField<String>(
                    label: 'Reimbursement Type',
                    value: _selectedExpenseType,
                    items:
                        (_selectedPolicy?.expenseTypes ?? const <String>[])
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExpenseType = value;
                      });
                    },
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Reimbursement type is required'
                                : null,
                  ),
                  SizedBox(height: sw * 0.035),

                  _DropdownField<int>(
                    label: 'Associate Trip',
                    value: _selectedTripId,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('No trip selected'),
                      ),
                      ..._tripOptions.map(
                        (trip) => DropdownMenuItem<int>(
                          value: trip.id,
                          child: Text(trip.tripName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTripId = value;
                      });
                    },
                  ),
                  SizedBox(height: sw * 0.035),
                  _DropdownField<String>(
                    label: 'Trip Type',
                    value: _selectedTripType,
                    items:
                        _tripTypeOptions
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedTripType = value;
                      });
                    },
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Trip type is required'
                                : null,
                  ),
                  SizedBox(height: sw * 0.035),
                  AppTextField(
                    controller: _amountController,
                    label: 'Amount',
                    hint: 'Enter amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: sw * 0.035),
                  AppTextField(
                    controller: _invoiceController,
                    label: 'Invoice Number',
                    hint: 'Enter invoice number',
                  ),
                  SizedBox(height: sw * 0.035),
                  _DropdownField<String>(
                    label: 'Expense Duration (Day or Days)',
                    value: _selectedDurationType,
                    items:
                        _durationOptions
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedDurationType = value;
                        if (value == _durationOptions.first) {
                          _toDate = _fromDate;
                        }
                      });
                    },
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Duration type is required'
                            : null,
                  ),
                  SizedBox(height: sw * 0.035),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: 'From Date',
                          value: _formatDate(_fromDate),
                          onTap: () => _pickDate(isFrom: true),
                        ),
                      ),
                      if (_selectedDurationType == _durationOptions.last) ...[
                        SizedBox(width: sw * 0.03),
                        Expanded(
                          child: _DateButton(
                            label: 'To Date',
                            value: _formatDate(_toDate),
                            onTap: () => _pickDate(isFrom: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: sw * 0.035),
                  //
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter description',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: sw * 0.04),
            _FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload File',
                    style: AppTextStyles.bodyMediumHeading(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: sh * 0.01),
                  if (_existingFiles.isEmpty && _newFiles.isEmpty)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _pickFiles();
                        },
                        child: Container(
                          padding: EdgeInsets.all(sw * 0.08),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Column(
                            children: [
                              SvgPicture.asset(AppAssets.iconupload),
                              SizedBox(height: sh * 0.01),
                              Text(
                                "Upload file(s)",
                                maxLines: 1,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.textPrimary),
                              ),
                              SizedBox(height: sh * 0.01),
                              Text(
                                "Tap to upload(PDF, DOC, DOCX)",
                                maxLines: 2,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Text(
                  //   'No files selected.',
                  //   style: AppTextStyles.bodySmall(
                  //     context,
                  //   ).copyWith(color: AppColors.textSecondary),
                  // )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ..._existingFiles.map(
                          (file) => _SelectedFileChip(
                            label: file.name,
                            isPdf: file.name.toLowerCase().endsWith('.pdf'),
                            isRemoving: _deletingExistingFileIds.contains(
                              file.id,
                            ),
                            removeIcon: Icons.delete_outline,
                            removeIconColor: AppColors.error,
                            onRemove: () => _deleteExistingFile(file),
                          ),
                        ),
                        ..._newFiles.map(
                          (file) => _SelectedFileChip(
                            label: file.path.split('/').last,
                            isPdf: file.path.toLowerCase().endsWith('.pdf'),
                            removeIcon: Icons.close,
                            onRemove: () {
                              setState(() {
                                _newFiles.remove(file);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(height: sw * 0.06),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.attendanceTeal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: sw * 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          _isEdit ? 'Save Changes' : 'Create Request',
                          style: AppTextStyles.buttonMedium(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge(
            context,
          ).copyWith(color: AppColors.textHeading),
        ),
        SizedBox(height: screenHeight * 0.01),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: DropdownButtonFormField<T?>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            validator: validator,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            decoration: InputDecoration(
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.01,
                vertical: screenHeight * 0.018,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodyMediumHeading(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFileChip extends StatelessWidget {
  final String label;
  final bool isPdf;
  final VoidCallback onRemove;
  final bool isRemoving;
  final IconData removeIcon;
  final Color? removeIconColor;

  const _SelectedFileChip({
    required this.label,
    required this.isPdf,
    required this.onRemove,
    this.isRemoving = false,
    this.removeIcon = Icons.close,
    this.removeIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            size: 18,
            color: isPdf ? Colors.redAccent : AppColors.attendanceTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: isRemoving ? null : onRemove,
            child:
                isRemoving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(
                      removeIcon,
                      size: 18,
                      color: removeIconColor,
                    ),
          ),
        ],
      ),
    );
  }
}
