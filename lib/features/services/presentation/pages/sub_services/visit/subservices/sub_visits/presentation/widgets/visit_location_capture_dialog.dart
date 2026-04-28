import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/utils/location_permission_helper.dart';
import '../../../../../../../../../../core/utils/location_service.dart';

class VisitLocationCaptureDialog extends StatefulWidget {
  const VisitLocationCaptureDialog();

  @override
  State<VisitLocationCaptureDialog> createState() =>
      VisitLocationCaptureDialogState();
}

class VisitLocationCaptureDialogState
    extends State<VisitLocationCaptureDialog> {
  final LocationService _locationService = LocationService();
  LocationData? _location;
  bool _isCapturingLocation = true;
  String? _errorMessage;

  final double _locationDialogMaxWidth = 420;
  final double _locationPreviewAspectRatio = 1.15;
  final double _visitLocationPreviewZoom = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureLocation();
    });
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
      _errorMessage = null;
      _location = null;
    });

    try {
      final hasPermission = await LocationPermissionHelper.ensureLocationAccess(
        context,
        actionLabel: 'capture visit location',
      );
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _isCapturingLocation = false;
          _errorMessage =
              'Location access is needed to capture the visit location.';
        });
        return;
      }

      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _location = location;
        _isCapturingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCapturingLocation = false;
        _errorMessage = 'Unable to capture current location right now.';
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
          constraints:  BoxConstraints(maxWidth: _locationDialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg,horizontal: AppSpacing.lg),
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
              'Location Capture',
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
    if (_isCapturingLocation) {
      return AspectRatio(
        aspectRatio: _locationPreviewAspectRatio,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            AppSpacing.vLg,
            Text(
              'Capturing your current location...',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.vLg,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: ElevatedButton(
                  onPressed: _captureLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                  ),
                  child: Text(
                    'Retry',
                    style: AppTextStyles.bodyMedium(context).copyWith(
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

    final location = _location;
    if (location == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your current location has been captured',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
        AppSpacing.vLg,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: AppColors.primary),
          ),
          padding: EdgeInsets.all(AppSpacing.xxs),
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: _locationPreviewAspectRatio,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(location.latitude, location.longitude),
                initialZoom: _visitLocationPreviewZoom,
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
                      point: LatLng(location.latitude, location.longitude),
                      width: AppTextStyles.heading3(context).fontSize ?? 28,
                      height: AppTextStyles.heading3(context).fontSize ?? 28,
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
          location.address,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.textSecondary,
            decorationColor: AppColors.primary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
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
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                child: Text(
                  'Continue',
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
