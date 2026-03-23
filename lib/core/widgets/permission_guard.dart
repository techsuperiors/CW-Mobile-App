import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/user/presentation/bloc/user_profile_bloc.dart';
import '../../features/user/presentation/bloc/user_profile_state.dart';

/// A wrapper widget that conditionally renders its child based on the presence
/// of a specific string permission in the `UserProfile`'s `RoleInfo`.
class PermissionGuard extends StatelessWidget {
  /// A single exact permission string required.
  final String? requiredPermission;

  /// A list of permissions. The user will see the widget if they have AT LEAST ONE of these.
  final List<String>? anyOf;

  /// A list of permissions. The user will see the widget only if they have ALL of these.
  final List<String>? allOf;

  /// The widget rendered if the user HAS the required access.
  final Widget child;

  /// The widget rendered if the user DOES NOT have the access.
  /// Defaults to a completely invisible `SizedBox.shrink()` (hides the element).
  final Widget? fallback;

  const PermissionGuard({
    Key? key,
    this.requiredPermission,
    this.anyOf,
    this.allOf,
    required this.child,
    this.fallback,
  }) : assert(
         requiredPermission != null || anyOf != null || allOf != null,
         'You must provide at least one permission requirement criteria.',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      // Specify `buildWhen` to prevent unnecessary re-renders when nothing related to the profile changes.
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        if (state is UserProfileLoaded) {
          final permissions = state.profile.role?.permissions ?? [];

          // Logically, users with a role 'Complete Access Role' might
          // optionally have bypass logic here if you want:
          // if (state.profile.role?.roleName == 'Complete Access Role') return child;

          bool hasAccess = false;

          if (requiredPermission != null) {
            hasAccess = permissions.contains(requiredPermission);
          } else if (anyOf != null) {
            hasAccess = anyOf!.any(
              (permission) => permissions.contains(permission),
            );
          } else if (allOf != null) {
            hasAccess = allOf!.every(
              (permission) => permissions.contains(permission),
            );
          }

          if (hasAccess) {
            return child;
          }
        }

        // Return the fallback if permission is missing, or while loading.
        // E.g., returning nothing (SizedBox.shrink) so buttons are completely completely hidden.
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
