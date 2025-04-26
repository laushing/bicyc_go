import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Singleton pattern to ensure only one instance exists
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() => _instance;
  
  LocationService._internal();
  
  // Stream controllers
  StreamController<LatLng>? _locationStreamController;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Public stream for location updates
  Stream<LatLng>? get locationStream => _locationStreamController?.stream;
  
  // Current location
  LatLng? _currentLocation;
  LatLng? get currentLocation => _currentLocation;
  
  // Service status
  bool _isActive = false;
  bool get isActive => _isActive;
  
  // Start location updates
  Future<bool> startLocationUpdates() async {
    if (_isActive) return true; // Already running
    
    try {
      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return false;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }
      
      // Initialize the stream controller if it's null or closed
      if (_locationStreamController == null || _locationStreamController!.isClosed) {
        _locationStreamController = StreamController<LatLng>.broadcast();
      }
      
      // Start listening to position updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          // Only emit updates if the controller is still active
          if (_locationStreamController != null && !_locationStreamController!.isClosed) {
            final location = LatLng(position.latitude, position.longitude);
            _currentLocation = location;
            _locationStreamController!.add(location);
          }
        },
        onError: (error) {
          debugPrint('Error getting location: $error');
          // Don't close the stream on error, just log it
        },
      );
      
      _isActive = true;
      return true;
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      return false;
    }
  }
  
  // Stop location updates properly
  void stopLocationUpdates() {
    _isActive = false;
    
    // Cancel the position subscription first
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    // Then close the stream controller
    if (_locationStreamController != null && !_locationStreamController!.isClosed) {
      _locationStreamController!.close();
      _locationStreamController = null;
    }
  }
  
  // Get current location once
  Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      return _currentLocation;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
  
  // Safe disposal method to be called when app is shutting down
  void dispose() {
    stopLocationUpdates();
  }
}
