import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class CyclistLocation {
  final String userId;
  final String name;
  final LatLng location;
  final double speed;
  final DateTime timestamp;

  CyclistLocation({
    required this.userId,
    required this.name,
    required this.location,
    this.speed = 0.0,
    required this.timestamp,
  });

  factory CyclistLocation.fromJson(Map<String, dynamic> json) {
    return CyclistLocation(
      userId: json['userId'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      speed: json['speed'] ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class LocationSharingService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _userId = '';
  String _userName = '';
  Timer? _locationUpdateTimer;
  final List<CyclistLocation> _nearbyCyclists = [];
  
  // Stream controller for broadcasting nearby cyclists updates
  final _cyclistsStreamController = StreamController<List<CyclistLocation>>.broadcast();
  
  // Connection event callbacks
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;
  
  // Getters
  bool get isConnected => _isConnected;
  Stream<List<CyclistLocation>> get cyclistsStream => _cyclistsStreamController.stream;
  List<CyclistLocation> get nearbyCyclists => List.unmodifiable(_nearbyCyclists);
  
  // Connect to the location sharing service
  Future<void> connect(String userId, String userName) async {
    try {
      _userId = userId;
      _userName = userName;
      
      // Connect to WebSocket server (replace with your actual server URL)
      final wsUrl = 'wss://bicycgo-api.example.com/location-sharing/$userId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      
      if (onConnected != null) onConnected!();
      
      // Listen for messages from the server
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _handleMessage(data);
        },
        onDone: _handleDisconnect,
        onError: (error) {
          _isConnected = false;
          if (onError != null) onError!(error.toString());
        }
      );
      
      // Start sending location updates
      _startLocationUpdates();
      
    } catch (e) {
      _isConnected = false;
      if (onError != null) onError!(e.toString());
    }
  }
  
  // Disconnect from the service
  void disconnect() {
    _stopLocationUpdates();
    if (_channel != null) {
      _channel!.sink.close();
      _handleDisconnect();
    }
  }
  
  void _handleDisconnect() {
    _isConnected = false;
    _nearbyCyclists.clear();
    _cyclistsStreamController.add(_nearbyCyclists);
    if (onDisconnected != null) onDisconnected!();
  }
  
  void _handleMessage(Map<String, dynamic> data) {
    final messageType = data['type'];
    
    switch (messageType) {
      case 'cyclists_update':
        _updateCyclistsList(data['cyclists']);
        break;
      case 'join_group_ride':
        // Handle joining a group ride
        break;
      case 'leave_group_ride':
        // Handle leaving a group ride
        break;
    }
  }
  
  void _updateCyclistsList(List<dynamic> cyclists) {
    _nearbyCyclists.clear();
    
    for (var cyclist in cyclists) {
      if (cyclist['userId'] != _userId) { // Don't include self
        _nearbyCyclists.add(CyclistLocation.fromJson(cyclist));
      }
    }
    
    // Notify listeners about the update
    _cyclistsStreamController.add(_nearbyCyclists);
  }
  
  // Start sending periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isConnected) {
        try {
          final position = await _getCurrentPosition();
          _sendLocationUpdate(position);
        } catch (e) {
          if (onError != null) onError!('Failed to get location: $e');
        }
      }
    });
  }
  
  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }
  
  Future<Position> _getCurrentPosition() async {
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
    
    return await Geolocator.getCurrentPosition();
  }
  
  void _sendLocationUpdate(Position position) {
    if (_channel != null && _isConnected) {
      final locationData = {
        'type': 'location_update',
        'userId': _userId,
        'name': _userName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel!.sink.add(jsonEncode(locationData));
    }
  }
  
  // Create or join a group ride
  void createGroupRide(String rideName, double radius) {
    if (_channel != null && _isConnected) {
      final message = {
        'type': 'create_group_ride',
        'name': rideName,
        'radius': radius, // in kilometers
      };
      
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
  void joinGroupRide(String rideId) {
    if (_channel != null && _isConnected) {
      final message = {
        'type': 'join_group_ride',
        'rideId': rideId,
      };
      
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
  void leaveGroupRide() {
    if (_channel != null && _isConnected) {
      final message = {
        'type': 'leave_group_ride',
      };
      
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
  // For the demo, we'll simulate real connections with mock data
  void startSimulation() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateNearbyCyclists();
    });
    
    _isConnected = true;
    if (onConnected != null) onConnected!();
  }
  
  void _simulateNearbyCyclists() {
    // Clear previous cyclists
    _nearbyCyclists.clear();
    
    // Generate 3-5 random cyclists
    final random = DateTime.now().millisecondsSinceEpoch;
    final count = 3 + (random % 3);
    
    for (int i = 0; i < count; i++) {
      final latOffset = (random % 100) / 10000 * (i % 2 == 0 ? 1 : -1);
      final lngOffset = (random % 100) / 10000 * (i % 3 == 0 ? 1 : -1);
      
      // Base location - assuming we're in Hong Kong for demo
      final baseLat = 22.302711;
      final baseLng = 114.177216;
      
      _nearbyCyclists.add(CyclistLocation(
        userId: 'user_$i',
        name: 'Cyclist ${i + 1}',
        location: LatLng(baseLat + latOffset, baseLng + lngOffset),
        speed: 15 + (random % 10) / 10,
        timestamp: DateTime.now(),
      ));
    }
    
    // Notify listeners
    _cyclistsStreamController.add(_nearbyCyclists);
  }
  
  void stopSimulation() {
    _locationUpdateTimer?.cancel();
    _nearbyCyclists.clear();
    _cyclistsStreamController.add(_nearbyCyclists);
    
    _isConnected = false;
    if (onDisconnected != null) onDisconnected!();
  }
  
  @override
  void dispose() {
    stopSimulation();
    disconnect();
    _cyclistsStreamController.close();
  }
}
