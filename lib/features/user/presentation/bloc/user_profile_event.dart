import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

/// User Profile events
abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load user profile event
class LoadUserProfile extends UserProfileEvent {
  final bool forceRefresh;

  const LoadUserProfile({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Set user profile event (when profile is received from API)
class SetUserProfile extends UserProfileEvent {
  final UserProfile profile;

  const SetUserProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Clear user profile event
class ClearUserProfile extends UserProfileEvent {
  const ClearUserProfile();
}
