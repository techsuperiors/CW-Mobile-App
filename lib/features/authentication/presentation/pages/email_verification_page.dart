import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_text_field.dart';
import '../../../../core/widgets/common/app_button.dart';
import 'otp_verification_page.dart';

/// Email verification page for forgot password
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Navigate to OTP verification page with the email
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationPage(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      });
    }
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
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: responsiveSpacing(32),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: responsiveSpacing(10)),
                // Logo at top
                Center(
                  child: AppLogo(
                    width: screenWidth * 0.7,
                    height: screenWidth * 0.3,
                  ),
                ),
                SizedBox(height: responsiveSpacing(10)),
                // Message icon
                SvgPicture.asset(
                  AppAssets.otpPageIcon,
                  fit: BoxFit.contain,
                  width: screenWidth * 0.5,
                ),
                SizedBox(height: responsiveSpacing(8)),
                // Forgot Password heading
                Text(
                  AppStrings.forgotPasswordTitle,
                  style: AppTextStyles.heading1(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsiveSpacing(8)),
                // Description text
                Text(
                  AppStrings.enterEmailToReset,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: responsiveSpacing(32)),
                // Email field
                _buildEmailField(),
                SizedBox(height: responsiveSpacing(24)),
                // Submit button
                AppButton(
                  label: AppStrings.sendVerificationCode,
                  onPressed: _handleSubmit,
                  isPrimary: true,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
                SizedBox(height: responsiveSpacing(32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return AppTextField(
      label: AppStrings.email,
      controller: _emailController,
      hint: AppStrings.enterEmail,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterEmail;
        }
        // Basic email validation
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }
}

