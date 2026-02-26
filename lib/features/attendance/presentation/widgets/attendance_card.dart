import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/usecases/punch_in_usecase.dart';

// Helper function to get gradient alignment for CSS angle (111.14°)
// CSS: 0° = right, clockwise. The gradient line goes in this direction
List<Alignment> _getGradientAlignment(double angleDegrees) {
  // Convert CSS angle to radians
  // CSS: 0° = right (→), 90° = bottom (↓), 180° = left (←), 270° = top (↑)
  final angleRad = angleDegrees * math.pi / 180;
  
  // Calculate the direction vector for the gradient line
  // For CSS 111.14°, this points down-left
  final dx = math.cos(angleRad);
  final dy = math.sin(angleRad);
  
  // In Flutter, LinearGradient flows from begin to end
  // For CSS 111.14°, colors flow along the perpendicular direction
  // The visual effect: teal at top-left, white at bottom-right
  // So we need the gradient to go from top-left to bottom-right
  // But following the CSS angle direction
  
  // Calculate perpendicular direction (90° rotation)
  final perpDx = -dy;  // Perpendicular x component
  final perpDy = dx;   // Perpendicular y component
  
  // Normalize and create alignment points
  // Begin point (where gradient starts - top-left area)
  // End point (where gradient ends - bottom-right area)
  return [
    Alignment(perpDx, -perpDy), // Begin (adjusted for Flutter's coordinate system)
    Alignment(-perpDx, perpDy),  // End
  ];
}

/// Large attendance card with date, time, progress, and punch in/out button
class AttendanceCard extends StatefulWidget {
  const AttendanceCard({super.key});

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  bool _isPunchedIn = false; // Track punch-in status
  bool _isLoading = false; // Track loading state

  Future<void> _handlePunchIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      // Initialize API client and dependencies
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
      final remoteDataSource = AttendanceRemoteDataSourceImpl(apiClient);
      final repository = AttendanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final punchInUseCase = PunchInUseCase(repository);

      // Call punch-in API
      final result = await punchInUseCase(
        punchInLocation: locationData.address,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        punchType: 'remote',
      );

