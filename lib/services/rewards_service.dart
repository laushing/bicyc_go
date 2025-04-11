import '../models/user_model.dart';

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
    await Future.delayed(const Duration(seconds: 1));
    
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
}
