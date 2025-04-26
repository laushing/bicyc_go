import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../l10n/app_localization.dart';
import '../screens/ar_navigation_screen.dart';

class MapService {
  final mapController = MapController();
  
  // Add a property to store the current custom route name
  String _customRouteName = 'Custom Route'; // Will be replaced with localized value when context is available
  
  // Add a callback for when a route point is added
  Function()? onRouteUpdated;
  
  // Add a property to store the planned date/time for the route
  DateTime? _routeDateTime;
  
  // Getter for route date time
  DateTime? get routeDateTime => _routeDateTime;
  
  // Getter for the current custom route name
  String get customRouteName => _customRouteName;
  
  // Add a method to force rebuild the map with updated data
  void refreshMap() {
    // Trigger a rebuild of the map
    mapController.move(mapController.center, mapController.zoom);
    if (onRouteUpdated != null) onRouteUpdated!();
  }
  
  // Method to update the custom route name
  void updateCustomRouteName(String newName, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    _customRouteName = newName.isNotEmpty ? newName : (l10n?.createCustomRoute ?? 'Custom Route');
    refreshMap(); // Refresh the map to show new name
  }
  
  // Method to update the route date time
  void updateRouteDateTime(DateTime? dateTime) {
    _routeDateTime = dateTime;
  }
  
