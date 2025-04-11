import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'Interactive Cycling Map',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Hong Kong cycling routes with real-time traffic updates and AR navigation coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.navigation),
            label: const Text('Plan a Route'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onPressed: () {
              // Route planning functionality will be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route planning coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
