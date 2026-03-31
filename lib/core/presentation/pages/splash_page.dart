import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../../features/authentication/presentation/bloc/auth_bloc/auth_bloc.dart';
import '../../../features/authentication/presentation/bloc/auth_bloc/auth_event.dart';
import '../../../features/authentication/presentation/bloc/auth_bloc/auth_state.dart';
import '../../../features/authentication/presentation/pages/login_page.dart';
import '../../../features/home/presentation/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _iconSlideAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _textFadeAnimation;

  AuthState? _resolvedAuthState;
  bool _isAnimationComplete = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _iconSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.8),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    _iconScaleAnimation =
        Tween<double>(begin: 0.78, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.08, 0.5, curve: Curves.easeOutBack),
          ),
        );

    _iconFadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
          ),
        );

    _textSlideAnimation =
        Tween<Offset>(
          begin: const Offset(-0.18, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.48, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _textFadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.48, 0.8, curve: Curves.easeOut),
          ),
        );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationComplete = true;
        _tryNavigate();
      }
    });

    _controller.forward();
    context.read<AuthBloc>().add(const AuthStatusChecked());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (!mounted ||
        _hasNavigated ||
        !_isAnimationComplete ||
        _resolvedAuthState == null) {
      return;
    }

    _hasNavigated = true;

    if (_resolvedAuthState is AuthAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          _resolvedAuthState = state;
          _tryNavigate();
        } else if (state is AuthError) {
          _resolvedAuthState = const AuthUnauthenticated();
          _tryNavigate();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.splashbackgroundLight, Color(0xFFFFFFFF)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _iconFadeAnimation,
                      child: SlideTransition(
                        position: _iconSlideAnimation,
                        child: ScaleTransition(
                          scale: _iconScaleAnimation,
                          child: Image.asset(
                            AppAssets.splashIcon,
                            width: screenWidth * 0.18,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Collectiv\n',
                                style: TextStyle(
                                  color: AppColors.textHeading,
                                  fontSize: screenWidth * 0.082,
                                  fontWeight: FontWeight.w800,
                                  height: 0.96,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              TextSpan(
                                text: 'Work',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: screenWidth * 0.082,
                                  fontWeight: FontWeight.w800,
                                  height: 0.96,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}