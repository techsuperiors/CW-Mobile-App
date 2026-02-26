import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/error/error_handler.dart';
import '../../../../../core/utils/token_storage.dart';
import '../../../../../core/utils/credentials_storage.dart';
import '../../../../user/domain/usecases/get_user_profile_usecase.dart';
import '../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../user/presentation/bloc/user_profile_event.dart';
import '../../../../user/presentation/bloc/user_profile_state.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Authentication BLoC - Simplified version with better error handling
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final GetUserProfileUseCase? getUserProfileUseCase;
  final UserProfileBloc? userProfileBloc;

  AuthBloc({
    required this.authRepository,
    this.getUserProfileUseCase,
    this.userProfileBloc,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.login(
        event.email,
        event.password,
      );
      
      // Handle remember me functionality
      if (event.rememberMe) {
        await CredentialsStorage.saveCredentials(event.email, event.password);
      } else {
        await CredentialsStorage.clearCredentials();
      }
      
      // Ensure token is saved before fetching profile
      // Token should already be saved in authRepository.login(), but we verify
      // Add a small delay to ensure token is fully persisted
      await Future.delayed(const Duration(milliseconds: 100));
      
      final token = TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Warning: Token not found after login');
      } else {
        debugPrint('Token retrieved successfully, length: ${token.length}');
      }
      
      // Fetch user profile after successful login with auth token
      // The token will be automatically added to the request header by ApiClient
      if (getUserProfileUseCase != null && token != null && token.isNotEmpty) {
        try {
          debugPrint('Fetching user profile with auth token in header...');
          final profileResult = await getUserProfileUseCase!();
          profileResult.fold(
            (failure) {
              // Profile fetch failed, but login was successful
              // Continue with login but log the error
              debugPrint('Failed to fetch user profile: ${failure.message}');
            },
            (profile) {
              // Profile fetched successfully
              // Store the profile in UserProfileBloc
              if (userProfileBloc != null) {
                userProfileBloc!.add(SetUserProfile(profile));
              }
              debugPrint('User profile fetched successfully!');
              debugPrint('Name: ${profile.user.fullName}');
              debugPrint('Email: ${profile.user.email}');
              debugPrint('Employee ID: ${profile.user.employeeID}');
              debugPrint('Designation: ${profile.userDesignation?.designationName ?? 'N/A'}');
              debugPrint('Department: ${profile.userDepartment?.departmentName ?? 'N/A'}');
            },
          );
        } catch (e) {
          // Profile fetch error, but login was successful
          // Continue with login but log the error
          debugPrint('Error fetching user profile: $e');
        }
      } else if (getUserProfileUseCase == null) {
        debugPrint('Warning: GetUserProfileUseCase is not provided');
      } else {
        debugPrint('Warning: Token is empty, cannot fetch user profile');
      }
      
      emit(AuthAuthenticated(user));
    } on AppException catch (e) {
      final failure = ErrorHandler.handleException(e);
      emit(AuthError(failure));
    } catch (e) {
      final failure = ErrorHandler.handleException(e);
      emit(AuthError(failure));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await authRepository.logout();
      if (success) {
        // Clear user profile on logout
        if (userProfileBloc != null) {
          userProfileBloc!.add(const ClearUserProfile());
        }
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthError(const ServerFailure('Logout failed. Please try again.')));
      }
    } on AppException catch (e) {
      final failure = ErrorHandler.handleException(e);
      emit(AuthError(failure));
    } catch (e) {
      final failure = ErrorHandler.handleException(e);
      emit(AuthError(failure));
    }
  }

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Check if token exists
      final hasToken = TokenStorage.hasToken();
      
      if (hasToken) {
        // Token exists, user is authenticated
        // Create minimal user object (token exists but no user data from API)
        final user = UserModel(
          id: 'user',
          email: 'user@example.com',
          name: 'User',
          avatar: null,
          role: null,
          createdAt: null,
        );
        emit(AuthAuthenticated(user));
        
        // Load user profile if available
        if (getUserProfileUseCase != null && userProfileBloc != null) {
          try {
            final profileResult = await getUserProfileUseCase!();
            profileResult.fold(
              (failure) {
                debugPrint('Failed to load user profile on auth check: ${failure.message}');
              },
              (profile) {
                userProfileBloc!.add(SetUserProfile(profile));
                debugPrint('User profile loaded on auth check: ${profile.user.fullName}');
              },
            );
          } catch (e) {
            debugPrint('Error loading user profile on auth check: $e');
          }
        }
      } else {
        // No token, user is not authenticated
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      // On error, assume not authenticated
      emit(const AuthUnauthenticated());
    }
  }
}

