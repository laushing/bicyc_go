import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserService {
  static const String _userKey = 'user_data';
  
  // For demonstration, we're using SharedPreferences for local storage
  // In a real app, you might use Firebase or another backend service
  
  // Get the current user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData == null) {
      return _createDefaultUser();
    }
    
    return User.fromJson(jsonDecode(userData));
  }
  
  // Save user data
  static Future<bool> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
  
  // For demo purposes, create a default user if none exists
  static Future<User> _createDefaultUser() async {
    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'New Cyclist',
      totalDistance: 0,
      achievementCount: 0,
      favoriteRoute: 'None',
      rewardPoints: 0, // Added required rewardPoints parameter
    );
    
    await saveUser(user);
    return user;
  }
}
