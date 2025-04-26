import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../l10n/app_localization.dart';

class FindCyclistsScreen extends StatefulWidget {
  const FindCyclistsScreen({super.key});

  @override
  State<FindCyclistsScreen> createState() => _FindCyclistsScreenState();
}

class _FindCyclistsScreenState extends State<FindCyclistsScreen> {
  List<User> _suggestedUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedUsers() async {
    try {
      final suggestions = await UserService.getSuggestedConnections();
      
      setState(() {
        _suggestedUsers = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading suggestions: $e')),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await UserService.searchUsers(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  Future<void> _sendConnectionRequest(User user) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await UserService.sendConnectionRequest(user.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requestSentTo.replaceFirst('{name}', user.name))),
      );
      
      // Refresh the suggested users
      _loadSuggestedUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.findCyclists),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchCyclists,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Search results or suggested connections
          Expanded(
            child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchController.text.isNotEmpty
                ? _buildUserList(
                    _searchResults, 
                    l10n.noSearchResults,
                    l10n
                  )
                : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUserList(
                      _suggestedUsers, 
                      l10n.noConnectionsYet,
                      l10n
                    ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserList(List<User> users, String emptyMessage, AppLocalizations l10n) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
            child: user.photoUrl == null
              ? const Icon(Icons.person)
              : null,
          ),
          title: Text(user.name),
          subtitle: Text('${user.totalDistance.toStringAsFixed(1)} km'),
          trailing: TextButton.icon(
            icon: const Icon(Icons.person_add),
            label: Text(l10n.connect),
            onPressed: () => _sendConnectionRequest(user),
          ),
          onTap: () {
            // View detailed profile
          },
        );
      },
    );
  }
}
