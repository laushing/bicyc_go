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
}
