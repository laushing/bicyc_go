import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'rewards_service.dart';
import '../models/cycling_activity.dart';
import '../models/user_model.dart';

class CyclingSessionService {
  // Singleton pattern
  static final CyclingSessionService _instance = CyclingSessionService._internal();
  factory CyclingSessionService() => _instance;
  CyclingSessionService._internal();
  
  final LocationService _locationService = LocationService();
  final RewardsService _rewardsService = RewardsService();
  
  // Session state
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  double _totalDistance = 0.0;
  int _elapsedSeconds = 0;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  
  // Speed history for smoothing (recent speeds in km/h)
  final Queue<double> _speedHistory = Queue<double>();
  final int _speedHistoryMaxSize = 5; // Number of readings to use for smoothing
  
  // Speed zone analytics (time spent in different speed ranges)
  final Map<String, int> _speedZones = {
    '0-5 km/h': 0,
    '5-10 km/h': 0,
    '10-15 km/h': 0,
    '15-20 km/h': 0,
    '20+ km/h': 0,
  };
  int _lastSpeedZoneUpdate = 0; // Last time speed zones were updated
  
  // Session data controllers
  final _distanceController = StreamController<double>.broadcast();
  final _durationController = StreamController<int>.broadcast();
  final _speedController = StreamController<double>.broadcast();
  final _maxSpeedController = StreamController<double>.broadcast();
  final _speedZonesController = StreamController<Map<String, int>>.broadcast();
  
  // Streams for UI updates
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<int> get durationStream => _durationController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get maxSpeedStream => _maxSpeedController.stream;
  Stream<Map<String, int>> get speedZonesStream => _speedZonesController.stream;
  
  Timer? _durationTimer;
  StreamSubscription<Position>? _locationSubscription;
  
  // Getters for current values
  bool get isSessionActive => _isSessionActive;
  double get totalDistance => _totalDistance;
  int get elapsedSeconds => _elapsedSeconds;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  Map<String, int> get speedZones => Map.unmodifiable(_speedZones);
  String get formattedStartTime => _sessionStartTime != null ? 
      '${_sessionStartTime!.hour.toString().padLeft(2, '0')}:${_sessionStartTime!.minute.toString().padLeft(2, '0')}' : '';
  
