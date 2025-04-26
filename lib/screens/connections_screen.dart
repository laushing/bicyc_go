import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../l10n/app_localization.dart';

class ConnectionsScreen extends StatefulWidget {
  final String userId;
  
  const ConnectionsScreen({super.key, required this.userId});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  List<User> _connections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    try {
      final connections = await UserService.getUserConnections(widget.userId);
      
      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading connections: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myConnections),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _connections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noConnectionsYet,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.connectToSeeHere,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _connections.length,
              itemBuilder: (context, index) {
                final connection = _connections[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: connection.photoUrl != null
                      ? NetworkImage(connection.photoUrl!)
                      : null,
                    child: connection.photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                  ),
                  title: Text(connection.name),
                  subtitle: Text('${connection.totalDistance.toStringAsFixed(1)} km'),
                  trailing: IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      // Open messaging with this user
                    },
                  ),
                  onTap: () {
                    // View detailed profile
                  },
                );
              },
            ),
    );
  }
}
