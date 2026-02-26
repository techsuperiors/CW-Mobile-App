import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_text_field.dart';
import '../../../../core/widgets/common/app_button.dart';
import '../../../../core/error/exceptions.dart';
import '../../data/repository/auth_repository.dart';

/// Change password page for logged-in users
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authRepository = context.read<AuthRepository>();
        await authRepository.changePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.passwordChangeSuccessMessage),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } on ServerException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } on NetworkException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.serverError),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    double responsiveSpacing(double baseSpacing) {
      if (screenHeight < 600) return baseSpacing * 0.75;
      if (screenHeight < 700) return baseSpacing * 0.85;
      return baseSpacing;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.loginHeaderTeal,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        title: Text(
          AppStrings.changePassword,
          style: AppTextStyles.heading3(context).copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.064,
          vertical: screenHeight * 0.04,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsiveSpacing(20)),
              _buildOldPasswordField(),
              SizedBox(height: responsiveSpacing(20)),
              _buildNewPasswordField(),
              SizedBox(height: responsiveSpacing(20)),
              _buildConfirmPasswordField(),
              SizedBox(height: responsiveSpacing(32)),
              AppButton(
                label: AppStrings.save,
                onPressed: _handleSave,
                isPrimary: true,
                isLoading: _isLoading,
                width: double.infinity,
                backgroundColor: AppColors.loginHeaderTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOldPasswordField() {
    return AppTextField(
      label: AppStrings.currentPassword,
      controller: _oldPasswordController,
      hint: AppStrings.enterCurrentPassword,
      obscureText: _obscureOldPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() => _obscureOldPassword = !_obscureOldPassword);
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterCurrentPassword;
        }
        return null;
      },
    );
  }

  Widget _buildNewPasswordField() {
    return AppTextField(
      label: AppStrings.password,
      controller: _newPasswordController,
      hint: AppStrings.enterPassword,
      obscureText: _obscureNewPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() => _obscureNewPassword = !_obscureNewPassword);
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterPassword;
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return AppTextField(
      label: AppStrings.confirmPassword,
      controller: _confirmPasswordController,
      hint: AppStrings.enterConfirmPassword,
      obscureText: _obscureConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterConfirmPassword;
        }
        if (value != _newPasswordController.text) {
          return AppStrings.passwordsDoNotMatch;
        }
        return null;
      },
    );
  }
}
