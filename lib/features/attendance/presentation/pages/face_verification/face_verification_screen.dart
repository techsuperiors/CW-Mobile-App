import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive helpers
    final size = MediaQuery.of(context).size;
    final screenH = size.height;
    final screenW = size.width;

    // Oval size: 60% of screen width, max 300
    final ovalSize = (screenW * 0.62).clamp(200.0, 300.0);

    // Font sizes
    final instrFontSize = (screenW * 0.034).clamp(12.0, 15.0);

    // Button height
    final btnHeight = (screenH * 0.068).clamp(50.0, 60.0);

    // Vertical spacers
    final topFlex = screenH < 700 ? 1 : 2;
    final midFlex = screenH < 700 ? 2 : 3;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenW * 0.06),
          child: Column(
            children: [
              Spacer(flex: topFlex),

              // Face oval frame
              // AnimatedBuilder(
              //   animation: _pulseAnimation,
              //   builder: (context, child) => Transform.scale(
              //     scale: _pulseAnimation.value,
              //     child: child,
              //   ),
              //   child: SizedBox(
              //     width: ovalSize,
              //     height: ovalSize,
              //     child: CustomPaint(painter: FaceOvalPainter()),
              //   ),
              // ),
              CircularCameraView(),
              SizedBox(height: screenH * 0.03),

              // Instruction text
              Text(
                'Position your face inside the frame and ensure good lighting. '
                    'This helps us accurately verify your identity for attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFB0BEC5),
                  fontSize: instrFontSize,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),

              Spacer(flex: midFlex),

              // Click Photo button
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Click Photo',
                    style: TextStyle(
                      fontSize: (screenW * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenH * 0.015),

              // Cancel button
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                        color: Color(0xFF3A4A5C), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: (screenW * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenH * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
        center: center, width: size.width, height: size.height);

    // Glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(rect, glowPaint);

    // Main border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(rect, borderPaint);

    // Teal corner accents
    final accentPaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const arcLength = 0.35;
    for (final angle in [-math.pi / 2, 0.0, math.pi / 2, math.pi]) {
      canvas.drawArc(rect, angle - arcLength / 2, arcLength, false, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularCameraView extends StatefulWidget {
  const CircularCameraView({super.key});

  @override
  State<CircularCameraView> createState() => _CircularCameraViewState();
}

class _CircularCameraViewState extends State<CircularCameraView> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> _openCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openCamera,
      child: ClipOval(
        child: SizedBox(
          width: 200,
          height: 200,
          child: _image != null
              ? Image.file(_image!, fit: BoxFit.cover)  // li hui image dikhao
              : Container(
            color: Colors.grey[300],
            child: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}