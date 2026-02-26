import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/credentials_storage.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_text_field.dart';
import '../../../../core/widgets/common/app_button.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../bloc/auth_bloc/auth_bloc.dart';
import '../bloc/auth_bloc/auth_event.dart';
import '../bloc/auth_bloc/auth_state.dart';
import '../../data/repository/auth_repository.dart';
import '../bloc/forgot_password/forgot_password_bloc.dart';
import 'forgot_password_page.dart';

/// Login page matching CollectivWork design
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Load saved credentials if remember me was enabled
  Future<void> _loadSavedCredentials() async {
    try {
      await CredentialsStorage.init();
      if (CredentialsStorage.isRememberMeEnabled()) {
        final savedUsername = CredentialsStorage.getSavedEmail();
        final savedPassword = CredentialsStorage.getSavedPassword();
        
        if (savedUsername != null && savedPassword != null) {
          setState(() {
            _usernameController.text = savedUsername;
            _passwordController.text = savedPassword;
            _rememberMe = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        ),
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
      headerHeightRatio = 0.30; // Reduce header on very small screens
    } else if (screenHeight > 800) {
      headerHeightRatio = 0.38; // Slightly increase on larger screens
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
    
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Navigate to dashboard (HomePage)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          } else if (state is AuthError) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: LayoutBuilder(
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
                            horizontal: screenWidth * 0.06, // 6% of screen width
                            vertical: screenHeight * 0.02, // 2% of screen height
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate responsive spacing based on available height
                              final availableHeight = constraints.maxHeight;
                              final topSpacing = availableHeight * 0.05;
                              final logoSpacing = availableHeight * 0.08;
                              final titleSpacing = availableHeight * 0.03;
                              
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: topSpacing),
                                  // Logo - responsive size
                                  Flexible(
                                    flex: 2,
                                    child: Center(
                                      child: AppLogo(
                                        width: screenWidth * 0.5,
                                        height: screenWidth * 0.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: logoSpacing),
                                  // Title
                                  Flexible(
                                    flex: 1,
                                    child: Text(
                                      AppStrings.logIn,
                                      style: AppTextStyles.heading1(context).copyWith(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: titleSpacing),
                                  // Subtitle
                                  Flexible(
                                    flex: 1,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.05,
                                      ),
                                      child: Text(
                                        AppStrings.pleaseLoginToAccess,
                                        style: AppTextStyles.bodyMedium(context).copyWith(
                                          color: AppColors.textWhite,
                                        ),
                                        textAlign: TextAlign.center,
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
                                // Username field (Email or Mobile)
                                _buildUsernameField(),
                                SizedBox(height: responsiveSpacing(20)),
                                // Password field
                                _buildPasswordField(),
                                SizedBox(height: responsiveSpacing(16)),
                                // Remember me and Forgot password row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Remember me checkbox
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: AppColors.loginHeaderTeal,
                                          ),
                                          Flexible(
                                            child: Text(
                                              AppStrings.rememberMe,
                                              style: AppTextStyles.bodyMedium(context),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Forgot password link
                                    Flexible(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BlocProvider(
                                                create: (_) => ForgotPasswordBloc(
                                                  authRepository: context.read<AuthRepository>(),
                                                ),
                                                child: const ForgotPasswordPage(),
                                              ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          AppStrings.forgotPassword,
                                          style: AppTextStyles.bodyMedium(context).copyWith(
                                            color: AppColors.loginHeaderTeal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsiveSpacing(32)),
                                // Login button
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    return AppButton(
                                      label: AppStrings.login,
                                      onPressed: _handleLogin,
                                      isPrimary: true,
                                      isLoading: state is AuthLoading,
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

  Widget _buildUsernameField() {
    return AppTextField(
      label: AppStrings.emailOrMobile,
      controller: _usernameController,
      hint: AppStrings.enterEmailOrMobile,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterEmailOrMobile;
        }
        
        final trimmedValue = value.trim();
        
        // Check if it's an email (contains @ and .)
        if (trimmedValue.contains('@')) {
          // Validate email format
          if (!trimmedValue.contains('.') || 
              trimmedValue.indexOf('@') == 0 || 
              trimmedValue.indexOf('@') == trimmedValue.length - 1) {
            return AppStrings.pleaseEnterValidEmail;
          }
          return null;
        }
        
        // Check if it's a mobile number (only digits, length 10)
        final isNumeric = RegExp(r'^[0-9]+$').hasMatch(trimmedValue);
        if (isNumeric) {
          if (trimmedValue.length != 10) {
            return AppStrings.pleaseEnterValidMobile;
          }
          return null;
        }
        
        // If neither email nor mobile, accept as username
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AppTextField(
      label: AppStrings.password,
      controller: _passwordController,
      hint: AppStrings.enterPassword,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.pleaseEnterPassword;
        }
        return null;
      },
    );
  }
}
