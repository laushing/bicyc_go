import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../l10n/app_localization.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  final String userId;
  
  const ConnectionRequestsScreen({super.key, required this.userId});

  @override
  State<ConnectionRequestsScreen> createState() => _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen> {
  List<ConnectionRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await UserService.getConnectionRequests(widget.userId);
      
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading connection requests: $e')),
      );
    }
  }

  Future<void> _acceptRequest(ConnectionRequest request) async {
    try {
      await UserService.acceptConnectionRequest(widget.userId, request.id);
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nowConnectedWith.replaceFirst('{name}', request.fromUserName))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    }
  }

  Future<void> _declineRequest(ConnectionRequest request) async {
    try {
      await UserService.declineConnectionRequest(widget.userId, request.id);
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectionRequests),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noConnectionRequests,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: request.fromUserPhotoUrl != null
                      ? NetworkImage(request.fromUserPhotoUrl!)
                      : null,
                    child: request.fromUserPhotoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                  ),
                  title: Text(request.fromUserName),
                  subtitle: Text('Sent ${_formatRequestDate(request.requestDate)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _declineRequest(request),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(request),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  String _formatRequestDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
  }
}
