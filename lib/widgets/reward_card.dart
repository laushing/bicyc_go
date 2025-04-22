import 'package:flutter/material.dart';

class RewardCard extends StatelessWidget {
  final String reward;
  final String points;

  const RewardCard({
    super.key,
    required this.reward,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: ListTile(
        leading: const Icon(Icons.card_giftcard, color: Colors.green),
        title: Text(reward),
        subtitle: Text(points),
        trailing: TextButton(
          child: const Text('REDEEM'),
          onPressed: () {},
        ),
      ),
    );
  }
}
