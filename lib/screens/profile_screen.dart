import 'package:flutter/material.dart';
import '../widgets/profile_stat.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'edit_profile_screen.dart';
import '../l10n/app_localization.dart';
import 'connections_screen.dart';
import 'connection_requests_screen.dart';
import 'find_cyclists_screen.dart';
import 'cyclist_messages_screen.dart';  // Import for messaging screen

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
    final l10n = AppLocalizations.of(context)!;
    
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
            _user?.name ?? l10n.cyclistProfile,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.connectWithCyclists,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ProfileStat(
            label: l10n.totalDistance, 
            value: '${_user?.totalDistance ?? 0} km'
          ),
          ProfileStat(
            label: l10n.achievements, 
            value: '${_user?.achievementCount ?? 0} ${l10n.badges}'
          ),
          ProfileStat(
            label: l10n.favoriteRoute, 
            value: _user?.favoriteRoute ?? l10n.none
          ),
          const SizedBox(height: 20),
          
          // Add Button to communicate with other cyclists
          ElevatedButton.icon(
            icon: const Icon(Icons.message),
            label: Text(l10n.cyclingCommunications),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (_user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CyclistMessagesScreen(currentUser: _user!),
                  ),
                );
              }
            },
          ),
          
          const SizedBox(height: 20),
          
          // Social Connections Section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  l10n.cyclingConnections,
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(
                      icon: Icons.people,
                      label: l10n.connections,
                      count: _user?.connections?.length ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConnectionsScreen(userId: _user!.id),
                          ),
                        );
                      },
                    ),
                    _buildSocialButton(
                      icon: Icons.person_add,
                      label: l10n.requests,
                      count: _user?.connectionRequests?.length ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConnectionRequestsScreen(userId: _user!.id),
                          ),
                        );
                      },
                      showBadge: (_user?.connectionRequests?.length ?? 0) > 0,
                    ),
                    _buildSocialButton(
                      icon: Icons.search,
                      label: l10n.findCyclists,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FindCyclistsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          OutlinedButton(
            child: Text(l10n.editProfile),
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
  
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    int? count,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).primaryColor),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
                if (count != null)
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
            if (showBadge)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
