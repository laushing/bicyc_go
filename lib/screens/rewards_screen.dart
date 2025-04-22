import 'package:flutter/material.dart';
import '../widgets/reward_card.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            'Cycling Rewards',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Earn points for every kilometer cycled!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          const RewardCard(reward: 'Free Bike Maintenance', points: '500 points'),
          const RewardCard(reward: 'Water Bottle', points: '200 points'),
          const RewardCard(reward: 'Pro Cycling Jersey', points: '1000 points'),
        ],
      ),
    );
  }
}
