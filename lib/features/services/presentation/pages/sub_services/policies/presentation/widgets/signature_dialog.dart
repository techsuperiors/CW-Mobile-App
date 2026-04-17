import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:signature/signature.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Dialog for capturing signature via drawing or upload
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isDrawMode = true;
  Uint8List? _uploadedSignature;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleFilePicker() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 90,
      );

      if (image != null) {
        final File file = File(image.path);
        final Uint8List bytes = await file.readAsBytes();
        setState(() {
          _uploadedSignature = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmSignature() async {
    if (_isDrawMode) {
      if (_signatureController.isNotEmpty) {
        final bytes = await _signatureController.toPngBytes();
        final croppedBytes = _cropDrawnSignature(bytes);
        if (!mounted) return;
        Navigator.of(context).pop(croppedBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please draw your signature'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } else {
      if (_uploadedSignature != null) {
        Navigator.of(context).pop(_uploadedSignature);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your signature'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Uint8List? _cropDrawnSignature(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return bytes;
    }

    final image = img.decodePng(bytes);
    if (image == null) {
      return bytes;
    }

    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 0) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      return bytes;
    }

    const padding = 12;
    final cropX = (minX - padding).clamp(0, image.width - 1);
    final cropY = (minY - padding).clamp(0, image.height - 1);
    final cropRight = (maxX + padding).clamp(0, image.width - 1);
    final cropBottom = (maxY + padding).clamp(0, image.height - 1);
    final cropWidth = cropRight - cropX + 1;
    final cropHeight = cropBottom - cropY + 1;

    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    return Uint8List.fromList(img.encodePng(cropped));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: DottedBorderPainter(
            color: AppColors.primaryLight,
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Signature',
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Radio Buttons
            Row(
              children: [
                Expanded(
                  child: _buildRadioOption(
                    'Draw Signature',
                    true,
                    () {
                      setState(() {
                        _isDrawMode = true;
                        _uploadedSignature = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRadioOption(
                    'Upload Signature',
                    false,
                    () {
                      setState(() {
                        _isDrawMode = false;
                        _signatureController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Signature Area
            _isDrawMode ? _buildDrawArea() : _buildUploadArea(),
            const SizedBox(height: 20),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: AppTextStyles.buttonMedium(context),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.buttonMedium(context).copyWith(
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
    );
  }

  Widget _buildRadioOption(String label, bool value, VoidCallback onTap) {
    final bool isSelected = _isDrawMode == value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calculate responsive sizes
        final radioSize = screenWidth < 360 ? 18.0 : 20.0;
        final radioInnerSize = screenWidth < 360 ? 8.0 : 10.0;
        final spacing = screenWidth < 360 ? 6.0 : 8.0;
        final fontSize = availableWidth < 120 
            ? AppTextStyles.bodySmall(context).fontSize! * 0.85
            : AppTextStyles.bodyMedium(context).fontSize! * 0.9;
        
        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: radioSize,
                height: radioSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.border,
                    width: 2,
                  ),
                  color: Colors.white,
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: radioInnerSize,
                          height: radioInnerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: spacing),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Signature(
          controller: _signatureController,
          backgroundColor: Colors.white,
          width: double.infinity,
          height: 200,
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _handleFilePicker,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: DottedBorderPainter(
            color: AppColors.primaryLight,
          ),
          child: _uploadedSignature != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _uploadedSignature!,
                    fit: BoxFit.contain,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Text(
                        'Click to upload or drag and drop',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Text(
                        'SVG, PNG, JPG or GIF (max. 800x400px)',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Custom painter for dotted border
class DottedBorderPainter extends CustomPainter {
  final Color color;

  DottedBorderPainter({this.color = AppColors.primaryLight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8),
        ),
      );

    // Create a dashed path effect
    final dashPath = _dashPath(path, dashArray: const [5.0, 5.0]);

    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path path, {required List<double> dashArray}) {
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      var dashIndex = 0;
      while (distance < pathMetric.length) {
        final length = dashArray[dashIndex % dashArray.length];
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length;
        dashIndex++;
        if (distance < pathMetric.length && dashArray.length > 1) {
          distance += dashArray[dashIndex % dashArray.length];
          dashIndex++;
        }
      }
    }

    return dashPath;
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