  // Start a new cycling session
  Future<bool> startSession() async {
    if (_isSessionActive) return true;
    
    // Start tracking location
    final trackingStarted = await _locationService.startTracking();
    if (!trackingStarted) return false;
    
    // Reset session data
    _sessionStartTime = DateTime.now();
    _totalDistance = 0.0;
    _elapsedSeconds = 0;
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _speedHistory.clear();
    _resetSpeedZones();
    _lastPosition = await _locationService.getCurrentPosition();
    _lastPositionTime = DateTime.now();
    
    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _durationController.add(_elapsedSeconds);
      
      // Update speed zones every second based on current speed
      _updateSpeedZones(_currentSpeed);
    });
    
    // Listen to location updates
    _locationSubscription = _locationService.locationStream.listen((position) {
      _updateSessionData(position);
    });
    
    _isSessionActive = true;
    return true;
  }
  
  // Reset speed zones counters
  void _resetSpeedZones() {
    for (final key in _speedZones.keys) {
      _speedZones[key] = 0;
    }
    _lastSpeedZoneUpdate = 0;
  }
  
  // Update speed zones based on current speed
  void _updateSpeedZones(double speedKmh) {
    String zone;
    if (speedKmh < 5) {
      zone = '0-5 km/h';
    } else if (speedKmh < 10) {
      zone = '5-10 km/h';
    } else if (speedKmh < 15) {
      zone = '10-15 km/h';
    } else if (speedKmh < 20) {
      zone = '15-20 km/h';
    } else {
      zone = '20+ km/h';
    }
    
    // Increment the appropriate zone counter by seconds since last update
    final int secondsSinceLastUpdate = _elapsedSeconds - _lastSpeedZoneUpdate;
    _speedZones[zone] = (_speedZones[zone] ?? 0) + secondsSinceLastUpdate;
    _lastSpeedZoneUpdate = _elapsedSeconds;
    
    // Notify listeners
    _speedZonesController.add(Map.from(_speedZones));
  }
  
  // Update session data with new position
  void _updateSessionData(Position newPosition) {
    final now = DateTime.now();
    
    if (_lastPosition != null && _lastPositionTime != null) {
      // Calculate distance increase
      final distanceIncrease = _locationService.calculateDistance(
        _lastPosition!,
        newPosition,
      );
      
      // Update total distance
      _totalDistance += distanceIncrease;
      _distanceController.add(_totalDistance);
      
      // Calculate instantaneous speed based on this update
      final timeDelta = now.difference(_lastPositionTime!).inMilliseconds / 1000; // in seconds
      if (timeDelta > 0) {
        // Speed in km/h from the recent position change
        final instantSpeed = (distanceIncrease / timeDelta) * 3600;
        
        // Add to history and maintain max size
        _speedHistory.add(instantSpeed);
        if (_speedHistory.length > _speedHistoryMaxSize) {
          _speedHistory.removeFirst();
        }
        
        // Calculate smoothed speed (average of recent readings)
        if (_speedHistory.isNotEmpty) {
          _currentSpeed = _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
          
          // Update max speed if needed
          if (_currentSpeed > _maxSpeed) {
            _maxSpeed = _currentSpeed;
            _maxSpeedController.add(_maxSpeed);
          }
          
          // Notify speed listeners
          _speedController.add(_currentSpeed);
        }
      }
    }
    
    _lastPosition = newPosition;
    _lastPositionTime = now;
  }
  
  // Get a summary of speed analytics
  Map<String, dynamic> getSpeedAnalytics() {
    // Calculate average speed
    final avgSpeed = _elapsedSeconds > 0 ? (_totalDistance / _elapsedSeconds) * 3600 : 0;
    
    // Calculate percentage time in each speed zone
    final Map<String, double> zonePercentages = {};
    if (_elapsedSeconds > 0) {
      for (final entry in _speedZones.entries) {
        zonePercentages[entry.key] = (entry.value / _elapsedSeconds) * 100;
      }
    }
    
    return {
      'currentSpeed': _currentSpeed,
      'maxSpeed': _maxSpeed,
      'avgSpeed': avgSpeed,
      'speedZones': Map.from(_speedZones),
      'zonePercentages': zonePercentages,
    };
  }
  
  // End the current session and calculate rewards
  Future<CyclingActivity?> endSession(User user) async {
    if (!_isSessionActive) return null;
    
    // Stop tracking
    _locationService.stopTracking();
    _durationTimer?.cancel();
    _locationSubscription?.cancel();
    
    _isSessionActive = false;
    
    // Calculate points
    final pointsEarned = _rewardsService.calculatePoints(_totalDistance);
    
    // Save activity
    final activity = await _rewardsService.addCyclingActivity(
      user.id,
      _totalDistance,
      pointsEarned,
    );
    
    // Update user points
    if (activity != null) {
      user.rewardPoints += pointsEarned;
    }
    
    return activity;
  }
  
  // Cancel current session without saving
  void cancelSession() {
    if (!_isSessionActive) return;
    
    _locationService.stopTracking();
    _durationTimer?.cancel();
    _locationSubscription?.cancel();
    
    _isSessionActive = false;
    _totalDistance = 0.0;
    _elapsedSeconds = 0;
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _speedHistory.clear();
    _resetSpeedZones();
  }
  
  // Format seconds to MM:SS
  String formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // Get session summary with enhanced speed data
  Map<String, dynamic> getSessionSummary() {
    return {
      'distance': _totalDistance,
      'duration': _elapsedSeconds,
      'currentSpeed': _currentSpeed,
      'maxSpeed': _maxSpeed,
      'avgSpeed': _elapsedSeconds > 0 ? (_totalDistance / _elapsedSeconds) * 3600 : 0,
      'startTime': _sessionStartTime,
      'speedZones': Map.from(_speedZones),
    };
  }
  
  void dispose() {
    // Only close the streams, don't cancel the session
    _distanceController.close();
    _durationController.close();
    _speedController.close();
    _maxSpeedController.close();
    _speedZonesController.close();
  }
}
