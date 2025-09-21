import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Load default address from shared preferences
  Future<Map<String, dynamic>> loadDefaultAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultAddress = prefs.getString('defaultAddress');
      final defaultLat = prefs.getDouble('defaultLat');
      final defaultLng = prefs.getDouble('defaultLng');
      
      return {
        'address': defaultAddress,
        'lat': defaultLat,
        'lng': defaultLng,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Save address as default
  Future<void> setDefaultAddress(String address, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('defaultAddress', address);
      await prefs.setDouble('defaultLat', lat);
      await prefs.setDouble('defaultLng', lng);
    } catch (e) {
      rethrow;
    }
  }

  // Get current location
  Future<LatLng> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      rethrow;
    }
  }

  // Get address from latitude and longitude
  Future<String> getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.postalCode ?? ''}';
      }
      
      return 'Unknown location';
    } catch (e) {
      rethrow;
    }
  }
}