  // Enhanced method to show the dialog for editing custom route name
  Future<void> showCustomRouteNameDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController(text: _customRouteName);
    final l10n = AppLocalizations.of(context);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n?.editRouteName ?? 'Edit Route Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: l10n?.routeNameHint ?? 'Enter a name for your custom route',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit_road),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (value) {
              updateCustomRouteName(value, context);
              Navigator.of(dialogContext).pop();
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
              ),
              child: Text(l10n?.cancel ?? 'Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n?.saveRoute ?? 'Save'),
              onPressed: () {
                updateCustomRouteName(nameController.text, context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Method to handle tap on map and show route point dialog
  Future<bool> handleMapTap(BuildContext context, LatLng tappedPoint, List<List<double>> customRoutePoints) async {
    bool pointAdded = false;
    final TextEditingController nameController = TextEditingController(text: _customRouteName);
    final l10n = AppLocalizations.of(context);
    // Initialize with current date/time or existing selection
    DateTime selectedDateTime = _routeDateTime ?? DateTime.now();
    
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n?.addPoint ?? 'Add Route Point'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customRoutePoints.isEmpty) 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.routeName ?? 'Route Name:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: l10n?.routeNameHint ?? 'Enter a name for your route',
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n?.plannedDateTime ?? 'Planned Date & Time:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            title: Text(
                              '${l10n?.date ?? 'Date'} ${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDateTime,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    selectedDateTime.hour,
                                    selectedDateTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                          ListTile(
                            title: Text(
                              '${l10n?.time ?? 'Time'} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  selectedDateTime = DateTime(
                                    selectedDateTime.year,
                                    selectedDateTime.month,
                                    selectedDateTime.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    if (customRoutePoints.isNotEmpty)
                      Text(
                        l10n?.addPointToRoute?.replaceAll('{routeName}', _customRouteName) ?? 
                        'Add point to "${_customRouteName}"?',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n?.location ?? 'Location'} (${tappedPoint.latitude.toStringAsFixed(6)}, ${tappedPoint.longitude.toStringAsFixed(6)})',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                  onPressed: () {
                    print('Cancel button pressed');
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n?.addPoint ?? 'Add Point'),
                  onPressed: () {
                    print('Add Point button pressed');
                    if (customRoutePoints.isEmpty) {
                      // This is the first point, so we set the route name and date
                      updateCustomRouteName(nameController.text, context);
                      updateRouteDateTime(selectedDateTime);
                    }
                    
                    // Add the point and return true
                    pointAdded = true;
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
    
    return pointAdded;
  }
  
  // Helper method to convert coordinates to LatLng objects
  List<LatLng> _convertCoordinatesToLatLng(List<List<double>> coordinates) {
    return coordinates.map((coord) => LatLng(coord[0], coord[1])).toList();
  }
  
  // Method to initialize the map widget with support for custom routes
  Widget buildMap({
    required List<CyclingRoute> routes,
    List<List<double>>? customRoutePoints,
    CyclingRoute? selectedRoute,
    required BuildContext mapContext,
    bool showWaypointNumbers = false,  // Add this parameter
    Function(LatLng)? onTap,
  }) {
    // Use the provided name or the stored name
    final routeName = _customRouteName;
    
    // Print debug info to check if custom route is being passed correctly
    if (customRoutePoints != null) {
      print("Custom route points: ${customRoutePoints.length}");
    }
    
    // Default to Hong Kong if no position provided
    final center = LatLng(22.302711, 114.177216);
    
    // Make sure polylines are created correctly
    List<Polyline> allPolylines = [
      ..._buildRoutesPolylines(routes, selectedRoute),
    ];
    
    // Add custom route polyline if we have enough points
    if (customRoutePoints != null && customRoutePoints.length > 1) {
      allPolylines.add(_buildCustomRoutePolyline(customRoutePoints));
    }
    
    List<Marker> allMarkers = [
      ..._buildRouteMarkers(routes),
    ];
    
    if (customRoutePoints != null && customRoutePoints.isNotEmpty) {
      allMarkers.addAll(_buildCustomRouteMarkers(customRoutePoints, routeName, mapContext));
    }
    
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: center,
        zoom: 13.0,
        interactiveFlags: InteractiveFlag.all,
        onTap: (tapPosition, latLng) async {
          print("Map tapped at: $latLng"); // Add logging
          
          // If we have a context and onTap callback, handle the map tap
          if (mapContext != null && onTap != null) {
            try {
              if (await handleMapTap(mapContext, latLng, customRoutePoints ?? [])) {
                onTap(latLng); // Call the original onTap only if user confirms
                if (onRouteUpdated != null) onRouteUpdated!();
              }
            } catch (e) {
              print("Error handling map tap: $e");
            }
          } else if (onTap != null) {
            // If we don't have a context but have onTap, just call onTap directly
            onTap(latLng);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.bicycgo.app',
        ),
        // Use the pre-generated polylines
        PolylineLayer(
          polylines: allPolylines,
        ),
        // Use the pre-generated markers
        MarkerLayer(
          markers: allMarkers,
        ),
      ],
    );
  }
  
  // Build polylines for all routes
  List<Polyline> _buildRoutesPolylines(List<CyclingRoute> routes, CyclingRoute? selectedRoute) {
    return routes.map((route) {
      bool isSelected = selectedRoute?.id == route.id;
      
      return Polyline(
        points: _convertCoordinatesToLatLng(route.coordinates),
        strokeWidth: isSelected ? 6.0 : 4.0, // Make selected route thicker
        color: isSelected ? Colors.green : Colors.blue, // Use different color for selected route
      );
    }).toList();
  }
  
  // Build polyline for custom route with improved visibility - make sure it works
  Polyline _buildCustomRoutePolyline(List<List<double>> points) {
    List<LatLng> latLngPoints = _convertCoordinatesToLatLng(points);
    print("Building custom route polyline with ${latLngPoints.length} points"); // Debug log
    
    return Polyline(
      points: latLngPoints,
      strokeWidth: 5.0,
      color: Colors.red.withOpacity(0.8),
      isDotted: false,
    );
  }
  
  // Build markers for route start points
  List<Marker> _buildRouteMarkers(List<CyclingRoute> routes) {
    List<Marker> markers = [];
    
    for (var route in routes) {
      final coordinates = _convertCoordinatesToLatLng(route.coordinates);
      if (coordinates.isNotEmpty) {
        final startPoint = coordinates.first;
        markers.add(Marker(
          width: 40.0,
          height: 40.0,
          point: startPoint,
          child: GestureDetector(
            onTap: () {
              // Show route details when marker is tapped
              print('Route selected: ${route.name}');
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40.0,
            ),
          ),
        ));
      }
    }
    
    return markers;
  }
  
  // Updated marker builder to add edit name option
  List<Marker> _buildCustomRouteMarkers(List<List<double>> points, String routeName, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    List<Marker> markers = [];
    
    for (int i = 0; i < points.length; i++) {
      if (i >= points.length) continue; // Extra safety check
      
      final point = LatLng(points[i][0], points[i][1]);
      String markerLabel = i == 0 ? (l10n?.start ?? "Start") : 
                          (i == points.length - 1 ? (l10n?.end ?? "End") : "${i + 1}");
      
      // Add the route name to the first marker
      if (i == 0) {
        markerLabel = "$routeName - ${l10n?.start ?? 'Start'}";
      }
      
      markers.add(
        Marker(
          width: i == 0 ? 120.0 : 30.0, // Make first marker wider for the name
          height: i == 0 ? 70.0 : 30.0, // Make first marker taller for the name
          point: point,
          child: GestureDetector(
            onTap: () {
              print('Waypoint $markerLabel at position: ${points[i]}');
              
              // Add option to edit name when tapping the first marker
              if (i == 0 && mapController.mapEventStream != null) {
                // We need to access the BuildContext, which we don't have here
                // Use a callback pattern to notify the parent widget
                if (onRouteUpdated != null) {
                  onRouteUpdated!();
                  print('Edit route name requested for "${routeName}"');
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.green : (i == points.length - 1 ? Colors.red : Colors.blue),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  width: 30.0,
                  height: 30.0,
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (i == 0 || i == points.length - 1)
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          i == 0 ? routeName : (l10n?.end ?? "End"),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (i == 0) 
                          Icon(
                            Icons.edit,
                            size: 10,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return markers;
  }
  
  // Focus map on a specific route
  void focusOnRoute(CyclingRoute route, {bool showWaypointNumbers = false}) {
    final points = _convertCoordinatesToLatLng(route.coordinates);
    if (points.isNotEmpty) {
      mapController.move(points.first, 15.0);
    }
  }

  // Method to track user location (would need location permissions)
  void trackUserLocation(Function(LatLng) onLocationUpdate) {
    // This would use a location plugin in a real implementation
    // For example, using the location or geolocator package
    print('Location tracking started');
  }

  // Existing methods
  Future<List<CyclingRoute>> fetchPopularRoutes() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return [
      CyclingRoute(
        id: '1',
        name: 'Victoria Peak Loop',
        description: 'Scenic route around Victoria Peak with panoramic views.',
        distance: 8.5,
        estimatedTimeMinutes: 45,
        difficulty: 'medium',
        coordinates: [
          [22.2759, 114.1455],
          [22.2742, 114.1502],
          // More coordinates would be here
        ],
        imageUrl: 'assets/images/victoria_peak.jpg',
      ),
      CyclingRoute(
        id: '2',
        name: 'Tolo Harbour Trail',
        description: 'Flat path along scenic Tolo Harbour with mountain views.',
        distance: 12.2,
        estimatedTimeMinutes: 60,
        difficulty: 'easy',
        coordinates: [
          [22.4199, 114.2079],
          [22.4155, 114.2100],
          // More coordinates would be here
        ],
        imageUrl: 'assets/images/tolo_harbour.jpg',
      ),
    ];
  }

  Future<Map<String, dynamic>> getTrafficUpdates(double lat, double lng) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'status': 'normal',
      'alerts': [
        {
          'type': 'construction',
          'message': 'Road works ahead, proceed with caution',
          'location': [22.2759, 114.1455]
        }
      ]
    };
  }
  
  // Method for AR integration - now navigates to AR screen
  void startARNavigation(CyclingRoute route, BuildContext context) {
    print('Starting AR navigation for route: ${route.name}');
    
    // Navigate to the AR navigation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARNavigationScreen(route: route),
      ),
    );
  }

  // Get tap position on map
  Future<LatLng?> getTapPosition(BuildContext context) async {
    // In a real implementation, we would convert screen coordinates to map coordinates
    // For this example, we'll generate a point near the current center of the map
    final center = mapController.center;
    
    // Generate a point within a small random distance of the center
    final random = Random();
    final lat = center.latitude + (random.nextDouble() - 0.5) * 0.01;
    final lng = center.longitude + (random.nextDouble() - 0.5) * 0.01;
    
    return LatLng(lat, lng);
  }
}
