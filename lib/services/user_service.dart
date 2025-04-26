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
      rewardPoints: 0,
    );

    await saveUser(user);
    return user;
  }

  // Get connections for a user
  static Future<List<User>> getUserConnections(String userId) async {
    // Implementation depends on your data source
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      User(
        id: 'user1',
        name: 'Alex Wong',
        photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        totalDistance: 125.4,
        rewardPoints: 0,
      ),
      User(
        id: 'user2',
        name: 'Sarah Chan',
        photoUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        totalDistance: 87.2,
        rewardPoints: 0,
      ),
      // Add more mock users as needed
    ];
  }

  // Get connection requests for a user
  static Future<List<ConnectionRequest>> getConnectionRequests(String userId) async {
    // Implementation depends on your data source
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      ConnectionRequest(
        id: 'req1',
        fromUserId: 'user3',
        fromUserName: 'Michael Lau',
        fromUserPhotoUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        requestDate: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ConnectionRequest(
        id: 'req2',
        fromUserId: 'user4',
        fromUserName: 'Jessica Lin',
        fromUserPhotoUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
        requestDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Accept a connection request
  static Future<bool> acceptConnectionRequest(String userId, String requestId) async {
    // Implementation depends on your data source
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true;
  }

  // Decline a connection request
  static Future<bool> declineConnectionRequest(String userId, String requestId) async {
    // Implementation depends on your data source
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true;
  }

  // Get suggested connections
  static Future<List<User>> getSuggestedConnections() async {
    // Implementation depends on your data source
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      User(
        id: 'user5',
        name: 'David Cheung',
        photoUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
        totalDistance: 56.8,
        rewardPoints: 0,
      ),
      User(
        id: 'user6',
        name: 'Emily Wu',
        photoUrl: 'https://randomuser.me/api/portraits/women/6.jpg',
        totalDistance: 112.5,
        rewardPoints: 0,
      ),
      User(
        id: 'user7',
        name: 'Thomas Ho',
        photoUrl: 'https://randomuser.me/api/portraits/men/7.jpg',
        totalDistance: 89.3,
        rewardPoints: 0,
      ),
    ];
  }

  // Search for users
  static Future<List<User>> searchUsers(String query) async {
    // Implementation depends on your data source
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Mock implementation just returns some users that match the query
    final allUsers = [
      User(
        id: 'user5',
        name: 'David Cheung',
        photoUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
        totalDistance: 56.8,
        rewardPoints: 0,
      ),
      User(
        id: 'user6',
        name: 'Emily Wu',
        photoUrl: 'https://randomuser.me/api/portraits/women/6.jpg',
        totalDistance: 112.5,
        rewardPoints: 0,
      ),
      User(
        id: 'user8',
        name: 'John Smith',
        photoUrl: 'https://randomuser.me/api/portraits/men/8.jpg',
        totalDistance: 75.9,
        rewardPoints: 0,
      ),
    ];

    return allUsers.where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Send a connection request
  static Future<bool> sendConnectionRequest(String userId) async {
    // Implementation depends on your data source
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true;
  }
}
