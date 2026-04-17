import 'package:collectivWork/core/utils/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final FocusNode _usernameFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  List<SavedLoginAccount> _savedAccounts = const [];
  bool _showSavedAccounts = false;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_handleUsernameFocusChange);
    _loadSavedCredentials();
  }

  /// Load saved credentials if remember me was enabled
  Future<void> _loadSavedCredentials() async {
    try {
      await CredentialsStorage.init();
      final savedAccounts = CredentialsStorage.getSavedAccounts();
      final mostRecent = CredentialsStorage.getMostRecentAccount();

      if (!mounted) return;

      setState(() {
        _savedAccounts = savedAccounts;
        if (mostRecent != null) {
          _usernameController.text = mostRecent.username;
          _passwordController.text = mostRecent.password;
          _rememberMe = true;
        }
      });
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  void _handleUsernameFocusChange() {
    if (!mounted) return;
    setState(() {
      _showSavedAccounts =
          _usernameFocusNode.hasFocus && _savedAccounts.isNotEmpty;
    });
  }

  List<SavedLoginAccount> get _filteredSavedAccounts {
    final query = _usernameController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _savedAccounts;
    }

    return _savedAccounts
        .where((account) => account.username.toLowerCase().contains(query))
        .toList();
  }

  void _selectSavedAccount(SavedLoginAccount account) {
    setState(() {
      _usernameController.text = account.username;
      _passwordController.text = account.password;
      _rememberMe = true;
      _showSavedAccounts = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _hideSavedAccounts() {
    if (!_showSavedAccounts) return;
    setState(() {
      _showSavedAccounts = false;
    });
  }

  Future<void> _removeSavedAccount(SavedLoginAccount account) async {
    await CredentialsStorage.removeAccount(account.username);
    await _loadSavedCredentials();

    if (!mounted) return;
    final currentUsername = _usernameController.text.trim().toLowerCase();
    if (currentUsername == account.username.toLowerCase()) {
      setState(() {
        _usernameController.clear();
        _passwordController.clear();
        _rememberMe = false;
      });
    } else {
      setState(() {
        _showSavedAccounts =
            _usernameFocusNode.hasFocus && _filteredSavedAccounts.isNotEmpty;
      });
    }
  }
  @override
  void dispose() {
    _usernameFocusNode.removeListener(_handleUsernameFocusChange);
    _usernameFocusNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    _hideSavedAccounts();
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        _hideSavedAccounts();
      },
      child: Scaffold(
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      // Teal Header Section with curved bottom
                      Container(
                        height: headerHeight,
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
                            // 6% of screen width
                            vertical:
                                screenHeight * 0.02, // 2% of screen height
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
                                      style: AppTextStyles.heading1(
                                        context,
                                      ).copyWith(
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
                                        style: AppTextStyles.bodyMedium(
                                          context,
                                        ).copyWith(color: AppColors.textWhite),
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
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.064,
                          // ~6.4% of screen width
                          vertical: screenHeight * 0.04,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: responsiveSpacing(20)),
                              // Username field (Email or Mobile)
                              _buildUsernameField(context),
                              SizedBox(height: responsiveSpacing(20)),
                              // Password field
                              _buildPasswordField(),
                              SizedBox(height: responsiveSpacing(16)),
                              // Remember me and Forgot password row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Remember me checkbox
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: AppSpacing.iconSmallHeight,
                                          width:  AppSpacing.iconSmallHeight,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor:
                                                AppColors.loginHeaderTeal,
                                          ),
                                        ),
                                        AppSpacing.hXs,
                                        Flexible(
                                          child: Text(
                                            AppStrings.rememberMe,
                                            style: AppTextStyles.bodyMediumHeading(
                                              context,
                                            ),
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
                                            builder:
                                                (_) => BlocProvider(
                                                  create:
                                                      (_) => ForgotPasswordBloc(
                                                        authRepository:
                                                            context
                                                                .read<
                                                                  AuthRepository
                                                                >(),
                                                      ),
                                                  child:
                                                      const ForgotPasswordPage(),
                                                ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        AppStrings.forgotPassword,
                                        style: AppTextStyles.bodyMediumHeading(
                                          context,
                                        ).copyWith(
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(BuildContext ctx) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: AppStrings.registeredemail,
          controller: _usernameController,
          hint: AppStrings.enterEmailOrMobile,
          keyboardType: TextInputType.text,
          focusNode: _usernameFocusNode,
          onTap: () {
            if (_savedAccounts.isEmpty) return;
            setState(() {
              _showSavedAccounts = true;
            });
          },
          onChanged: (_) {
            if (!_usernameFocusNode.hasFocus) return;
            setState(() {
              _showSavedAccounts = _filteredSavedAccounts.isNotEmpty;
            });
          },
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
        ),
        if (_showSavedAccounts && _filteredSavedAccounts.isNotEmpty) ...[
          // const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenWidth * 0.004,
                horizontal: screenHeight * 0.004,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredSavedAccounts.length,
                      separatorBuilder:
                          (_, __) => SizedBox(height: screenHeight * 0.008),
                      itemBuilder: (context, index) {
                        final account = _filteredSavedAccounts[index];
                        final initials =
                            account.username.isNotEmpty
                                ? account.username[0].toUpperCase()
                                : 'U';
                        return InkWell(
                          // borderRadius: BorderRadius.circular(18),
                          onTap: () => _selectSavedAccount(account),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * .004,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: screenWidth * 0.08,
                                  height: screenHeight * 0.08,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF22C1C3),
                                        Color(0xFF0B7F7F),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: AppTextStyles.bodyMedium(
                                        context,
                                      ).copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.username,
                                        style: AppTextStyles.bodySmall(
                                          context,
                                        ).copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: screenHeight * 0.002),
                                      Text(
                                        _maskPassword(account.password),
                                        style: AppTextStyles.bodySmall(
                                          context,
                                        ).copyWith(
                                          color: AppColors.textSecondary,
                                          letterSpacing: 1.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        () => _removeSavedAccount(account),
                                    icon: const Icon(Icons.close, size: 16),
                                    padding: EdgeInsets.zero,
                                    color: AppColors.textSecondary,
                                    tooltip: 'Remove',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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

  String _maskPassword(String password) {
    if (password.isEmpty) return '';
    if (password.length <= 3) return '*' * password.length;
    return '${'*' * (password.length - 2)}${password.substring(password.length - 2)}';
  }
}
