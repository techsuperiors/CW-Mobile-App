import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

/// User Profile states
abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserProfileInitial extends UserProfileState {
  const UserProfileInitial();
}

/// Loading state
class UserProfileLoading extends UserProfileState {
  const UserProfileLoading();
}

/// Loaded state
class UserProfileLoaded extends UserProfileState {
  final UserProfile profile;

  const UserProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Error state
class UserProfileError extends UserProfileState {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

