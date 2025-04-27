import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/cycling_activity.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/rewards_service.dart';

class CyclingSessionService {
  // Services
  final LocationService _locationService = LocationService();
  final RewardsService _rewardsService = RewardsService();
  
  // Session state
  bool _isSessionActive = false;
  bool get isSessionActive => _isSessionActive;
  
  // Session data
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  DateTime? _startTime;
  List<LatLng> _routePoints = [];
  Map<String, int> _speedZones = {
    'slow': 0,    // 0-10 km/h
    'medium': 0,  // 10-20 km/h
    'fast': 0,    // 20+ km/h
  };
  
  // Getters for session data
  double get totalDistance => _totalDistance;
  int get elapsedSeconds => _elapsedSeconds;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  Map<String, int> get speedZones => Map.unmodifiable(_speedZones);
  
  // Stream controllers
  final _distanceController = StreamController<double>.broadcast();
  final _durationController = StreamController<int>.broadcast();
  final _speedController = StreamController<double>.broadcast();
  final _maxSpeedController = StreamController<double>.broadcast();
  final _routeController = StreamController<List<LatLng>>.broadcast();
  final _speedZonesController = StreamController<Map<String, int>>.broadcast();
  
  // Streams for UI updates
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<int> get durationStream => _durationController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get maxSpeedStream => _maxSpeedController.stream;
  Stream<List<LatLng>> get routeStream => _routeController.stream;
  Stream<Map<String, int>> get speedZonesStream => _speedZonesController.stream;
  
  // Timers and subscriptions
  Timer? _durationTimer;
  StreamSubscription? _locationSubscription;
  LatLng? _lastLocation;
  DateTime? _lastLocationTime;
  
  // Start a new cycling session
  Future<bool> startSession() async {
    if (_isSessionActive) return true; // Already started
    
    try {
      // Reset session data
      _totalDistance = 0.0;
      _elapsedSeconds = 0;
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _routePoints = [];
      _speedZones = {'slow': 0, 'medium': 0, 'fast': 0};
      _startTime = DateTime.now();
      _lastLocation = null;
      _lastLocationTime = null;
      
      // Start location updates
      final locationStarted = await _locationService.startLocationUpdates();
      if (!locationStarted) {
        debugPrint('Failed to start location updates');
        return false;
      }
      
      // Start tracking duration
      _durationTimer = Timer.periodic(const Duration(seconds: 1), _updateDuration);
      
      // Start tracking location
      _locationSubscription = _locationService.locationStream?.listen(
        _handleLocationUpdate,
        onError: (error) {
          debugPrint('Location error in cycling session: $error');
        },
      );
      
      if (_locationSubscription == null) {
        debugPrint('Failed to subscribe to location updates');
        _durationTimer?.cancel();
        return false;
      }
      
      _isSessionActive = true;
      return true;
    } catch (e) {
      debugPrint('Error starting cycling session: $e');
      // Clean up any resources that might have been initialized
      _durationTimer?.cancel();
      _locationSubscription?.cancel();
      _locationService.stopLocationUpdates();
      return false;
    }
  }
  
  // End the current session and save activity
  Future<CyclingActivity?> endSession(User user) async {
    if (!_isSessionActive) return null;
    
    try {
      // Stop timers and subscriptions safely
      _durationTimer?.cancel();
      _durationTimer = null;
      
      // Cancel location subscription first
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      
      // Now we can stop location updates
      _locationService.stopLocationUpdates();
      
      // Create a new activity with the session data
      final points = _rewardsService.calculatePoints(_totalDistance);
      
      final activity = await _rewardsService.addCyclingActivity(
        user.id,
        _totalDistance,
        points,
      );
      
      _isSessionActive = false;
      
      // Clean up data but keep the last values for display
      _startTime = null;
      _routePoints = [];
      
      return activity;
    } catch (e) {
      debugPrint('Error ending cycling session: $e');
      return null;
    }
  }
  
  // Cancel the session without saving
  void cancelSession() {
    _durationTimer?.cancel();
    _durationTimer = null;
    
    // Cancel location subscription first before stopping the service
    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    // Then stop location updates
    _locationService.stopLocationUpdates();
    
    _isSessionActive = false;
    _startTime = null;
    _routePoints = [];
  }
  
  // Format duration into HH:MM:SS
  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
  
  // Private method to update duration
  void _updateDuration(Timer timer) {
    if (!_isSessionActive) return;
    
    _elapsedSeconds++;
    _durationController.add(_elapsedSeconds);
  }
  
  // Private method to handle location updates
  void _handleLocationUpdate(LatLng location) {
    if (!_isSessionActive) return;
    
    debugPrint('Received location update: ${location.latitude}, ${location.longitude}'); // Added debug print
    
    // Add the point to the route
    _routePoints.add(location);
    _routeController.add(_routePoints);
    
    // Calculate distance if we have a previous location
    if (_lastLocation != null) {
      final Distance distance = const Distance();
      final double segmentDistance = distance.as(
        LengthUnit.Kilometer,
        _lastLocation!,
        location,
      );
      
      debugPrint('Calculated segment distance: $segmentDistance km'); // Added debug print
      
      _totalDistance += segmentDistance;
      _distanceController.add(_totalDistance);
      
      // Calculate speed if we have a previous timestamp
      if (_lastLocationTime != null) {
        final double timeDeltaMillis = DateTime.now().difference(_lastLocationTime!).inMilliseconds.toDouble();
        final double timeDeltaHours = timeDeltaMillis / 3600000.0;
        
        debugPrint('Time delta: $timeDeltaMillis ms ($timeDeltaHours hours)'); // Added debug print
        
        if (timeDeltaHours > 0) {
          _currentSpeed = segmentDistance / timeDeltaHours;
          debugPrint('Calculated current speed: $_currentSpeed km/h'); // Added debug print
          _speedController.add(_currentSpeed);
          
          // Update max speed
          if (_currentSpeed > _maxSpeed) {
            _maxSpeed = _currentSpeed;
            _maxSpeedController.add(_maxSpeed);
          }
          
          // Update speed zones
          String zone;
          if (_currentSpeed < 10) {
            zone = 'slow';
          } else if (_currentSpeed < 20) {
            zone = 'medium';
          } else {
            zone = 'fast';
          }
          
          _speedZones[zone] = (_speedZones[zone] ?? 0) + 1;
          _speedZonesController.add(_speedZones);
        } else {
          debugPrint('Time delta is zero or negative, cannot calculate speed.'); // Added debug print
        }
      } else {
         debugPrint('Last location time is null, cannot calculate speed yet.'); // Added debug print
      }
    } else {
       debugPrint('First location update, cannot calculate distance/speed yet.'); // Added debug print
    }
    
    // Update previous location and time
    _lastLocation = location;
    _lastLocationTime = DateTime.now();
  }
  
  // Clean up resources when the service is no longer needed
  void dispose() {
    // Cancel any active session first
    if (_isSessionActive) {
      cancelSession();
    }
    
    // Clean up controllers
    _distanceController.close();
    _durationController.close();
    _speedController.close();
    _maxSpeedController.close();
    _routeController.close();
    _speedZonesController.close();
  }
}
