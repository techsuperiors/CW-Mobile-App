import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

class LocationPermissionHelper {
  LocationPermissionHelper._();

  static const String _locationDeniedCountKey = 'location_permission_denied_count';

  static Future<bool> ensureLocationAccess(
    BuildContext context, {
    required String actionLabel,
  }) async {
    final locationService = LocationService();

    final serviceEnabled = await locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      final openSettings = await _showLocationServicesDialog(
        context,
        actionLabel: actionLabel,
      );
      if (openSettings == true) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    var permission = await locationService.checkLocationPermission();

    if (permission == LocationPermission.denied) {
      final deniedCount = await _getDeniedCount();

      if (deniedCount >= 2) {
        if (!context.mounted) return false;
        final openSettings = await _showPermissionSettingsDialog(
          context,
          actionLabel: actionLabel,
        );
        if (openSettings == true) {
          await openAppSettings();
        }
        return false;
      }

      try {
        permission = await locationService.requestLocationPermission();
      } catch (_) {
        permission = await locationService.checkLocationPermission();
      }

      if (permission == LocationPermission.denied) {
        await _incrementDeniedCount();
        if (context.mounted) {
          _showInfoSnackBar(
            context,
            'Location permission is required to $actionLabel.',
          );
        }
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        await _incrementDeniedCount();
        if (!context.mounted) return false;
        final openSettings = await _showPermissionSettingsDialog(
          context,
          actionLabel: actionLabel,
        );
        if (openSettings == true) {
          await openAppSettings();
        }
        return false;
      }

      await _resetDeniedCount();
    }

    if (permission == LocationPermission.deniedForever) {
      await _incrementDeniedCount();
      if (!context.mounted) return false;
      final openSettings = await _showPermissionSettingsDialog(
        context,
        actionLabel: actionLabel,
      );
      if (openSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    await _resetDeniedCount();
    return true;
  }

  static Future<bool?> _showPermissionSettingsDialog(
    BuildContext context, {
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location Permission Needed'),
          content: Text(
            'Location permission is permanently denied. Please enable it from app settings to $actionLabel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> _showLocationServicesDialog(
    BuildContext context, {
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Turn On Location'),
          content: Text(
            'Location services are off. Please turn them on to $actionLabel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  static Future<int> _getDeniedCount() async {
    final prefs = await _prefs();
    return prefs.getInt(_locationDeniedCountKey) ?? 0;
  }

  static Future<void> _incrementDeniedCount() async {
    final prefs = await _prefs();
    final current = prefs.getInt(_locationDeniedCountKey) ?? 0;
    await prefs.setInt(_locationDeniedCountKey, current + 1);
  }

  static Future<void> _resetDeniedCount() async {
    final prefs = await _prefs();
    await prefs.remove(_locationDeniedCountKey);
  }
}
