import 'package:flutter/material.dart';
import '../widgets/profile_stat.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green,
            backgroundImage: _user?.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
            child: _user?.photoUrl == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
          ),
          const SizedBox(height: 20),
          Text(
            _user?.name ?? 'Cyclist Profile',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect with other cyclists in Hong Kong',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ProfileStat(
            label: 'Total Distance', 
            value: '${_user?.totalDistance ?? 0} km'
          ),
          ProfileStat(
            label: 'Achievements', 
            value: '${_user?.achievementCount ?? 0} badges'
          ),
          ProfileStat(
            label: 'Favorite Route', 
            value: _user?.favoriteRoute ?? 'None'
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            child: const Text('Edit Profile'),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: _user!),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
          ),
        ],
      ),
    );
  }
}
