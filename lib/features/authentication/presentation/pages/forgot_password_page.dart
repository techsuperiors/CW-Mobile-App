import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_text_field.dart';
import '../../../../core/widgets/common/app_button.dart';
import '../bloc/forgot_password/forgot_password_bloc.dart';
import '../bloc/forgot_password/forgot_password_event.dart';
import '../bloc/forgot_password/forgot_password_state.dart';
import 'otp_verification_page.dart';

/// Forgot password page
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<ForgotPasswordBloc>().add(
            ForgotPasswordRequested(_emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    
    // Responsive header height - adjust for smaller screens
    double headerHeightRatio = 0.35;
    if (screenHeight < 600) {
      headerHeightRatio = 0.30;
    } else if (screenHeight > 800) {
      headerHeightRatio = 0.38;
    }
    final headerHeight = screenHeight * headerHeightRatio;
    
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
        if (state is ForgotPasswordForgotSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ForgotPasswordBloc>(),
                child: OtpVerificationPage(email: state.email),
              ),
            ),
          );
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
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Teal Header Section with curved bottom
                    Container(
                      height: headerHeight,
                      decoration: BoxDecoration(
                        color: AppColors.loginHeaderTeal,
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final topSpacing = availableHeight * 0.05;
                            final titleSpacing = availableHeight * 0.03;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: topSpacing),
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
                                          AppStrings.forgetPassword,
                                          style: AppTextStyles.bodyMedium(context).copyWith(
                                            color: AppColors.textWhite,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Main title
                                Flexible(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      AppStrings.forgotPasswordTitle,
                                      style: AppTextStyles.heading1(context).copyWith(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(height: titleSpacing),
                                // Subtitle
                                Flexible(
                                  flex: 1,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                      child: Text(
                                        AppStrings.pleaseResetPassword,
                                        style: AppTextStyles.bodyMedium(context).copyWith(
                                          color: AppColors.textWhite,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: topSpacing),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    // White Content Section
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.064, // ~6.4% of screen width
                          vertical: screenHeight * 0.04, // 4% of screen height
                        ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: responsiveSpacing(20)),
                                // Email field
                                _buildEmailField(),
                                SizedBox(height: responsiveSpacing(32)),
                                // Send button
                                BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                                  builder: (context, state) {
                                    return AppButton(
                                      label: AppStrings.send,
                                      onPressed: _handleSubmit,
                                      isPrimary: true,
                                      isLoading: state is ForgotPasswordLoading,
                                      width: double.infinity,
                                      backgroundColor: AppColors.loginHeaderTeal,
                                    );
                                  },
                                ),
                                SizedBox(height: responsiveSpacing(32)),
                              ],
                            ),
                          ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildEmailField() {
    return AppTextField(
      label: AppStrings.email,
      controller: _emailController,
      hint: AppStrings.enterYourEmail,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterEmail;
        }
        // Basic email validation
        if (!value.contains('@') || !value.contains('.')) {
          return AppStrings.pleaseEnterValidEmail;
        }
        return null;
      },
    );
  }
}

