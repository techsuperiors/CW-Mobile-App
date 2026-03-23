import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/user/presentation/bloc/user_profile_bloc.dart';
import '../../features/user/presentation/bloc/user_profile_state.dart';

/// A utility class for checking permissions imperatively outside the widget tree
/// or inside callbacks/functions where you can't use `PermissionGuard`.
class PermissionChecker {
  /// Checks if the currently loaded user profile has the specified permission(s).
  static bool hasPermission(
    BuildContext context, {
    String? requiredPermission,
    List<String>? anyOf,
    List<String>? allOf,
  }) {
    assert(
      requiredPermission != null || anyOf != null || allOf != null,
      'You must provide at least one permission requirement criteria.',
    );

    // Read the current state of UserProfileBloc synchronously
    final state = context.read<UserProfileBloc>().state;

    if (state is UserProfileLoaded) {
      final permissions = state.profile.role?.permissions ?? [];

      if (requiredPermission != null) {
        return permissions.contains(requiredPermission);
      } else if (anyOf != null) {
        return anyOf.any((permission) => permissions.contains(permission));
      } else if (allOf != null) {
        return allOf.every((permission) => permissions.contains(permission));
      }
    }

    return false;
  }
}
