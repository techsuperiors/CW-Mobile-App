import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

/// User Profile BLoC
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;

  UserProfileBloc({
    required this.getUserProfileUseCase,
  }) : super(const UserProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<SetUserProfile>(_onSetUserProfile);
    on<ClearUserProfile>(_onClearUserProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileLoading());
    
    final result = await getUserProfileUseCase();
    
    result.fold(
      (failure) {
        emit(UserProfileError(failure.message));
      },
      (profile) {
        emit(UserProfileLoaded(profile));
      },
    );
  }

  void _onSetUserProfile(
    SetUserProfile event,
    Emitter<UserProfileState> emit,
  ) {
    emit(UserProfileLoaded(event.profile));
  }

  void _onClearUserProfile(
    ClearUserProfile event,
    Emitter<UserProfileState> emit,
  ) {
    emit(const UserProfileInitial());
  }
}

