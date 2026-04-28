import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../../core/utils/location_permission_helper.dart';
import '../../../../../../../../../../../core/utils/location_service.dart';
import '../../domain/models/account_model.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class CreateCustomerSheet extends StatefulWidget {
  const CreateCustomerSheet({super.key});

  @override
  State<CreateCustomerSheet> createState() => _CreateCustomerSheetState();
}

class _CreateCustomerSheetState extends State<CreateCustomerSheet> {
  static const List<String> _customerTypes = [
    'LEAD',
    'PROSPECT',
    'CLIENT',
    'VENDOR',
    'RESELLER',
    'DISTRIBUTOR',
    'PARTNER',
    'SUPPLIER',
  ];

  static const List<String> _addressTypes = [
    'SITE',
    'CLIENT',
    'WAREHOUSE',
    'OFFICE',
    'VENDOR',
    'DISTRIBUTION_CENTER',
    'OTHER',
  ];

  static const String _defaultCountryCode = '+91';
  static const double _defaultMapZoom = 5.5;
  static const double _pickerMapZoom = 15;
  static const LatLng _defaultMapCenter = LatLng(22.5937, 78.9629);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _businessDomainController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<_AddressFormData> _addresses = [_AddressFormData()];
  String? _selectedCustomerType;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerCodeController.dispose();
    _businessDomainController.dispose();
    _descriptionController.dispose();
    for (final address in _addresses) {
      address.dispose();
    }
    super.dispose();
  }

  void _addAddress() {
    FocusScope.of(context).unfocus();
    setState(() {
      _addresses.add(_AddressFormData());
    });
  }

  void _removeAddress(int index) {
    if (_addresses.length == 1) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      final removed = _addresses.removeAt(index);
      removed.dispose();
    });
  }

  void _addContact(int addressIndex) {
    FocusScope.of(context).unfocus();
    setState(() {
      _addresses[addressIndex].contacts.add(_ContactFormData());
    });
  }

  void _removeContact(int addressIndex, int contactIndex) {
    final contacts = _addresses[addressIndex].contacts;
    if (contacts.length == 1) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      final removed = contacts.removeAt(contactIndex);
      removed.dispose();
    });
  }

  bool _hasValidSelections() {
    return (_selectedCustomerType ?? '').trim().isNotEmpty;
  }

  bool _hasAnyAddressData(_AddressFormData address) {
    return address.labelController.text.trim().isNotEmpty ||
        (address.addressType ?? '').trim().isNotEmpty ||
        address.addressController.text.trim().isNotEmpty ||
        (address.country ?? '').trim().isNotEmpty ||
        (address.state ?? '').trim().isNotEmpty ||
        (address.city ?? '').trim().isNotEmpty ||
        address.pincodeController.text.trim().isNotEmpty ||
        address.contacts.any(_hasAnyContactData);
  }

  bool _hasAnyContactData(_ContactFormData contact) {
    return contact.nameController.text.trim().isNotEmpty ||
        contact.designationController.text.trim().isNotEmpty ||
        contact.phoneController.text.trim().isNotEmpty ||
        contact.emailController.text.trim().isNotEmpty;
  }

  void _submit(AccountState state) {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || !_hasValidSelections()) {
      return;
    }

    final params = CreateAccountCustomerParams(
      customerName: _customerNameController.text.trim(),
      customerCode: _customerCodeController.text.trim(),
      customerType: _selectedCustomerType!.trim(),
      businessDomain: _businessDomainController.text.trim(),
      description: _descriptionController.text.trim(),
      addresses: _addresses
          .where(_hasAnyAddressData)
          .map(
            (address) => CreateAccountAddressParams(
              label: address.labelController.text.trim(),
              type: (address.addressType ?? '').trim(),
              address: address.addressController.text.trim(),
              country: (address.country ?? '').trim(),
              state: (address.state ?? '').trim(),
              city: (address.city ?? '').trim(),
              pincode: address.pincodeController.text.trim(),
              latitude: '',
              longitude: '',
              contacts: address.contacts
                  .where(_hasAnyContactData)
                  .toList(growable: false)
                  .asMap()
                  .entries
                  .map((entry) {
                    final contact = entry.value;
                    final phoneNumber = contact.phoneController.text.trim();
                    return CreateAccountContactParams(
                      name: contact.nameController.text.trim(),
                      designation: contact.designationController.text.trim(),
                      phone:
                          phoneNumber.isEmpty
                              ? ''
                              : '$_defaultCountryCode$phoneNumber',
                      email: contact.emailController.text.trim(),
                      isPrimary: entry.key == 0,
                    );
                  })
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );

    context.read<AccountBloc>().add(CreateAccountCustomerRequested(params));
  }

  Future<void> _openLatLongPicker(_AddressFormData address) async {
    FocusScope.of(context).unfocus();

    final initialPoint = _parseLatLng(
      address.latitudeController.text,
      address.longitudeController.text,
    );

    final selectedPoint = await showDialog<LatLng>(
      context: context,
      builder:
          (_) => _LatLongMapPickerDialog(
            initialPoint: initialPoint ?? _defaultMapCenter,
            initialZoom:
                initialPoint == null ? _defaultMapZoom : _pickerMapZoom,
          ),
    );

    if (!mounted || selectedPoint == null) return;

    setState(() {
      address.latitudeController.text = selectedPoint.latitude.toStringAsFixed(
        6,
      );
      address.longitudeController.text = selectedPoint.longitude.toStringAsFixed(
        6,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen:
          (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.actionError != current.actionError,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          Navigator.of(context).pop(true);
          messenger.showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
          context.read<AccountBloc>().add(const ClearAccountFeedback());
          return;
        }

        if (state.actionError != null && state.actionError!.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<AccountBloc>().add(const ClearAccountFeedback());
        }
      },
      builder: (context, state) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: DraggableScrollableSheet(
            initialChildSize: 0.86,
            minChildSize: 0.6,
            maxChildSize: 0.96,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.xl),
                      topRight: Radius.circular(AppSpacing.xl),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl + keyboardInset,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: AppSpacing.section,
                              height: AppSpacing.xs + 1,
                              decoration: BoxDecoration(
                                color: AppColors.borderDark,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.sectionLarge,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.vSm,
                          Container(
                            width: AppSpacing.sectionLarge - AppSpacing.xs,
                            height: AppSpacing.sectionLarge - AppSpacing.xs,
                            decoration: BoxDecoration(
                              color: AppColors.serviceBlueBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.xl + AppSpacing.xxs,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              AppAssets.iconVisit,
                              width: AppSpacing.iconSmallWidth,
                              height: AppSpacing.iconSmallHeight,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          AppSpacing.vMd,
                          Text(
                            'Add Customer',
                            style: AppTextStyles.heading4(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vSm,
                          Text(
                            'Create a customer profile with address and primary contact details.',
                            style: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                          AppSpacing.vLg,
                          Text(
                            'Customer Details',
                            style: AppTextStyles.labelLarge(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vMd,
                          _buildTextField(
                            context,
                            label: 'Customer Name*',
                            hint: 'Enter customer name',
                            controller: _customerNameController,
                            enabled: !state.isCreatingCustomer,
                          ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Customer Code',
                            hint: 'Enter customer code',
                            controller: _customerCodeController,
                            enabled: !state.isCreatingCustomer,
                            validator: (_) => null,
                          ),
                          AppSpacing.vLg,
                          _buildDropdownField<String>(
                            context,
                            label: 'Customer Type*',
                            hint: 'Select customer type',
                            value: _selectedCustomerType,
                            items: _customerTypes,
                            itemLabelBuilder: (item) => item,
                            onChanged:
                                state.isCreatingCustomer
                                    ? null
                                    : (value) => setState(
                                      () => _selectedCustomerType = value,
                                    ),
                            validator:
                                (value) =>
                                    (value ?? '').trim().isEmpty
                                        ? 'Customer type is required'
                                        : null,
                          ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Business Domain*',
                            hint: 'Enter business domain',
                            controller: _businessDomainController,
                            enabled: !state.isCreatingCustomer,
                          ),
                          AppSpacing.vLg,
                          Text(
                            'Addresses',
                            style: AppTextStyles.labelLarge(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vMd,
                          ..._addresses.asMap().entries.map((entry) {
                            final index = entry.key;
                            final address = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == _addresses.length - 1
                                        ? AppSpacing.lg
                                        : AppSpacing.xl,
                              ),
                              child: _buildAddressSection(
                                context,
                                state,
                                index: index,
                                address: address,
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed:
                                  state.isCreatingCustomer ? null : _addAddress,
                              icon: const Icon(Icons.add, size: AppSpacing.lg),
                              label: Text(
                                'Add address',
                                style: AppTextStyles.bodyMediumHeading(context),
                              ),
                            ),
                          ),
                          AppSpacing.vMd,
                          _buildTextField(
                            context,
                            label: 'Description',
                            hint: 'Enter description',
                            controller: _descriptionController,
                            enabled: !state.isCreatingCustomer,
                            minLines: 3,
                            maxLines: 4,
                            validator: (_) => null,
                          ),
                          AppSpacing.vXl,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  state.isCreatingCustomer
                                      ? null
                                      : () => _submit(state),
                              style: ElevatedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.md,
                                  ),
                                ),
                              ),
                              child:
                                  state.isCreatingCustomer
                                      ? const SizedBox(
                                        height: AppSpacing.lg + AppSpacing.xxs,
                                        width: AppSpacing.lg + AppSpacing.xxs,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textWhite,
                                        ),
                                      )
                                      : Text(
                                        'Add Customer',
                                        style: AppTextStyles.buttonLarge(
                                          context,
                                        ),
                                      ),
                            ),
                          ),
                          AppSpacing.vMd,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  state.isCreatingCustomer
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.md,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.bodyMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildAddressSection(
    BuildContext context,
    AccountState state, {
    required int index,
    required _AddressFormData address,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Address ${index + 1}',
                  style: AppTextStyles.labelLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_addresses.length > 1)
                IconButton(
                  onPressed:
                      state.isCreatingCustomer
                          ? null
                          : () => _removeAddress(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          _buildTextField(
            context,
            label: 'Label',
            hint: 'Enter label',
            controller: address.labelController,
            enabled: !state.isCreatingCustomer,
            validator: (_) => null,
          ),
          AppSpacing.vLg,
          _buildDropdownField<String>(
            context,
            label: 'Address Type',
            hint: 'Select address type',
            value: address.addressType,
            items: _addressTypes,
            itemLabelBuilder: _formatAddressTypeLabel,
            onChanged:
                state.isCreatingCustomer
                    ? null
                    : (value) => setState(() => address.addressType = value),
            validator: (_) => null,
          ),
          AppSpacing.vLg,
          _buildTextField(
            context,
            label: 'Address',
            hint: 'Enter full address',
            controller: address.addressController,
            enabled: !state.isCreatingCustomer,
            minLines: 2,
            maxLines: 3,
            validator: (_) => null,
          ),
          AppSpacing.vLg,
          Text(
            'Country / State / City',
            style: AppTextStyles.labelLarge(context),
          ),
          AppSpacing.vSm,
          AbsorbPointer(
            absorbing: state.isCreatingCustomer,
            child: CSCPickerPlus(
              layout: Layout.vertical,
              flagState: CountryFlag.DISABLE,
              currentCountry: address.country,
              currentState: address.state,
              currentCity: address.city,
              countryDropdownLabel: 'Select country',
              stateDropdownLabel: 'Select state',
              cityDropdownLabel: 'Select city',
              countrySearchPlaceholder: 'Search country',
              stateSearchPlaceholder: 'Search state',
              citySearchPlaceholder: 'Search city',
              selectedItemStyle: AppTextStyles.bodyMedium(context),
              dropdownItemStyle: AppTextStyles.bodyMedium(context),
              dropdownHeadingStyle: AppTextStyles.labelLarge(
                context,
              ).copyWith(color: AppColors.textSecondary),
              dropdownDecoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(
                  AppSpacing.md - AppSpacing.xxs,
                ),
                border: Border.all(color: AppColors.border),
              ),
              disabledDropdownDecoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(
                  AppSpacing.md - AppSpacing.xxs,
                ),
                border: Border.all(color: AppColors.border),
              ),
              onCountryChanged: (value) {
                setState(() {
                  address.country = _sanitizeLocationValue(value);
                  address.state = null;
                  address.city = null;
                });
              },
              onStateChanged: (value) {
                setState(() {
                  address.state = _sanitizeLocationValue(value);
                  address.city = null;
                });
              },
              onCityChanged: (value) {
                setState(() {
                  address.city = _sanitizeLocationValue(value);
                });
              },
            ),
          ),
          AppSpacing.vLg,
          _buildLocationTypeSection(context, state, address),
          AppSpacing.vLg,
          _buildTextField(
            context,
            label: 'Pincode',
            hint: 'Enter pincode',
            controller: address.pincodeController,
            enabled: !state.isCreatingCustomer,
            keyboardType: TextInputType.number,
            validator: (_) => null,
          ),
          AppSpacing.vLg,
          Text(
            'Point of contact',
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          AppSpacing.vMd,
          ...address.contacts.asMap().entries.map((contactEntry) {
            final contactIndex = contactEntry.key;
            final contact = contactEntry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    contactIndex == address.contacts.length - 1
                        ? AppSpacing.lg
                        : AppSpacing.xl,
              ),
              child: _buildContactSection(
                context,
                state,
                addressIndex: index,
                contactIndex: contactIndex,
                contact: contact,
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  state.isCreatingCustomer ? null : () => _addContact(index),
              icon: const Icon(Icons.add, size: AppSpacing.lg),
              label: Text(
                'Add contact',
                style: AppTextStyles.bodyMediumHeading(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    AccountState state, {
    required int addressIndex,
    required int contactIndex,
    required _ContactFormData contact,
  }) {
    return Container(
      padding: AppSpacing.cardPaddingSmall,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contactIndex == 0
                      ? 'Primary Contact'
                      : 'Contact ${contactIndex + 1}',
                  style: AppTextStyles.labelLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_addresses[addressIndex].contacts.length > 1)
                IconButton(
                  onPressed:
                      state.isCreatingCustomer
                          ? null
                          : () => _removeContact(addressIndex, contactIndex),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          _buildTextField(
            context,
            label: 'Name',
            hint: 'Enter contact name',
            controller: contact.nameController,
            enabled: !state.isCreatingCustomer,
            validator: (_) => null,
          ),
          AppSpacing.vLg,
          _buildTextField(
            context,
            label: 'Designation',
            hint: 'Enter designation',
            controller: contact.designationController,
            enabled: !state.isCreatingCustomer,
            validator: (_) => null,
          ),
          AppSpacing.vLg,
          Text('Contact Number', style: AppTextStyles.labelLarge(context)),
          AppSpacing.vSm,
          Row(
            children: [
              Container(
                padding: AppSpacing.inputPadding,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.md - AppSpacing.xxs,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _defaultCountryCode,
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: TextFormField(
                  controller: contact.phoneController,
                  enabled: !state.isCreatingCustomer,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyMedium(context),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Enter contact number',
                  ),
                  validator: (value) {
                    final phone = (value ?? '').trim();
                    if (phone.isEmpty) return null;
                    if (phone.length != 10) {
                      return 'Enter a valid 10-digit contact number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          AppSpacing.vLg,
          _buildTextField(
            context,
            label: 'Email',
            hint: 'Enter email',
            controller: contact.emailController,
            enabled: !state.isCreatingCustomer,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            validator: (value) {
              final email = (value ?? '').trim();
              if (email.isEmpty) return null;
              final isValid = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(email);
              return isValid ? null : 'Enter a valid email';
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTypeSection(
    BuildContext context,
    AccountState state,
    _AddressFormData address,
  ) {
    final groupValue = address.locationType;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingSmall,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Type',
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vSm,
          Row(
            children: [
              Expanded(
                child: _LocationTypeOption(
                  label: 'Polygon',
                  isSelected: groupValue == _AddressLocationType.polygon,
                  onTap:
                      state.isCreatingCustomer
                          ? null
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Polygon will be added later.'),
                            ),
                          ),
                ),
              ),
              Expanded(
                child: _LocationTypeOption(
                  label: 'Latitude / Longitude',
                  isSelected: groupValue == _AddressLocationType.latLong,
                  onTap:
                      state.isCreatingCustomer
                          ? null
                          : () => setState(
                            () =>
                                address.locationType =
                                    _AddressLocationType.latLong,
                          ),
                ),
              ),
            ],
          ),
          if (address.locationType == _AddressLocationType.latLong) ...[
            AppSpacing.vSm,
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed:
                    state.isCreatingCustomer
                        ? null
                        : () => _openLatLongPicker(address),
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  'Pick On Map',
                  style: AppTextStyles.bodyMediumHeading(context),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
            ),
            AppSpacing.vSm,
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    context,
                    label: 'Latitude',
                    hint: 'Enter latitude',
                    controller: address.latitudeController,
                    enabled: !state.isCreatingCustomer,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (_) => null,
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: _buildTextField(
                    context,
                    label: 'Longitude',
                    hint: 'Enter longitude',
                    controller: address.longitudeController,
                    enabled: !state.isCreatingCustomer,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (_) => null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool enabled,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
        AppSpacing.vSm,
        TextFormField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium(context),
          decoration: InputDecoration(hintText: hint),
          validator:
              validator ?? _requiredValidator(_normalizeFieldLabel(label)),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(
    BuildContext context, {
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabelBuilder,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge(context)),
        AppSpacing.vSm,
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          decoration: InputDecoration(hintText: hint),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabelBuilder(item),
                    style: AppTextStyles.bodyMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
          validator: validator,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatAddressTypeLabel(String value) {
    return value
        .split('_')
        .map((segment) {
          if (segment.isEmpty) return segment;
          final lower = segment.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _normalizeFieldLabel(String label) {
    return label.replaceAll('*', '').trim();
  }

  String _sanitizeLocationValue(String? value) {
    if (value == null) return '';
    final sanitized =
        value
            .replaceAll(RegExp(r'[\u{1F1E6}\u{1F1FF}]', unicode: true), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    return sanitized;
  }

  LatLng? _parseLatLng(String latitude, String longitude) {
    final lat = double.tryParse(latitude.trim());
    final lng = double.tryParse(longitude.trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  String? Function(String?) _requiredValidator(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required';
      }
      return null;
    };
  }
}

class _AddressFormData {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final List<_ContactFormData> contacts = [_ContactFormData()];

  _AddressLocationType locationType = _AddressLocationType.latLong;
  String? addressType;
  String? country;
  String? state;
  String? city;

  void dispose() {
    labelController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    for (final contact in contacts) {
      contact.dispose();
    }
  }
}

enum _AddressLocationType { polygon, latLong }

class _LocationTypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LocationTypeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: AppTextStyles.bodyMedium(context).fontSize,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            AppSpacing.hSm,
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatLongMapPickerDialog extends StatefulWidget {
  final LatLng initialPoint;
  final double initialZoom;

  const _LatLongMapPickerDialog({
    required this.initialPoint,
    required this.initialZoom,
  });

  @override
  State<_LatLongMapPickerDialog> createState() => _LatLongMapPickerDialogState();
}

class _LatLongMapPickerDialogState extends State<_LatLongMapPickerDialog> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  bool _isLoadingCurrentLocation = true;
  String? _locationErrorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCurrentLocation = true;
      _locationErrorMessage = null;
    });

    try {
      final hasPermission = await LocationPermissionHelper.ensureLocationAccess(
        context,
        actionLabel: 'select address location on map',
      );
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _isLoadingCurrentLocation = false;
          _locationErrorMessage =
              'Current location was not available, so the map opened on the fallback position.';
        });
        return;
      }

      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      final point = LatLng(location.latitude, location.longitude);
      _mapController.move(point, _CreateCustomerSheetState._pickerMapZoom);
      setState(() {
        _selectedPoint = point;
        _isLoadingCurrentLocation = false;
        _locationErrorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCurrentLocation = false;
        _locationErrorMessage =
            'Current location could not be captured, so the map opened on the fallback position.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          color: AppColors.background,
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildBody(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select Location',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap anywhere on the map to fill the latitude and longitude.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
        if (_isLoadingCurrentLocation) ...[
          AppSpacing.vSm,
          Row(
            children: [
              SizedBox(
                width: AppTextStyles.bodySmall(context).fontSize,
                height: AppTextStyles.bodySmall(context).fontSize,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              AppSpacing.hSm,
              Expanded(
                child: Text(
                  'Opening map near your current location...',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ] else if (_locationErrorMessage != null) ...[
          AppSpacing.vSm,
          Text(
            _locationErrorMessage!,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
        AppSpacing.vLg,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: AppColors.primary),
          ),
          padding: const EdgeInsets.all(AppSpacing.xxs),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1.05,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialPoint,
                initialZoom: widget.initialZoom,
                onTap: (_, tappedPoint) {
                  setState(() {
                    _selectedPoint = tappedPoint;
                  });
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'collectivWork',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: AppSpacing.xl + AppSpacing.xl,
                      height: AppSpacing.xl + AppSpacing.xl,
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.error,
                        size: AppTextStyles.heading3(context).fontSize,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppSpacing.vMd,
        Text(
          'Lat: ${_selectedPoint.latitude.toStringAsFixed(6)}\nLng: ${_selectedPoint.longitude.toStringAsFixed(6)}',
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.vLg,
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selectedPoint),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                child: Text(
                  'Use Location',
                  style: AppTextStyles.bodyMediumHeading(context).copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactFormData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  void dispose() {
    nameController.dispose();
    designationController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }
}
