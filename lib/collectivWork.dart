import 'package:flutter/material.dart';
import 'core/presentation/pages/splash_page.dart';
import 'core/presentation/pages/app_loading_screen.dart';
import 'core/presentation/pages/app_error_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';

// Authentication - Simplified structure
import 'core/network/api_service.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/utils/app_navigator.dart';
import 'core/utils/token_storage.dart';
import 'features/authentication/data/repository/auth_repository.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/user/data/datasources/user_profile_remote_datasource.dart';
import 'features/user/data/repositories/user_profile_repository_impl.dart';
import 'features/user/domain/usecases/get_user_profile_usecase.dart';
import 'features/user/presentation/bloc/user_profile_bloc.dart';
import 'package:dio/dio.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CollectivWorkApp extends StatefulWidget {
  const CollectivWorkApp({super.key});

  @override
  State<CollectivWorkApp> createState() => _CollectivWorkAppState();
}

class _CollectivWorkAppState extends State<CollectivWorkApp> {
  bool _isInitialized = false;
  bool _initializationFailed = false;
  String? _errorMessage;
  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize SharedPreferences (async operation)
      _sharedPreferences = await SharedPreferences.getInstance();
      
      // Initialize TokenStorage
      await TokenStorage.init();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Initialization failed: $e');
      setState(() {
        _initializationFailed = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Build CollectivWorkApp');

    // Create simplified dependencies with proper network handling
    final connectivity = Connectivity();
    final networkInfo = NetworkInfoImpl(connectivity);
    
    // Create ApiService with token expiration callback
    final apiService = ApiService(
      networkInfo: networkInfo,
      onTokenExpired: () {
        // Clear navigation stack and navigate to login
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
    
    // Create ApiClient for profile API
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    
    // Create user profile dependencies
    final userProfileRemoteDataSource = UserProfileRemoteDataSourceImpl(apiClient);
    final userProfileRepository = UserProfileRepositoryImpl(
      remoteDataSource: userProfileRemoteDataSource,
      networkInfo: networkInfo,
    );
    final getUserProfileUseCase = GetUserProfileUseCase(userProfileRepository);
    
    // Create UserProfileBloc first
    final userProfileBloc = UserProfileBloc(
      getUserProfileUseCase: getUserProfileUseCase,
    );
    
    final authRepository = AuthRepository(apiService);
    final authBloc = AuthBloc(
      authRepository: authRepository,
      getUserProfileUseCase: getUserProfileUseCase,
      userProfileBloc: userProfileBloc,
    );

    final materialApp = MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme, // Disabled for now
      themeMode: ThemeMode.light, // Force light mode only
      home: _isInitialized
          ? const SplashPage()
          : (_initializationFailed
          ? AppErrorScreen(
        errorMessage: _errorMessage,
        onRetry: () {
          setState(() {
            _initializationFailed = false;
            _isInitialized = false;
            _errorMessage = null;
            _sharedPreferences = null;
          });
          _initializeApp();
        },
      )
          : const AppLoadingScreen()),
    );

    // Wrap with MultiBlocProvider
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => authBloc),
        BlocProvider(create: (_) => userProfileBloc),
      ],
      child: materialApp,
    );
  }
}