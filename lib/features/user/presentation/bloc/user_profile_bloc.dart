import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/clear_cached_user_profile_usecase.dart';
import '../../domain/usecases/get_cached_user_profile_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

/// User Profile BLoC
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final GetCachedUserProfileUseCase getCachedUserProfileUseCase;
  final ClearCachedUserProfileUseCase clearCachedUserProfileUseCase;
  UserProfile? _lastKnownProfile;

  UserProfile? get lastKnownProfile => _lastKnownProfile;

  UserProfileBloc({
    required this.getUserProfileUseCase,
    required this.getCachedUserProfileUseCase,
    required this.clearCachedUserProfileUseCase,
  }) : super(const UserProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<SetUserProfile>(_onSetUserProfile);
    on<ClearUserProfile>(_onClearUserProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    if (!event.forceRefresh) {
      if (state is UserProfileLoading) {
        return;
      }

      if (state is UserProfileLoaded) {
        final loadedState = state as UserProfileLoaded;
        if (!loadedState.isStale && !loadedState.isRefreshing) {
          return;
        }
      }
    }

    UserProfileLoaded? loadedState;
    if (state is UserProfileLoaded) {
      loadedState = state as UserProfileLoaded;
      emit(loadedState.copyWith(isRefreshing: true, warningMessage: null));
    }

    final cachedResult = await getCachedUserProfileUseCase();
    final cachedProfile = cachedResult.fold((_) => null, (profile) => profile);

    if (loadedState == null) {
      if (cachedProfile != null) {
        _lastKnownProfile = cachedProfile;
        emit(
          UserProfileLoaded(cachedProfile, isStale: true, isRefreshing: true),
        );
      } else {
        emit(const UserProfileLoading());
      }
    }

    final result = await getUserProfileUseCase();

    result.fold(
      (failure) {
        final fallbackProfile = loadedState?.profile ?? cachedProfile;
        if (fallbackProfile != null) {
          _lastKnownProfile = fallbackProfile;
          emit(
            UserProfileLoaded(
              fallbackProfile,
              isStale: true,
              isRefreshing: false,
              warningMessage: _messageForFailure(failure),
            ),
          );
          return;
        }

        emit(UserProfileRecoveryRequired(_messageForFailure(failure)));
      },
      (profile) {
        _lastKnownProfile = profile;
        emit(UserProfileLoaded(profile, isStale: false, isRefreshing: false));
      },
    );
  }

  Future<void> _onSetUserProfile(
    SetUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    _lastKnownProfile = event.profile;
    emit(UserProfileLoaded(event.profile, isStale: false, isRefreshing: false));
  }

  Future<void> _onClearUserProfile(
    ClearUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    await clearCachedUserProfileUseCase();
    _lastKnownProfile = null;
    emit(const UserProfileInitial());
  }

  String _messageForFailure(Failure failure) {
    return failure.message;
  }
}
