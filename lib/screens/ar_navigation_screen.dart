import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/route_model.dart';
import '../l10n/app_localization.dart';

class ARNavigationScreen extends StatefulWidget {
  final CyclingRoute route;

  const ARNavigationScreen({super.key, required this.route});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  int _currentWaypointIndex = 0;
  double _distanceToNextWaypoint = 0;
  String _currentDirection = "straight";
  Timer? _navigationTimer;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  
  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _calculateInitialNavigationData();
    _startNavigationSimulation();
  }

  void _calculateInitialNavigationData() {
    // Calculate initial distance to first waypoint
    if (widget.route.coordinates.length > 1) {
      _distanceToNextWaypoint = _calculateDistance(
        widget.route.coordinates[0][0], 
        widget.route.coordinates[0][1],
        widget.route.coordinates[1][0], 
        widget.route.coordinates[1][1]
      );
    }
  }

  void _startNavigationSimulation() {
    // Simulate navigation updates every second
    _navigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          
          // Decrease distance to next waypoint as we "move"
          _distanceToNextWaypoint = _distanceToNextWaypoint > 0.01 
              ? _distanceToNextWaypoint - 0.01 
              : 0;
              
          // If we've reached the waypoint, move to the next one
          if (_distanceToNextWaypoint <= 0 && 
              _currentWaypointIndex < widget.route.coordinates.length - 1) {
            _currentWaypointIndex++;
            
            // Calculate new distance and direction
            if (_currentWaypointIndex < widget.route.coordinates.length - 1) {
              _distanceToNextWaypoint = _calculateDistance(
                widget.route.coordinates[_currentWaypointIndex][0],
                widget.route.coordinates[_currentWaypointIndex][1],
                widget.route.coordinates[_currentWaypointIndex + 1][0],
                widget.route.coordinates[_currentWaypointIndex + 1][1]
              );
              
              // Determine direction (simplified)
              _updateDirection();
            }
          }
          
          // End simulation when we reach the last waypoint
          if (_currentWaypointIndex >= widget.route.coordinates.length - 1 && 
              _distanceToNextWaypoint <= 0) {
            _navigationTimer?.cancel();
            _showNavigationCompleteDialog();
          }
        });
      }
    });
  }
  
  void _updateDirection() {
    // For simplicity, randomly change direction occasionally
    if (_elapsedSeconds % 10 == 0) {
      final directions = ["left", "right", "straight"];
      _currentDirection = directions[_elapsedSeconds % 3];
    }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n?.navigationComplete ?? 'Navigation Complete'),
        content: Text(
          l10n?.reachedDestination.replaceAll('{routeName}', widget.route.name) ?? 
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
    _navigationTimer?.cancel();
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
          // Camera preview would go here in a real AR implementation
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade200, Colors.blue.shade800],
              ),
            ),
          ),
          
          // AR navigation overlay
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
                      '${l10n?.estimatedTimeRemaining ?? 'Estimated time remaining'}: ${((widget.route.estimatedTimeMinutes - _elapsedSeconds / 60)).toInt()} min',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
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
        Text(
          directionText,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (_distanceToNextWaypoint > 0)
          Text(
            '${_distanceToNextWaypoint.toStringAsFixed(2)} km',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}