      result.fold(
        (failure) {
          // Handle error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (success) {
          // Handle success
          setState(() {
            _isPunchedIn = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM, yyyy').format(now);
    final dayTimeStr = DateFormat('EEEE, hh:mm a').format(now);
    
    // Calculate progress - nearly complete with small blue segment at top
    // Based on screenshot: mostly green (about 90-95%), small blue segment
    const double progress = 0.60; // 92% green, 8% blue
    
    return Transform.translate(
      offset: const Offset(0, -12), // Overlap header slightly
      child: Container(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
          MediaQuery.of(context).size.height * 0.0125, // 1.25% of screen height
          MediaQuery.of(context).size.width * 0.053,
          MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _getGradientAlignment(111.14)[0],
            end: _getGradientAlignment(111.14)[1],
            stops: const [0.0, 0.4, 0.8676], // Start with teal, transition to white
            colors: [
              AppColors.attendanceTeal,
              AppColors.attendanceTeal,
              AppColors.background,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Date, time, and button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date
                  Text(
                    dateStr,
                    style: AppTextStyles.heading4(context).copyWith(
                      color: AppColors.textWhite,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.0075), // 0.75% of screen height
                  // Day and time
                  Text(
                    dayTimeStr,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textWhite,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
                  // Punch In/Out button
                  ElevatedButton(
                    onPressed: _isPunchedIn ? () {
                      // TODO: Implement punch-out functionality when API is available
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Punch-out functionality coming soon'),
                        ),
                      );
                    } : _isLoading ? null : _handlePunchIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPunchedIn ? AppColors.background : AppColors.attendanceTeal,
                      foregroundColor: _isPunchedIn ? AppColors.textPrimary : AppColors.textWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
                        vertical: MediaQuery.of(context).size.height * 0.0175, // 1.75% of screen height
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // More rounded/oval
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.037,
                            height: MediaQuery.of(context).size.width * 0.037,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.064, // ~6.4% of screen width
                                height: MediaQuery.of(context).size.width * 0.064,
                                decoration: BoxDecoration(
                                  color: _isPunchedIn ? AppColors.success : AppColors.textWhite,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPunchedIn ? Icons.arrow_back : Icons.arrow_forward,
                                  color: _isPunchedIn ? AppColors.textWhite : AppColors.attendanceTeal,
                                  size: MediaQuery.of(context).size.width * 0.037, // ~3.7% of screen width
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.021), // ~2.1% of screen width
                              Text(
                                _isPunchedIn ? AppStrings.punchOut : AppStrings.punchIn,
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _isPunchedIn ? AppColors.textPrimary : AppColors.textWhite,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
            // Right side - Circular progress
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                children: [
                  // Inner circle with gradient border, inset shadows, and background gradient
                  Stack(
                    children: [
                      // Outer circle with gradient border (0.86px)
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            // 44.27deg gradient for border
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.attendanceAlmostWhite,
                              AppColors.attendanceLightBlueGrey,
                            ],
                            stops: const [0.273, 0.8825],
                          ),
                        ),
                      ),
                      // Inner circle with background gradient and inset shadows
                      Center(
                        child: Container(
                          width: 90 - (0.86 * 2), // Subtract border width
                          height: 90 - (0.86 * 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.attendanceGreyBlue,
                                AppColors.attendanceVeryLightGreyBlue,
                              ],
                            ),
                            boxShadow: [
                              // First inset shadow
                              BoxShadow(
                                color: AppColors.attendanceLightBlueGrey.withOpacity(0.71),
                                blurRadius: 25.76,
                                spreadRadius: -0.86,
                                offset: const Offset(8.59, 9.45),
                              ),
                              // Second inset shadow
                              BoxShadow(
                                color: AppColors.attendanceLightBlueGrey.withOpacity(0.52),
                                blurRadius: 6.87,
                                spreadRadius: 0,
                                offset: const Offset(6.01, 6.01),
                              ),
                              // Third inset shadow (negative offset for inset effect)
                              BoxShadow(
                                color: AppColors.background.withOpacity(0.2),
                                blurRadius: 25.76,
                                spreadRadius: 0,
                                offset: const Offset(-10.31, -10.31),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Progress ring
                  CustomPaint(
                    size: const Size(90, 90),
                    painter: CircularProgressPainter(
                      progress: progress,
                      progressColor: AppColors.success,
                      remainingColor: AppColors.background,
                      strokeWidth: 10,
                    ),
                  ),
                  // Time text
                  Center(
                    child: Text(
                      '07:35',
                      style: AppTextStyles.heading5(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.attendanceTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for circular progress indicator with two colors
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color remainingColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.remainingColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final startAngle = -math.pi / 2; // Start from top (12 o'clock)
    final progressSweepAngle = 2 * math.pi * progress;

    // Create SweepGradient with smooth color blending
    // Since SweepGradient goes full circle, we use many intermediate colors
    // to ensure smooth blending across the progress arc portion
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final progressGradient = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle, // Align with arc start
      colors: [
        AppColors.successDark,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accentLight,
      ],
      stops: const [
        0.0, 0.07, 0.14, 0.21, 0.29, 0.36, 0.43, 0.5, 0.57, 0.64, 0.71, 0.79, 0.86, 0.93, 1.0
      ],
    );

    // Draw progress arc with gradient
    final progressPaint = Paint()
      ..shader = progressGradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      rect,
      startAngle,
      progressSweepAngle,
      false,
      progressPaint,
    );

    // Draw remaining arc with gradient, border, and shadow
    final remainingSweepAngle = 2 * math.pi * (1 - progress);
    
    if (remainingSweepAngle > 0) {
      // Calculate the angle for the remaining arc
      final remainingStartAngle = startAngle + progressSweepAngle;
      
      // Create gradient for remaining arc (white with subtle gradient for depth)
      // Using LinearGradient along the arc direction for better visual effect
      final remainingGradient = SweepGradient(
        center: Alignment.center,
        startAngle: remainingStartAngle,
        colors: [
          AppColors.background,
          AppColors.attendanceVeryLightGrey,
          AppColors.attendanceGreyDepth,
          AppColors.attendanceVeryLightGrey,
          AppColors.background,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

      // Draw shadow layer for remaining arc (creates depth effect)
      final shadowPaint = Paint()
        ..color = AppColors.textPrimary.withOpacity(0.1)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..isAntiAlias = true;

      // Draw shadow with slight offset to create depth
      canvas.save();
      canvas.translate(2.0, 2.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        shadowPaint,
      );
      canvas.restore();

      // Draw light border as base layer (creates visible edge definition)
      // Draw a slightly larger stroke first to create border effect
      final borderBasePaint = Paint()
        ..color = AppColors.attendanceLightGreyBorder
        ..strokeWidth = strokeWidth + 2.0 // Slightly larger for visible border
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        borderBasePaint,
      );

      // Draw remaining arc with internal gradient (main fill) on top of border
      final remainingPaint = Paint()
        ..shader = remainingGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        remainingPaint,
      );

      // Draw inner highlight for premium 3D effect
      final innerHighlightRadius = radius - (strokeWidth / 2) + 0.5;
      final innerHighlightPaint = Paint()
        ..color = AppColors.background.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerHighlightRadius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        innerHighlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.remainingColor != remainingColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

