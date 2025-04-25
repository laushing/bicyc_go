import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/route_model.dart';
import '../l10n/app_localization.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

class ARNavigationScreen extends StatefulWidget {
  final CyclingRoute route;

  const ARNavigationScreen({super.key, required this.route});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraInitialized = false;
  
  // Location tracking
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Compass/heading
  double? _currentHeading;
  StreamSubscription<CompassEvent>? _compassStream;
  
  // Navigation state
  int _currentWaypointIndex = 0;
  double _distanceToNextWaypoint = 0;
  String _currentDirection = "straight";
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;
  
  // Permissions
  bool _hasLocationPermission = false;
  bool _hasCameraPermission = false;
  
  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }
  
  Future<void> _initPermissions() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    _hasCameraPermission = cameraStatus.isGranted;
    
    // Request location permission
    final locationStatus = await Permission.location.request();
    _hasLocationPermission = locationStatus.isGranted;
    
    if (_hasCameraPermission) {
      await _initCamera();
    }
    
    if (_hasLocationPermission) {
      await _initLocationTracking();
      await _initCompass();
      _calculateInitialNavigationData();
    }
    
    // Start tracking elapsed time
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }
  
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  Future<void> _initLocationTracking() async {
    try {
      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Setup position stream for continuous updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
          _updateNavigationData();
        });
      });
    } catch (e) {
      print('Error setting up location tracking: $e');
    }
  }
  
  Future<void> _initCompass() async {
    try {
      _compassStream = FlutterCompass.events?.listen((CompassEvent event) {
        setState(() {
          _currentHeading = event.heading;
          if (_currentHeading != null && _currentPosition != null) {
            _updateDirectionToNextWaypoint();
          }
        });
      });
    } catch (e) {
      print('Error setting up compass: $e');
    }
  }

  void _calculateInitialNavigationData() {
    if (_currentPosition != null && widget.route.coordinates.length > 0) {
      final nextWaypointLat = widget.route.coordinates[0][0];
      final nextWaypointLng = widget.route.coordinates[0][1];
      
      _distanceToNextWaypoint = _calculateDistance(
        _currentPosition!.latitude, 
        _currentPosition!.longitude,
        nextWaypointLat, 
        nextWaypointLng
      );
      
      _updateDirectionToNextWaypoint();
    }
  }
  
  void _updateNavigationData() {
    if (_currentPosition == null || _currentWaypointIndex >= widget.route.coordinates.length) {
      return;
    }
    
    final nextWaypointLat = widget.route.coordinates[_currentWaypointIndex][0];
    final nextWaypointLng = widget.route.coordinates[_currentWaypointIndex][1];
    
    _distanceToNextWaypoint = _calculateDistance(
      _currentPosition!.latitude, 
      _currentPosition!.longitude,
      nextWaypointLat, 
      nextWaypointLng
    );
    
    // Check if we've reached the current waypoint
    if (_distanceToNextWaypoint < 0.015) { // 15 meters threshold
      if (_currentWaypointIndex < widget.route.coordinates.length - 1) {
        setState(() {
          _currentWaypointIndex++;
        });
      } else {
        // Reached the end of the route
        _showNavigationCompleteDialog();
      }
    }
  }
  
  void _updateDirectionToNextWaypoint() {
    if (_currentPosition == null || 
        _currentHeading == null || 
        _currentWaypointIndex >= widget.route.coordinates.length) {
      return;
    }
    
    final nextWaypointLat = widget.route.coordinates[_currentWaypointIndex][0];
    final nextWaypointLng = widget.route.coordinates[_currentWaypointIndex][1];
    
    // Calculate bearing to next waypoint
    final double bearing = _calculateBearing(
      _currentPosition!.latitude, 
      _currentPosition!.longitude,
      nextWaypointLat, 
      nextWaypointLng
    );
    
    // Calculate the difference between our heading and the bearing to the waypoint
    double headingDifference = (bearing - _currentHeading!);
    
    // Normalize to range -180 to 180
    while (headingDifference > 180) headingDifference -= 360;
    while (headingDifference < -180) headingDifference += 360;
    
    // Determine direction based on heading difference
    if (headingDifference > 20) {
      _currentDirection = "right";
    } else if (headingDifference < -20) {
      _currentDirection = "left";
    } else {
      _currentDirection = "straight";
    }
  }
  
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    // Convert to radians
    lat1 = _toRadians(lat1);
    lon1 = _toRadians(lon1);
    lat2 = _toRadians(lat2);
    lon2 = _toRadians(lon2);
    
    // Calculate initial bearing
    double y = sin(lon2 - lon1) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    double bearing = atan2(y, x);
    
    // Convert to degrees
    bearing = (bearing * 180 / pi + 360) % 360;
    
    return bearing;
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation (in km)
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat/2) * sin(dLat/2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon/2) * sin(dLon/2);
        
    final double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
  
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }
  
  void _showNavigationCompleteDialog() {
    // Ensure we don't show the dialog multiple times
    _positionStream?.cancel();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n?.navigationComplete ?? 'Navigation Complete'),
        content: Text(
          l10n?.reachedDestination?.replaceAll('{routeName}', widget.route.name) ?? 
          'You have reached your destination on ${widget.route.name}!'
        ),
        actions: [
          ElevatedButton(
            child: Text(l10n?.returnToMap ?? 'Return to Map'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to map
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _cameraController?.dispose();
    _positionStream?.cancel();
    _compassStream?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n?.navigating ?? 'Navigating'}: ${widget.route.name}'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Camera preview
          _hasCameraPermission && _cameraInitialized && _cameraController != null
              ? SizedBox.expand(
                  child: CameraPreview(_cameraController!),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade200, Colors.blue.shade800],
                    ),
                  ),
                  child: Center(
                    child: _hasCameraPermission 
                        ? const CircularProgressIndicator()
                        : Text(
                            'Camera permission required for AR',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
          
          // Permission error messages
          if (!_hasLocationPermission)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Location permission required for navigation',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.pleaseEnableLocation ?? 'Please enable location services in your device settings to use navigation',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          // AR navigation overlay
          if (_hasLocationPermission)
            Column(
              children: [
                // Direction indicator
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _buildDirectionIndicator(),
                  ),
                ),
                
                // Navigation info panel
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${l10n?.waypoint ?? 'Waypoint'} ${_currentWaypointIndex + 1} / ${widget.route.coordinates.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n?.distanceToNextTurn ?? 'Distance to next turn'}: ${_distanceToNextWaypoint.toStringAsFixed(2)} km',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n?.estimatedTimeRemaining ?? 'Estimated time remaining'}: ${_estimateTimeRemaining()} min',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
          // Current location display (for debugging)
          if (_currentPosition != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'GPS: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'pause',
            onPressed: _togglePause,
            backgroundColor: _isPaused ? Colors.green : Colors.orange,
            child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'exit',
            onPressed: () {
              Navigator.pop(context);
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
  
  int _estimateTimeRemaining() {
    if (_currentPosition == null || _currentWaypointIndex >= widget.route.coordinates.length) {
      return 0;
    }
    
    // Calculate remaining distance
    double remainingDistance = _distanceToNextWaypoint;
    
    // Add distances between remaining waypoints
    for (int i = _currentWaypointIndex; i < widget.route.coordinates.length - 1; i++) {
      remainingDistance += _calculateDistance(
        widget.route.coordinates[i][0],
        widget.route.coordinates[i][1],
        widget.route.coordinates[i + 1][0],
        widget.route.coordinates[i + 1][1]
      );
    }
    
    // Estimate time based on average cycling speed (15 km/h)
    int estimatedMinutes = (remainingDistance / 15 * 60).round();
    return estimatedMinutes;
  }
  
  Widget _buildDirectionIndicator() {
    IconData directionIcon;
    String directionText;
    
    switch (_currentDirection) {
      case "left":
        directionIcon = Icons.turn_left;
        directionText = l10n?.turnLeft ?? "Turn Left";
        break;
      case "right":
        directionIcon = Icons.turn_right;
        directionText = l10n?.turnRight ?? "Turn Right";
        break;
      default:
        directionIcon = Icons.straight;
        directionText = l10n?.continuesStraight ?? "Continue Straight";
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          directionIcon,
          size: 100,
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            directionText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_distanceToNextWaypoint > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_distanceToNextWaypoint.toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
