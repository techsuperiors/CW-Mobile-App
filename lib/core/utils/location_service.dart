import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates (reverse geocoding)
      String address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get current location: ${e.toString()}');
    }
  }

  /// Get address from coordinates using reverse geocoding
  Future<String> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Unknown Location';
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

      return addressParts.join(', ');
    } catch (e) {
      // If reverse geocoding fails, return a basic address
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }
}
