import '../models/user_model.dart';
import '../models/cycling_activity.dart';

class RewardsService {
  // Calculate points based on distance cycled
  int calculatePoints(double distanceKm) {
    return (distanceKm * 10).round(); // 10 points per km
  }
  
  // Check if user has enough points for a reward
  bool canRedeem(User user, int requiredPoints) {
    return user.rewardPoints >= requiredPoints;
  }
  
  // Redeem a reward (would connect to backend)
  Future<bool> redeemReward(String userId, String rewardId, int pointsCost) async {
    // In a real app, this would make an API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Placeholder for reward redemption logic
    print('User $userId redeemed reward $rewardId for $pointsCost points');
    return true;
  }
  
  // Get available rewards (would fetch from backend)
  Future<List<Map<String, dynamic>>> getAvailableRewards() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      {
        'id': '1',
        'name': 'Free Bike Maintenance',
        'description': 'One free basic bike maintenance service',
        'pointsCost': 500,
        'imageUrl': 'assets/images/bike_maintenance.jpg',
      },
      {
        'id': '2',
        'name': 'Water Bottle',
        'description': 'BicycGo branded sports water bottle',
        'pointsCost': 200,
        'imageUrl': 'assets/images/water_bottle.jpg',
      },
      {
        'id': '3',
        'name': 'Pro Cycling Jersey',
        'description': 'Professional-grade cycling jersey',
        'pointsCost': 1000,
        'imageUrl': 'assets/images/jersey.jpg',
      },
    ];
  }
  
  // Get recent cycling activities for a user
  Future<List<CyclingActivity>> getRecentActivities(String userId) async {
    // In a real app, this would fetch from a database or API
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return some mock activities
    final now = DateTime.now();
    return [
      CyclingActivity(
        id: 'act1',
        userId: userId,
        distance: 5.2,
        pointsEarned: 52,
        date: now.subtract(const Duration(days: 1)),
      ),
      CyclingActivity(
        id: 'act2',
        userId: userId,
        distance: 8.7,
        pointsEarned: 87,
        date: now.subtract(const Duration(days: 3)),
      ),
      CyclingActivity(
        id: 'act3',
        userId: userId,
        distance: 3.1,
        pointsEarned: 31,
        date: now.subtract(const Duration(days: 6)),
      ),
    ];
  }
  
  // Add a new cycling activity and earn points
  Future<CyclingActivity?> addCyclingActivity(
    String userId, 
    double distance, 
    int pointsEarned
  ) async {
    // In a real app, this would save to a database and update user points
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Create a new activity
    final activity = CyclingActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      distance: distance,
      pointsEarned: pointsEarned,
      date: DateTime.now(),
    );
    
    print('User $userId earned $pointsEarned points by cycling $distance km');
    return activity;
  }
  
  // Find active cyclists nearby (simulated implementation)
  Future<List<Map<String, dynamic>>> findActiveCyclists(double latitude, double longitude, double radiusKm) async {
    // In a real app, this would query a backend or real-time database
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate some mock nearby cyclists
    return [
      {
        'id': 'user123',
        'name': 'Alex Chen',
        'distance': 1.2, // km away
        'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
        'currentlyActive': true,
        'profilePhoto': 'assets/images/profile_alex.jpg',
        'speed': 18.5, // km/h
        'routeName': 'Victoria Peak Loop'
      },
      {
        'id': 'user456',
        'name': 'Maya Wong',
        'distance': 2.5, // km away
        'lastActive': DateTime.now().subtract(const Duration(minutes: 15)),
        'currentlyActive': true,
        'profilePhoto': 'assets/images/profile_maya.jpg',
        'speed': 15.2, // km/h
        'routeName': 'Tolo Harbour Trail'
      },
    ];
  }
  
  // Send message to another cyclist
  Future<bool> sendMessage(String fromUserId, String toUserId, String messageContent) async {
    // In a real app, this would send to a backend messaging service
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Log the message for this example
    print('Message from $fromUserId to $toUserId: $messageContent');
    
    // Simulate successful message sending
    return true;
  }
  
  // Get message history with a specific cyclist
  Future<List<Map<String, dynamic>>> getMessageHistory(String userId, String otherUserId) async {
    // In a real app, this would fetch from a database
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return mock message history
    final now = DateTime.now();
    return [
      {
        'id': 'msg1',
        'senderId': otherUserId,
        'receiverId': userId,
        'content': 'Hi there! Are you cycling today?',
        'timestamp': now.subtract(const Duration(hours: 2)),
        'read': true,
      },
      {
        'id': 'msg2',
        'senderId': userId,
        'receiverId': otherUserId,
        'content': 'Yes, planning to ride along the harbor in about an hour!',
        'timestamp': now.subtract(const Duration(hours: 1, minutes: 45)),
        'read': true,
      },
      {
        'id': 'msg3',
        'senderId': otherUserId,
        'receiverId': userId,
        'content': 'Great! Mind if I join you? I could use some company.',
        'timestamp': now.subtract(const Duration(hours: 1, minutes: 30)),
        'read': true,
      },
      {
        'id': 'msg4',
        'senderId': userId,
        'receiverId': otherUserId,
        'content': 'Sure! Let\'s meet at Victoria Park entrance at 3pm.',
        'timestamp': now.subtract(const Duration(hours: 1)),
        'read': true,
      },
    ];
  }
  
  // Get list of recent conversations
  Future<List<Map<String, dynamic>>> getRecentConversations(String userId) async {
    // In a real app, this would fetch from a database
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    return [
      {
        'userId': 'user123',
        'name': 'Alex Chen',
        'lastMessage': 'Are we still meeting tomorrow?',
        'timestamp': now.subtract(const Duration(hours: 1)),
        'unreadCount': 1,
        'profilePhoto': 'assets/images/profile_alex.jpg',
      },
      {
        'userId': 'user456',
        'name': 'Maya Wong',
        'lastMessage': 'Thanks for the route recommendation!',
        'timestamp': now.subtract(const Duration(days: 1)),
        'unreadCount': 0,
        'profilePhoto': 'assets/images/profile_maya.jpg',
      },
    ];
  }
  
  // Create or join a cycling group chat
  Future<Map<String, dynamic>> createGroupChat(String creatorId, String groupName, List<String> initialMemberIds) async {
    // In a real app, this would create a group chat in the backend
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    
    // Return the created group info
    return {
      'id': groupId,
      'name': groupName,
      'creatorId': creatorId,
      'members': [...initialMemberIds, creatorId],
      'createdAt': DateTime.now(),
      'lastActive': DateTime.now(),
    };
  }
  
  // Share a cycling route with another user
  Future<bool> shareRoute(String fromUserId, String toUserId, String routeId, String routeName) async {
    // In a real app, this would save the shared route to a database
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Log the route sharing for this example
    print('Route $routeId ($routeName) shared from $fromUserId to $toUserId');
    
    // Simulate successful route sharing
    return true;
  }
  
  // Join a group ride with other cyclists
  Future<bool> joinGroupRide(String userId, String rideId) async {
    // In a real app, this would update a group ride in the backend
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Log joining the ride
    print('User $userId joined ride $rideId');
    
    return true;
  }
  
  // Get active group rides nearby
  Future<List<Map<String, dynamic>>> getActiveGroupRides(double latitude, double longitude, double radiusKm) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Return mock group rides
    return [
      {
        'id': 'ride1',
        'name': 'Saturday Morning Ride',
        'organizer': 'Hong Kong Cycling Club',
        'startTime': DateTime.now().add(const Duration(days: 1, hours: 10)),
        'startLocation': 'Victoria Park',
        'route': 'Victoria Park to Taikoo Shing',
        'distance': 15.5,
        'participants': 12,
        'maxParticipants': 20,
        'difficulty': 'Easy',
      },
      {
        'id': 'ride2',
        'name': 'Tai Mo Shan Challenge',
        'organizer': 'Adventure Cyclists',
        'startTime': DateTime.now().add(const Duration(days: 2, hours: 8)),
        'startLocation': 'Tsuen Wan Park',
        'route': 'Tsuen Wan to Tai Mo Shan Peak',
        'distance': 28.2,
        'participants': 8,
        'maxParticipants': 15,
        'difficulty': 'Hard',
      },
    ];
  }
}
