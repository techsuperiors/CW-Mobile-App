import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_button.dart';
import '../bloc/forgot_password/forgot_password_bloc.dart';
import '../bloc/forgot_password/forgot_password_event.dart';
import '../bloc/forgot_password/forgot_password_state.dart';
import 'reset_password_page.dart';

/// OTP Verification page matching CollectivWork design
class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _remainingSeconds = 80; // 01:20 in seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _resendCode() {
    if (_canResend) {
      setState(() {
        _remainingSeconds = 80;
        _canResend = false;
      });
      _timer?.cancel();
      _startTimer();
      context.read<ForgotPasswordBloc>().add(
        ForgotPasswordResendRequested(widget.email),
      );
    }
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}${AppStrings.sec}';
  }

  void _handleOtpChange(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handlePaste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _otpControllers[i].text = digits[i];
    }
    if (digits.length >= 6) {
      _focusNodes[5].unfocus();
    } else if (digits.isNotEmpty) {
      _focusNodes[digits.length].requestFocus();
    }
  }

  void _handleSubmit() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseEnterCompleteOtp),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordOtpValidated(email: widget.email, otp: otp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Responsive spacing helper
    double responsiveSpacing(double baseSpacing) {
      if (screenHeight < 600) {
        return baseSpacing * 0.75;
      } else if (screenHeight < 700) {
        return baseSpacing * 0.85;
      }
      return baseSpacing;
    }

    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordOtpValidatedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.otpVerifiedSuccessfully),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => BlocProvider.value(
                    value: context.read<ForgotPasswordBloc>(),
                    child: const ResetPasswordPage(),
                  ),
            ),
          );
        } else if (state is ForgotPasswordResendSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.verificationCodeSent),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<ForgotPasswordBloc>().add(const ForgotPasswordReset());
        } else if (state is ForgotPasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Normal Teal Header Section with curved bottom (just back button)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.attendanceTeal, // 0xFF0B7F7F
                            Color(0xFF073F3F), // mid blend
                            AppColors.attendancedarkbottom, // 0xFF031e1e
                          ],
                          stops: [0.0, 0.85, 1.0],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: screenHeight * 0.04),
                            // Back button and title row
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: AppColors.textWhite,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Flexible(
                                    child: Text(
                                      AppStrings.otp,
                                      style: AppTextStyles.bodyMedium(
                                        context,
                                      ).copyWith(color: AppColors.textWhite),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
                    // White Content Section with title and email
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.064,
                          // ~6.4% of screen width
                          vertical: screenHeight * 0.04, // 4% of screen height
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: responsiveSpacing(20)),
                            // Main title - on white background
                            Text(
                              AppStrings.getYourCode,
                              style: AppTextStyles.heading1(context).copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: responsiveSpacing(12)),
                            // Instructional text with email - on white background
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0),
                              child: RichText(
                                textAlign: TextAlign.start,
                                text: TextSpan(
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.weveSentVerificationCode,
                                      style: AppTextStyles.bodyMedium(
                                        context,
                                      ).copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        wordSpacing: 1.6,
                                        fontSize:
                                            AppTextStyles.bodySmall(
                                              context,
                                            ).fontSize,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${widget.email}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        fontSize:
                                            AppTextStyles.bodyMediumHeading(
                                              context,
                                            ).fontSize,
                                      ),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: AppStrings.wrongEmail,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.loginHeaderTeal,
                                        decoration: TextDecoration.underline,
                                        fontSize:
                                            AppTextStyles.bodyMediumHeading(
                                              context,
                                            ).fontSize,
                                      ),
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              // Pop back to forgot password page (bloc preserved)
                                              Navigator.pop(context);
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: responsiveSpacing(40)),
                            // OTP Input Fields - Centered
                            _buildOtpFields(context),
                            SizedBox(height: responsiveSpacing(32)),
                            // Verify and Proceed button
                            BlocBuilder<
                              ForgotPasswordBloc,
                              ForgotPasswordState
                            >(
                              builder: (context, state) {
                                return AppButton(
                                  label: AppStrings.verifyAndProceed,
                                  onPressed: _handleSubmit,
                                  isPrimary: true,
                                  isLoading: state is ForgotPasswordLoading,
                                  width: double.infinity,
                                  backgroundColor: AppColors.loginHeaderTeal,
                                );
                              },
                            ),
                            SizedBox(height: responsiveSpacing(24)),
                            // Resend Code and Timer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Resend Code link
                                Flexible(
                                  child: GestureDetector(
                                    onTap: _canResend ? _resendCode : null,
                                    child: Text(
                                      AppStrings.resendCode,
                                      style: AppTextStyles.bodyMediumHeading(
                                        context,
                                      ).copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _canResend
                                                ? AppColors.loginHeaderTeal
                                                : AppColors.textTertiary,
                                        decoration:
                                            _canResend
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                // Timer
                                Flexible(
                                  child: Text(
                                    _formatTimer(_remainingSeconds),
                                    style: AppTextStyles.bodyMediumHeading(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: responsiveSpacing(32)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpFields(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive spacing and field width based on available width
        // We want 6 fields with 5 gaps between them
        final availableWidth = constraints.maxWidth;
        // Use 1.5% of available width for spacing between fields (responsive)
        final spacing = availableWidth * 0.015;
        // Calculate field width: (availableWidth - 5*spacing) / 6
        final fieldWidth = (availableWidth - (5 * spacing)) / 6;
        final fieldHeight = fieldWidth * 1.2; // Maintain aspect ratio

        // Clamp values to ensure reasonable sizes on all screens
        final finalSpacing = spacing.clamp(5.0, 10.0);
        final finalFieldWidth = fieldWidth.clamp(18.0, 36.0);
        final finalFieldHeight = finalFieldWidth * 1.2;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index < 5 ? finalSpacing : 0),
              child: SizedBox(
                width: finalFieldWidth,
                height: finalFieldHeight,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  style: AppTextStyles.heading2(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.loginHeaderTeal,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (value) => _handleOtpChange(value, index),
                  onTap: () {
                    // Select all text when tapped
                    _otpControllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _otpControllers[index].text.length,
                    );
                  },
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
