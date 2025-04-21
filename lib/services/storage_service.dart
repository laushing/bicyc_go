import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_model.dart';

class StorageService {
  static const String _routesKey = 'saved_cycling_routes';
  
  // Save routes to SharedPreferences
  Future<bool> saveRoutes(List<CyclingRoute> routes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesJson = routes.map((route) => route.toJson()).toList();
      await prefs.setString(_routesKey, jsonEncode(routesJson));
      return true;
    } catch (e) {
      print('Error saving routes: $e');
      return false;
    }
  }
  
  // Load routes from SharedPreferences
  Future<List<CyclingRoute>> loadRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesString = prefs.getString(_routesKey);
      
      if (routesString == null || routesString.isEmpty) {
        return [];
      }
      
      final routesJson = jsonDecode(routesString) as List;
      return routesJson
          .map((routeJson) => CyclingRoute.fromJson(routeJson))
          .toList();
    } catch (e) {
      print('Error loading routes: $e');
      return [];
    }
  }
}
