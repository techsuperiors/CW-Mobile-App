import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final bool hasResolvedAddress;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.hasResolvedAddress,
  });
}

/// Service for handling location operations
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    // First check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check permission status
    LocationPermission permission = await checkLocationPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Please grant location permission.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
    }

    return permission;
  }

  /// Get current location with address
  Future<LocationData> getCurrentLocation() async {
    try {
      // Request permission first
      await requestLocationPermission();

      // Get current position. If the fresh lookup times out, fall back to the
      // last known position so we can still preserve the punch event.
      final position = await _getBestAvailablePosition();

      final resolvedAddress = await tryGetAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final address =
          resolvedAddress ??
          buildCoordinateFallback(position.latitude, position.longitude);

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        hasResolvedAddress: resolvedAddress != null,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get current location: ${e.toString()}');
    }
  }

  Future<Position> _getBestAvailablePosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }
      rethrow;
    }
  }

  /// Get address from coordinates using reverse geocoding
  Future<String?> tryGetAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      Placemark place = placemarks[0];
      
      // Build address string
      List<String> addressParts = [];
      
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
        addressParts.add(place.subAdministrativeArea!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }
      if (place.postalCode != null && place.postalCode!.isNotEmpty) {
        addressParts.add(place.postalCode!);
      }

      final address = addressParts.join(', ').trim();
      return address.isEmpty ? null : address;
    } catch (e) {
      return null;
    }
  }

  String buildCoordinateFallback(double latitude, double longitude) {
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }
}
