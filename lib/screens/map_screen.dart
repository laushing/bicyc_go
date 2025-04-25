import 'package:flutter/material.dart';
import '../services/map_service.dart';
import '../services/storage_service.dart';
import '../services/location_sharing_service.dart';
import '../models/route_model.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localization.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();
  final StorageService _storageService = StorageService();
  final LocationSharingService _locationSharingService = LocationSharingService();
  List<CyclingRoute> _availableRoutes = [];
  List<CyclistLocation> _nearbyCyclists = [];
  bool _isLoading = true;
  bool _isCreatingRoute = false;
  bool _isLocationSharingEnabled = false;
  final List<List<double>> _customRoutePoints = [];
  String _customRouteName = 'Custom Route';
  CyclingRoute? _selectedRoute;
  
  // Add a class-level variable for localization
  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _loadRoutes();

    // Set up callbacks
    _mapService.onRouteUpdated = () {
      setState(() {
        _customRouteName = _mapService.customRouteName;
      });
      _mapService.showCustomRouteNameDialog(context);
    };
    
    // Set up location sharing callbacks
    _locationSharingService.onConnected = () {
      if (mounted) {
        setState(() {
          _isLocationSharingEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.locationSharingEnabled ?? 'Location sharing enabled')),
        );
      }
    };
    
    _locationSharingService.onDisconnected = () {
      if (mounted) {
        setState(() {
          _isLocationSharingEnabled = false;
          _nearbyCyclists = [];
        });
      }
    };
    
    // Listen for cyclist updates
    _locationSharingService.cyclistsStream.listen((cyclists) {
      setState(() {
        _nearbyCyclists = cyclists;
      });
    });
  }

  @override
  void dispose() {
    _locationSharingService.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First load saved routes
      final savedRoutes = await _storageService.loadRoutes();
      
      // Then fetch popular routes
      final popularRoutes = await _mapService.fetchPopularRoutes();
      
      // Combine them, ensuring no duplicates by ID
      final Map<String, CyclingRoute> routesMap = {};
      
      // Add popular routes first
      for (var route in popularRoutes) {
        routesMap[route.id] = route;
      }
      
      // Then add saved routes (will override popular routes with same ID)
      for (var route in savedRoutes) {
        routesMap[route.id] = route;
      }
      
      setState(() {
        _availableRoutes = routesMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.loadRoutesError ?? 'Failed to load routes'}: $e')),
        );
      }
    }
  }

  void _showRoutePlanningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.planRoute ?? 'Plan Your Route'),
        content: SizedBox(
          width: double.maxFinite,
          child: _availableRoutes.isEmpty
              ? Center(child: Text(l10n?.noRoutesAvailable ?? 'No routes available'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _availableRoutes[index];
                    return ListTile(
                      title: Text(route.name),
                      subtitle: Text(
                        '${route.distance} km • ${route.difficulty} • ~${route.estimatedTimeMinutes} min',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectRoute(route);
                      },
                      // Add delete button for custom routes
                      trailing: route.id.startsWith('custom_')
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteRoute(route.id);
                              },
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startCustomRouteCreation();
            },
            child: Text(l10n?.createCustomRoute ?? 'Create Custom Route'),
          ),
        ],
      ),
    );
  }

  void _startCustomRouteCreation() {
    setState(() {
      _isCreatingRoute = true;
      _customRoutePoints.clear();
      _customRouteName = '${l10n?.createCustomRoute ?? 'Custom Route'} ${DateTime.now().millisecondsSinceEpoch}';
      _mapService.updateCustomRouteName(_customRouteName);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.tapToAddPoint ?? 'Tap on the map to add waypoints. Tap "Save Route" when finished.'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _addWaypoint(double lat, double lng) {
    if (!_isCreatingRoute) return;

    setState(() {
      _customRoutePoints.add([lat, lng]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.pointAdded.replaceAll('{count}', _customRoutePoints.length.toString()) ?? 
                      'Point added! (${_customRoutePoints.length} total)'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _saveCustomRoute() {
    if (_customRoutePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.needMorePoints ?? 'Add at least 2 points to create a route')),
      );
      return;
    }

    // Use the route name from the mapService
    final routeName = _mapService.customRouteName;
    final plannedDateTime = _mapService.routeDateTime;
    
    String description;
    if (plannedDateTime != null) {
      description = '${l10n?.createCustomRoute ?? 'Custom route created by user'} '
                    '(${l10n?.plannedDateTime ?? 'Planned for'} '
                    '${plannedDateTime.day}/${plannedDateTime.month}/${plannedDateTime.year})';
    } else {
      description = l10n?.createCustomRoute ?? 'Custom route created by user';
    }

    final newRoute = CyclingRoute(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: routeName,
      description: description,
      distance: _calculateRouteDistance(_customRoutePoints),
      estimatedTimeMinutes: _estimateTime(_customRoutePoints),
      difficulty: 'custom',
      coordinates: _customRoutePoints,
      imageUrl: 'assets/images/custom_route.jpg',
    );

    setState(() {
      _availableRoutes.add(newRoute);
      _isCreatingRoute = false;
      _customRoutePoints.clear();
    });
    
    // Save the updated routes list
    _storageService.saveRoutes(_availableRoutes).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.routeSaved ?? 'Route saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.routeSaveError ?? 'Failed to save route')),
        );
      }
    });

    _selectRoute(newRoute);
  }
  
  void _deleteRoute(String routeId) {
    setState(() {
      _availableRoutes.removeWhere((route) => route.id == routeId);
    });
    
    // Save the updated routes list
    _storageService.saveRoutes(_availableRoutes);
  }

  double _calculateRouteDistance(List<List<double>> points) {
    if (points.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final dx = (points[i + 1][0] - points[i][0]) * 111;
      final dy = (points[i + 1][1] - points[i][1]) * 111 * cos(points[i][0] * pi / 180);
      totalDistance += sqrt(dx * dx + dy * dy);
    }

    return double.parse(totalDistance.toStringAsFixed(1));
  }

  int _estimateTime(List<List<double>> points) {
    final distance = _calculateRouteDistance(points);
    return (distance / 15 * 60).round();
  }

  void _selectRoute(CyclingRoute route) {
    setState(() {
      _selectedRoute = route; // Store the selected route
    });
    
    _mapService.focusOnRoute(route);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n?.routeSelected ?? 'Route selected:'} ${route.name}'),
        action: SnackBarAction(
          label: l10n?.startNavigation ?? 'Start Navigation',
          onPressed: () => _startNavigation(route),
        ),
      ),
    );
  }

  void _toggleLocationSharing() {
    if (_isLocationSharingEnabled) {
      _locationSharingService.stopSimulation();
      setState(() {
        _isLocationSharingEnabled = false;
      });
    } else {
      _locationSharingService.startSimulation();
    }
  }

  void _startNavigation(CyclingRoute route) {
    _mapService.startARNavigation(route, context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n?.navigationStarted ?? 'Starting navigation for'} ${route.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mapService.buildMap(
                  routes: _availableRoutes,
                  customRoutePoints: _isCreatingRoute ? _customRoutePoints : null,
                  selectedRoute: _selectedRoute,
                  mapContext: context,
                  // Remove the nearbyCyclists parameter as it is not defined
                  onTap: _isCreatingRoute
                      ? (LatLng coords) {
                          _addWaypoint(coords.latitude, coords.longitude);
                        }
                      : null,
                ),
                
          // Location sharing toggle button
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: _isLocationSharingEnabled ? Colors.green : Colors.grey,
              onPressed: _toggleLocationSharing,
              child: Icon(
                _isLocationSharingEnabled ? Icons.location_on : Icons.location_off,
                color: Colors.white,
              ),
            ),
          ),
          
          // Bottom planning button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _isCreatingRoute
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: Text(l10n?.cancel ?? 'Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isCreatingRoute = false;
                              _customRoutePoints.clear();
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(l10n?.saveRoute ?? 'Save Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saveCustomRoute,
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: Text(l10n?.planRoute ?? 'Plan a Route'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showRoutePlanningDialog,
                    ),
            ),
          ),
          
          // Cyclists info panel when location sharing is enabled
          if (_isLocationSharingEnabled && _nearbyCyclists.isNotEmpty)
            Positioned(
              top: 80,
              right: 10,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.nearbyCyclists ?? 'Nearby Cyclists',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...List.generate(
                      _nearbyCyclists.length > 3 ? 3 : _nearbyCyclists.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bike, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              _nearbyCyclists[index].name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              '${_nearbyCyclists[index].speed.toStringAsFixed(1)} km/h',
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_nearbyCyclists.length > 3)
                      Center(
                        child: Text(
                          '+ ${_nearbyCyclists.length - 3} ${l10n?.more ?? 'more'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isCreatingRoute
          ? FloatingActionButton(
              onPressed: () {
                _mapService.showCustomRouteNameDialog(context);
              },
              tooltip: l10n?.editRouteName ?? 'Edit Route Name',
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}
