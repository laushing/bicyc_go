import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _favoriteRouteController;
  late TextEditingController _distanceController;
  late TextEditingController _achievementsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _favoriteRouteController = TextEditingController(text: widget.user.favoriteRoute);
    _distanceController = TextEditingController(text: widget.user.totalDistance.toString());
    _achievementsController = TextEditingController(text: widget.user.achievementCount.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _favoriteRouteController.dispose();
    _distanceController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    // Update the user object
    widget.user.name = _nameController.text;
    widget.user.favoriteRoute = _favoriteRouteController.text;
    widget.user.totalDistance = (int.tryParse(_distanceController.text) ?? 0).toDouble();
    widget.user.achievementCount = int.tryParse(_achievementsController.text) ?? 0;

    // Save to storage
    await UserService.saveUser(widget.user);
    
    setState(() {
      _isSaving = false;
    });
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Total Distance (km)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _achievementsController,
                  decoration: const InputDecoration(
                    labelText: 'Achievements Count',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _favoriteRouteController,
                  decoration: const InputDecoration(
                    labelText: 'Favorite Route',
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          ),
    );
  }
}
