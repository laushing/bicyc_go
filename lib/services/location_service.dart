import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static LocationService? _instance;
  
  // Singleton pattern
  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }
  
  LocationService._internal();
  
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<Position>.broadcast();
  
  Stream<Position> get locationStream => _locationController.stream;
  bool _isTracking = false;
  bool get isTracking => _isTracking;
  
  // Request location permissions and check availability
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      return false;
    }
    
    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }
    
    return true;
  }
  
  // Start tracking location
  Future<bool> startTracking() async {
    if (_isTracking) return true;
    
    final permissionsGranted = await checkPermissions();
    if (!permissionsGranted) return false;
    
    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // Highest accuracy for speed tracking
          distanceFilter: 5, // Update every 5 meters for more precise speed readings
          timeLimit: Duration(seconds: 2), // Get updates at least every 2 seconds
        ),
      ).listen((Position position) {
        _locationController.add(position);
      });
      
      _isTracking = true;
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }
  
  // Stop tracking
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }
  
  // Get current position once
  Future<Position?> getCurrentPosition() async {
    final permissionsGranted = await checkPermissions();
    if (!permissionsGranted) return null;
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }
  
  // Calculate distance between two positions in kilometers
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    ) / 1000; // Convert meters to kilometers
  }
  
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
