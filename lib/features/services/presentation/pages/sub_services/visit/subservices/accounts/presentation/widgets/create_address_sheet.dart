import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

class CreateAddressSheet extends StatefulWidget {
  const CreateAddressSheet({super.key});

  @override
  State<CreateAddressSheet> createState() => _CreateAddressSheetState();
}

class _CreateAddressSheetState extends State<CreateAddressSheet> {
  static const List<String> _addressTypes = [
    'SITE',
    'CLIENT',
    'WAREHOUSE',
    'OFFICE',
    'VENDOR',
    'DISTRIBUTION_CENTER',
    'OTHER',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  String? _selectedAddressType;
  String? _country;
  String? _state;
  String? _city;
  _AddressLocationType _locationType = _AddressLocationType.latLong;
  List<LatLng> _polygonPoints = const [];
  bool _showSelectionErrors = false;

  @override
  void dispose() {
    _addressNameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  bool _hasValidSelections() {
    return (_selectedAddressType ?? '').trim().isNotEmpty &&
        (_city ?? '').trim().isNotEmpty &&
        (_locationType != _AddressLocationType.polygon ||
            _polygonPoints.length >= 3);
  }

  void _submit(AccountState state) {
    FocusScope.of(context).unfocus();
    setState(() {
      _showSelectionErrors = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || !_hasValidSelections()) {
      return;
    }

    final polygon =
        _locationType == _AddressLocationType.polygon
            ? _closedPolygonPoints(_polygonPoints)
            : const <LatLng>[];

    context.read<AccountBloc>().add(
      CreateAccountAddressRequested(
        CreateVisitAddressParams(
          addressName: _addressNameController.text.trim(),
          addressType: _selectedAddressType!.trim(),
          pincode: _pincodeController.text.trim(),
          city: (_city ?? '').trim(),
          state: (_state ?? '').trim(),
          country: (_country ?? '').trim(),
          latitude:
              _locationType == _AddressLocationType.latLong
                  ? _latitudeController.text.trim()
                  : '',
          longitude:
              _locationType == _AddressLocationType.latLong
                  ? _longitudeController.text.trim()
                  : '',
          polygon:
              polygon
                  .map(
                    (point) => CreateVisitAddressPolygonPointParams(
                      latitude: point.latitude,
                      longitude: point.longitude,
                    ),
                  )
                  .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _openLatLongPicker() async {
    final initialPoint = _parseLatLng(
      _latitudeController.text,
      _longitudeController.text,
    );

    final selectedPoint = await showDialog<LatLng>(
      context: context,
      builder:
          (_) => _LatLongMapPickerDialog(
            initialPoint: initialPoint,
          ),
    );

    if (!mounted || selectedPoint == null) return;

    setState(() {
      _latitudeController.text = selectedPoint.latitude.toStringAsFixed(6);
      _longitudeController.text = selectedPoint.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _openPolygonPicker() async {
    final points = await showDialog<List<LatLng>>(
      context: context,
      builder: (_) => _PolygonMapPickerDialog(initialPoints: _polygonPoints),
    );

    if (!mounted || points == null) return;

    setState(() {
      _polygonPoints = points;
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
            initialChildSize: 0.84,
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
                              AppAssets.location_Icon,
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
                            'Add Address',
                            style: AppTextStyles.heading4(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vSm,
                          Text(
                            'Create a visit address with optional map-based location details.',
                            style: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                          AppSpacing.vLg,
                          Text(
                            'Address Details',
                            style: AppTextStyles.labelLarge(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vMd,
                          _buildTextField(
                            context,
                            label: 'Label*',
                            hint: 'Enter address name',
                            controller: _addressNameController,
                            enabled: !state.isCreatingAddress,
                          ),
                          AppSpacing.vLg,
                          _buildDropdownField<String>(
                            context,
                            label: 'Type*',
                            hint: 'Select',
                            value: _selectedAddressType,
                            items: _addressTypes,
                            itemLabelBuilder: _formatAddressTypeLabel,
                            onChanged:
                                state.isCreatingAddress
                                    ? null
                                    : (value) => setState(
                                      () => _selectedAddressType = value,
                                    ),
                            validator:
                                (value) =>
                                    (value ?? '').trim().isEmpty
                                        ? 'Type is required'
                                        : null,
                          ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Address',
                            hint: 'Enter full address',
                            controller: _addressController,
                            enabled: !state.isCreatingAddress,
                            minLines: 2,
                            maxLines: 3,
                            validator: (_) => null,
                          ),
                          AppSpacing.vLg,
                          Text('Country', style: AppTextStyles.labelLarge(context)),
                          AppSpacing.vSm,
                          AbsorbPointer(
                            absorbing: state.isCreatingAddress,
                            child: CSCPickerPlus(
                              flagState: CountryFlag.DISABLE,
                              layout: Layout.vertical,
                              currentCountry: _country,
                              currentState: _state,
                              currentCity: _city,
                              countryDropdownLabel: 'Select country',
                              stateDropdownLabel: 'Select state',
                              cityDropdownLabel: 'Select city',
                              countrySearchPlaceholder: 'Search country',
                              stateSearchPlaceholder: 'Search state',
                              citySearchPlaceholder: 'Search city',
                              selectedItemStyle: AppTextStyles.bodyMedium(
                                context,
                              ),
                              dropdownItemStyle: AppTextStyles.bodyMedium(
                                context,
                              ),
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
                                  _country = _sanitizeLocationValue(value);
                                  _state = null;
                                  _city = null;
                                });
                              },
                              onStateChanged: (value) {
                                setState(() {
                                  _state = _sanitizeLocationValue(value);
                                  _city = null;
                                });
                              },
                              onCityChanged: (value) {
                                setState(() {
                                  _city = _sanitizeLocationValue(value);
                                });
                              },
                            ),
                          ),
                          if (_showSelectionErrors && (_city ?? '').trim().isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: Text(
                                'City is required',
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.error),
                              ),
                            ),
                          AppSpacing.vLg,
                          _buildTextField(
                            context,
                            label: 'Pincode*',
                            hint: 'Enter pincode',
                            controller: _pincodeController,
                            enabled: !state.isCreatingAddress,
                            keyboardType: TextInputType.number,
                          ),
                          AppSpacing.vLg,
                          _buildLocationTypeSection(context, state),
                          AppSpacing.vXl,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  state.isCreatingAddress
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
                                  state.isCreatingAddress
                                      ? const SizedBox(
                                        height: AppSpacing.lg + AppSpacing.xxs,
                                        width: AppSpacing.lg + AppSpacing.xxs,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textWhite,
                                        ),
                                      )
                                      : Text(
                                        'Add Address',
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
                                  state.isCreatingAddress
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: AppSpacing.buttonPadding,
                                side: const BorderSide(
                                  color: AppColors.border,
                                ),
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

  Widget _buildLocationTypeSection(BuildContext context, AccountState state) {
    final hasPolygonError =
        _showSelectionErrors &&
        _locationType == _AddressLocationType.polygon &&
        _polygonPoints.length < 3;

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
                  isSelected: _locationType == _AddressLocationType.polygon,
                  onTap:
                      state.isCreatingAddress
                          ? null
                          : () => setState(
                            () => _locationType = _AddressLocationType.polygon,
                          ),
                ),
              ),
              Expanded(
                child: _LocationTypeOption(
                  label: 'Latitude / Longitude',
                  isSelected: _locationType == _AddressLocationType.latLong,
                  onTap:
                      state.isCreatingAddress
                          ? null
                          : () => setState(
                            () => _locationType = _AddressLocationType.latLong,
                          ),
                ),
              ),
            ],
          ),
          AppSpacing.vSm,
          if (_locationType == _AddressLocationType.latLong) ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed:
                    state.isCreatingAddress ? null : _openLatLongPicker,
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
                    controller: _latitudeController,
                    enabled: !state.isCreatingAddress,
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
                    controller: _longitudeController,
                    enabled: !state.isCreatingAddress,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (_) => null,
                  ),
                ),
              ],
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed:
                    state.isCreatingAddress ? null : _openPolygonPicker,
                icon: const Icon(Icons.polyline_outlined),
                label: Text(
                  'Draw Polygon',
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
            Text(
              _polygonPoints.isEmpty
                  ? 'No polygon selected yet.'
                  : '${_polygonPoints.length} point(s) selected',
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            if (hasPolygonError) ...[
              AppSpacing.vXs,
              Text(
                'Select at least 3 points for a polygon',
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.error),
              ),
            ],
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
          items:
              items
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

  String? Function(String?) _requiredValidator(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required';
      }
      return null;
    };
  }

  String _sanitizeLocationValue(String? value) {
    if (value == null) return '';
    final sanitized =
        value
            .replaceAll(
              RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true),
              '',
            )
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

  List<LatLng> _closedPolygonPoints(List<LatLng> points) {
    if (points.length < 3) return points;
    final first = points.first;
    final last = points.last;
    final isClosed =
        first.latitude == last.latitude && first.longitude == last.longitude;
    if (isClosed) return points;
    return [...points, first];
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
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatLongMapPickerDialog extends StatefulWidget {
  final LatLng? initialPoint;

  const _LatLongMapPickerDialog({required this.initialPoint});

  @override
  State<_LatLongMapPickerDialog> createState() => _LatLongMapPickerDialogState();
}

class _LatLongMapPickerDialogState extends State<_LatLongMapPickerDialog> {
  static const double _defaultMapZoom = 5.5;
  static const double _pickerMapZoom = 15;
  static const LatLng _defaultMapCenter = LatLng(22.5937, 78.9629);

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  bool _isLoadingCurrentLocation = true;
  String? _locationErrorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint ?? _defaultMapCenter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted || widget.initialPoint != null) {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
      return;
    }

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
      _mapController.move(point, _pickerMapZoom);
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
              _buildHeader(context, 'Select Location'),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
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
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
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
                    _buildMapFrame(
                      context,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: widget.initialPoint ?? _defaultMapCenter,
                          initialZoom:
                              widget.initialPoint == null
                                  ? _defaultMapZoom
                                  : _pickerMapZoom,
                          onTap: (_, tappedPoint) {
                            setState(() {
                              _selectedPoint = tappedPoint;
                            });
                          },
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                  size:
                                      AppTextStyles.heading3(context).fontSize,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    _buildDialogActions(
                      context,
                      primaryLabel: 'Use Location',
                      onPrimary: () => Navigator.of(context).pop(_selectedPoint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolygonMapPickerDialog extends StatefulWidget {
  final List<LatLng> initialPoints;

  const _PolygonMapPickerDialog({required this.initialPoints});

  @override
  State<_PolygonMapPickerDialog> createState() => _PolygonMapPickerDialogState();
}

class _PolygonMapPickerDialogState extends State<_PolygonMapPickerDialog> {
  static const double _defaultMapZoom = 5.5;
  static const double _pickerMapZoom = 15;
  static const LatLng _defaultMapCenter = LatLng(22.5937, 78.9629);

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  late List<LatLng> _points;
  bool _isLoadingCurrentLocation = true;
  String? _locationErrorMessage;

  @override
  void initState() {
    super.initState();
    _points = List<LatLng>.from(widget.initialPoints);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted || _points.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingCurrentLocation = true;
      _locationErrorMessage = null;
    });

    try {
      final hasPermission = await LocationPermissionHelper.ensureLocationAccess(
        context,
        actionLabel: 'draw polygon on map',
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
      _mapController.move(point, _pickerMapZoom);
      setState(() {
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
              _buildHeader(context, 'Draw Polygon'),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap on the map to add polygon points. Use at least 3 points.',
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
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
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
                    _buildMapFrame(
                      context,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _points.isNotEmpty ? _points.first : _defaultMapCenter,
                          initialZoom:
                              _points.isEmpty ? _defaultMapZoom : _pickerMapZoom,
                          onTap: (_, tappedPoint) {
                            setState(() {
                              _points = [..._points, tappedPoint];
                            });
                          },
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'collectivWork',
                          ),
                          if (_points.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _displayPolygonPoints(_points),
                                  strokeWidth: 3,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          if (_points.length >= 3)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: _points,
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  borderColor: AppColors.primary,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers:
                                _points
                                    .map(
                                      (point) => Marker(
                                        point: point,
                                        width: AppSpacing.lg + AppSpacing.md,
                                        height: AppSpacing.lg + AppSpacing.md,
                                        child: Icon(
                                          Icons.location_on,
                                          color: AppColors.error,
                                          size: AppTextStyles.heading5(
                                            context,
                                          ).fontSize,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vMd,
                    Text(
                      '${_points.length} point(s) selected',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    AppSpacing.vMd,
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _points.isEmpty
                                    ? null
                                    : () => setState(() {
                                      _points = _points.sublist(
                                        0,
                                        _points.length - 1,
                                      );
                                    }),
                            child: Text(
                              'Undo',
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          ),
                        ),
                        AppSpacing.hMd,
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _points.isEmpty
                                    ? null
                                    : () => setState(() {
                                      _points = const [];
                                    }),
                            child: Text(
                              'Clear',
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vLg,
                    _buildDialogActions(
                      context,
                      primaryLabel: 'Use Polygon',
                      isPrimaryEnabled: _points.length >= 3,
                      onPrimary: () => Navigator.of(context).pop(_points),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LatLng> _displayPolygonPoints(List<LatLng> points) {
    if (points.length < 2) return points;
    final first = points.first;
    final last = points.last;
    final isClosed =
        first.latitude == last.latitude && first.longitude == last.longitude;
    return isClosed ? points : [...points, first];
  }
}

Widget _buildHeader(BuildContext context, String title) {
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
            title,
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

Widget _buildMapFrame(BuildContext context, {required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      border: Border.all(color: AppColors.primary),
    ),
    padding: const EdgeInsets.all(AppSpacing.xxs),
    clipBehavior: Clip.antiAlias,
    child: AspectRatio(aspectRatio: 1.05, child: child),
  );
}

Widget _buildDialogActions(
  BuildContext context, {
  required String primaryLabel,
  required VoidCallback onPrimary,
  bool isPrimaryEnabled = true,
}) {
  return Row(
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
          onPressed: isPrimaryEnabled ? onPrimary : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
          child: Text(
            primaryLabel,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}
