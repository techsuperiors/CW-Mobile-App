import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/utils/location_permission_helper.dart';
import '../../../../../../../../../../core/utils/location_service.dart';
import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';

typedef VisitActivitySubmittingSelector =
    bool Function(VisitState state, int activityId);
typedef VisitActivityMessageSelector = String? Function(VisitState state);
typedef VisitActivityLastHandledSelector = int? Function(VisitState state);
typedef VisitActivitySubmitCallback =
    void Function(
      BuildContext context,
      VisitActivityModel activity,
      LocationData location,
      File imageFile,
    );

class VisitActivityCaptureDialog extends StatefulWidget {
  final VisitActivityModel activity;
  final String locationActionLabel;
  final String locationRequiredMessage;
  final String selfiePrompt;
  final String readyBodyKey;
  final VisitActivitySubmittingSelector isSubmittingSelector;
  final VisitActivityMessageSelector successMessageSelector;
  final VisitActivityMessageSelector errorMessageSelector;
  final VisitActivityLastHandledSelector lastHandledActivityIdSelector;
  final VisitActivitySubmitCallback onSubmit;

  const VisitActivityCaptureDialog({
    super.key,
    required this.activity,
    required this.locationActionLabel,
    required this.locationRequiredMessage,
    required this.selfiePrompt,
    required this.readyBodyKey,
    required this.isSubmittingSelector,
    required this.successMessageSelector,
    required this.errorMessageSelector,
    required this.lastHandledActivityIdSelector,
    required this.onSubmit,
  });

  @override
  State<VisitActivityCaptureDialog> createState() =>
      _VisitActivityCaptureDialogState();
}

class _VisitActivityCaptureDialogState extends State<VisitActivityCaptureDialog> {
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  LocationData? _location;
  File? _capturedImageFile;
  bool _isPreparingLocation = true;
  bool _isCapturingImage = false;
  String? _locationError;

  bool get _isSubmitting => widget.isSubmittingSelector(
    context.read<VisitBloc>().state,
    widget.activity.id,
  );

  bool get _canSubmit =>
      !_isPreparingLocation &&
      _location != null &&
      _capturedImageFile != null &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareLocation();
    });
  }

  Future<void> _prepareLocation() async {
    setState(() {
      _isPreparingLocation = true;
      _locationError = null;
      _location = null;
    });

    try {
      final hasPermission = await LocationPermissionHelper.ensureLocationAccess(
        context,
        actionLabel: widget.locationActionLabel,
      );
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _isPreparingLocation = false;
          _locationError = widget.locationRequiredMessage;
        });
        return;
      }

      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _location = location;
        _isPreparingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPreparingLocation = false;
        _locationError = 'Unable to capture current location right now.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    setState(() {
      _isCapturingImage = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        setState(() {
          _capturedImageFile = File(image.path);
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to capture image right now.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingImage = false;
        });
      }
    }
  }

  void _submit() {
    final location = _location;
    final imageFile = _capturedImageFile;
    if (location == null || imageFile == null) {
      return;
    }

    widget.onSubmit(context, widget.activity, location, imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitBloc, VisitState>(
      listenWhen: (previous, current) {
        final previousError = widget.errorMessageSelector(previous);
        final currentError = widget.errorMessageSelector(current);
        final previousSuccess = widget.successMessageSelector(previous);
        final currentSuccess = widget.successMessageSelector(current);
        final previousLastHandled = widget.lastHandledActivityIdSelector(previous);
        final currentLastHandled = widget.lastHandledActivityIdSelector(current);

        return previousError != currentError ||
            previousSuccess != currentSuccess ||
            previousLastHandled != currentLastHandled;
      },
      listener: (context, state) {
        if (widget.lastHandledActivityIdSelector(state) != widget.activity.id) {
          return;
        }

        final successMessage = widget.successMessageSelector(state);
        if (successMessage != null && successMessage.isNotEmpty) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage)),
          );
          context.read<VisitBloc>().add(const ClearVisitFeedback());
          return;
        }

        final errorMessage = widget.errorMessageSelector(state);
        if (errorMessage != null && errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<VisitBloc>().add(const ClearVisitFeedback());
        }
      },
      child: Dialog(
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
            constraints: const BoxConstraints(maxWidth: 360),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Image Capture',
              style: AppTextStyles.bodyMediumHeading(context).copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child:
            _isPreparingLocation
                ? KeyedSubtree(
                  key: const ValueKey('preparing-location'),
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        AppSpacing.vLg,
                        Text(
                          'Preparing location for this activity...',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
                : KeyedSubtree(
                  key: ValueKey(widget.readyBodyKey),
                  child: _buildReadyBody(context),
                ),
      ),
    );
  }

  Widget _buildReadyBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_locationError != null) ...[
          AppSpacing.vSm,
          Text(
            _locationError!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.error),
          ),
          AppSpacing.vSm,
          TextButton(
            onPressed: _isSubmitting ? null : _prepareLocation,
            child: Text(
              'Retry Location',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        AppSpacing.vMd,
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: AppColors.primary),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 0.72,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child:
                      _capturedImageFile != null
                          ? ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            child: Image.file(
                              _capturedImageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: AppTextStyles.heading3(context).fontSize,
                                  color: AppColors.primary,
                                ),
                                AppSpacing.vSm,
                                Text(
                                  widget.selfiePrompt,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ElevatedButton.icon(
                    onPressed:
                        (_isCapturingImage || _isSubmitting)
                            ? null
                            : _capturePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                    ),
                    icon:
                        _isCapturingImage
                            ? SizedBox(
                              width: AppTextStyles.bodySmall(context).fontSize,
                              height: AppTextStyles.bodySmall(context).fontSize,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textWhite,
                              ),
                            )
                            : const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _capturedImageFile == null ? 'Take a photo' : 'Retake',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_location != null) ...[
          AppSpacing.vSm,
          Text(
            _location!.address,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
        AppSpacing.vLg,
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                child:
                    _isSubmitting
                        ? SizedBox(
                          width: AppTextStyles.bodySmall(context).fontSize,
                          height: AppTextStyles.bodySmall(context).fontSize,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textWhite,
                          ),
                        )
                        : Text(
                          'Submit',
                          style: AppTextStyles.bodyMediumHeading(
                            context,
                          ).copyWith(
                            color:
                                _canSubmit
                                    ? AppColors.textWhite
                                    : AppColors.backgroundDark.withValues(
                                      alpha: 0.6,
                                    ),
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
