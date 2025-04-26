import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/stat_card.dart';
import '../services/rewards_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../l10n/app_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _appOpenCount = 0;
  double _totalDistance = 0.0;
  int _rewardPoints = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Track app opens using shared preferences
      final prefs = await SharedPreferences.getInstance();
      int openCount = prefs.getInt('app_open_count') ?? 0;
      openCount++; // Increment for current open
      await prefs.setInt('app_open_count', openCount);
      
      // Get user data for total distance and rewards
      final User? user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('User data is null');
      }
      
      setState(() {
        _appOpenCount = openCount;
        _totalDistance = user.totalDistance;
        _rewardPoints = user.rewardPoints;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading home data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pedal_bike, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              l10n?.dashboard ?? 'BicycGo Dashboard',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              l10n?.connectWithCyclists ?? 'Welcome to your cycling companion!',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            
            // Show app open count as recent rides
            StatCard(
              title: l10n?.recentRides ?? 'Recent Rides',
              value: _appOpenCount.toString(),
              icon: Icons.history,
            ),
            
            // Show total distance instead of weekly distance
            StatCard(
              title: l10n?.totalDistance ?? 'Total Distance',
              value: '${_totalDistance.toStringAsFixed(1)} km',
              icon: Icons.timeline,
            ),
            
            // Show actual reward points from user data
            StatCard(
              title: l10n?.rewardPoints ?? 'Reward Points',
              value: _rewardPoints.toString(),
              icon: Icons.star,
            ),
            
            // Add refresh button
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.refresh ?? 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
  }
}
