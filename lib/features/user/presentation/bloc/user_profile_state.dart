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
  final bool isStale;
  final bool isRefreshing;
  final String? warningMessage;

  const UserProfileLoaded(
    this.profile, {
    this.isStale = false,
    this.isRefreshing = false,
    this.warningMessage,
  });

  UserProfileLoaded copyWith({
    UserProfile? profile,
    bool? isStale,
    bool? isRefreshing,
    String? warningMessage,
  }) {
    return UserProfileLoaded(
      profile ?? this.profile,
      isStale: isStale ?? this.isStale,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      warningMessage: warningMessage,
    );
  }

  @override
  List<Object?> get props => [profile, isStale, isRefreshing, warningMessage];
}

/// Recovery state when profile cannot be loaded and no cache is available.
class UserProfileRecoveryRequired extends UserProfileState {
  final String message;

  const UserProfileRecoveryRequired(this.message);

  @override
  List<Object?> get props => [message];
}
