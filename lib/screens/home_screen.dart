import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pedal_bike, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'BicycGo Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome to your cycling companion!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          StatCard(title: 'Recent Rides', value: '5', icon: Icons.history),
          StatCard(title: 'Weekly Distance', value: '42 km', icon: Icons.timeline),
          StatCard(title: 'Reward Points', value: '350', icon: Icons.star),
        ],
      ),
    );
  }
}
