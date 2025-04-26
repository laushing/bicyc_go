import 'package:flutter/material.dart';
import '../services/rewards_service.dart';
import '../models/user_model.dart';
import '../l10n/app_localization.dart';
import 'dart:async';

class CyclistMessagesScreen extends StatefulWidget {
  final User currentUser;
  
  const CyclistMessagesScreen({super.key, required this.currentUser});

  @override
  State<CyclistMessagesScreen> createState() => _CyclistMessagesScreenState();
}

class _CyclistMessagesScreenState extends State<CyclistMessagesScreen> with SingleTickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  List<Map<String, dynamic>> _recentConversations = [];
  List<Map<String, dynamic>> _nearbyCyclists = [];
  List<Map<String, dynamic>> _activeRides = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConversations();
    _loadNearbyCyclists();
    _loadActiveRides();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final conversations = await _rewardsService.getRecentConversations(widget.currentUser.id);
      setState(() {
        _recentConversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }
  
  Future<void> _loadNearbyCyclists() async {
    try {
      // In a real app, you would get the user's current location
      final latitude = 22.2796; // Example Hong Kong latitude
      final longitude = 114.1722; // Example Hong Kong longitude
      
      final cyclists = await _rewardsService.findActiveCyclists(latitude, longitude, 5.0);
      setState(() {
        _nearbyCyclists = cyclists;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding nearby cyclists: $e')),
        );
      }
    }
  }
  
  Future<void> _loadActiveRides() async {
    try {
      // In a real app, you would get the user's current location
      final latitude = 22.2796; // Example Hong Kong latitude
      final longitude = 114.1722; // Example Hong Kong longitude
      
      final rides = await _rewardsService.getActiveGroupRides(latitude, longitude, 10.0);
      setState(() {
        _activeRides = rides;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group rides: $e')),
        );
      }
    }
  }
  
  void _navigateToChat(String userId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          currentUser: widget.currentUser,
          otherUserId: userId,
          otherUserName: name,
        ),
      ),
    ).then((_) => _loadConversations());
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cyclingCommunications),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.messages),
            Tab(text: l10n.nearbyCyclists),
            Tab(text: l10n.groupCycling),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Messages tab
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _recentConversations.isEmpty
              ? Center(child: Text(l10n.noMessagesYet))
              : _buildConversationsList(),
              
          // Nearby cyclists tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _nearbyCyclists.isEmpty
              ? Center(child: Text(l10n.noCyclistsNearby))
              : _buildNearbyCyclistsList(),
              
          // Group rides tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activeRides.isEmpty
              ? Center(child: Text('No active group rides nearby'))
              : _buildGroupRidesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create group chat screen
          _showCreateGroupDialog();
        },
        child: const Icon(Icons.group_add),
        tooltip: l10n.createGroup,
      ),
    );
  }
  
  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _recentConversations.length,
        itemBuilder: (context, index) {
          final conversation = _recentConversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(conversation['profilePhoto']),
            ),
            title: Text(conversation['name']),
            subtitle: Text(
              conversation['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (conversation['unreadCount'] > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation['unreadCount'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => _navigateToChat(conversation['userId'], conversation['name']),
          );
        },
      ),
    );
  }
  
  Widget _buildNearbyCyclistsList() {
    final l10n = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _loadNearbyCyclists,
      child: ListView.builder(
        itemCount: _nearbyCyclists.length,
        itemBuilder: (context, index) {
          final cyclist = _nearbyCyclists[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(cyclist['profilePhoto']),
            ),
            title: Text(cyclist['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on, 
                      size: 14, 
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cyclist['distance'].toStringAsFixed(1)} km away',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.directions_bike, 
                      size: 14, 
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Cycling on ${cyclist['routeName']} at ${cyclist['speed'].toStringAsFixed(1)} km/h',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cyclist['currentlyActive'] ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  color: Colors.blue,
                  onPressed: () => _navigateToChat(cyclist['id'], cyclist['name']),
                ),
              ],
            ),
            onTap: () {
              // View full profile
              _showCyclistDetailDialog(cyclist);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildGroupRidesList() {
    final l10n = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _loadActiveRides,
      child: ListView.builder(
        itemCount: _activeRides.length,
        itemBuilder: (context, index) {
          final ride = _activeRides[index];
          final startTime = ride['startTime'] as DateTime;
          final now = DateTime.now();
          final isToday = startTime.day == now.day && 
                          startTime.month == now.month && 
                          startTime.year == now.year;
          
          final formattedDate = isToday 
              ? 'Today at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}' 
              : '${startTime.day}/${startTime.month} at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ride['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(ride['difficulty']),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          ride['difficulty'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organized by: ${ride['organizer']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(formattedDate),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(ride['startLocation']),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('${ride['distance']} km'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('${ride['participants']}/${ride['maxParticipants']} participants'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _joinGroupRide(ride['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.joinGroupRide),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
  
  Future<void> _joinGroupRide(String rideId) async {
    try {
      final success = await _rewardsService.joinGroupRide(widget.currentUser.id, rideId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined the group ride!')),
        );
        
        // Refresh the list of rides
        _loadActiveRides();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining group ride: $e')),
        );
      }
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
  
  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Cycling Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Weekend Riders',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can add members after creating the group',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _createGroup(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
  
  void _showCyclistDetailDialog(Map<String, dynamic> cyclist) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.green.shade100,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(cyclist['profilePhoto']),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cyclist['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, '${cyclist['distance'].toStringAsFixed(1)} km away'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.directions_bike, 'Currently cycling on ${cyclist['routeName']}'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.speed, 'Current speed: ${cyclist['speed'].toStringAsFixed(1)} km/h'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: Text(l10n.sendMessage),
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToChat(cyclist['id'], cyclist['name']);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.directions_bike),
                        label: Text(l10n.inviteToRide),
                        onPressed: () {
                          Navigator.pop(context);
                          _showRouteShareDialog(cyclist['id'], cyclist['name']);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
  
  void _showRouteShareDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Route with $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.route, color: Colors.green),
              title: const Text('Victoria Peak Loop'),
              subtitle: const Text('8.5 km • Medium'),
              onTap: () {
                Navigator.pop(context);
                _shareRoute(userId, userName, 'route_1', 'Victoria Peak Loop');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.blue),
              title: const Text('Tolo Harbour Trail'),
              subtitle: const Text('12.2 km • Easy'),
              onTap: () {
                Navigator.pop(context);
                _shareRoute(userId, userName, 'route_2', 'Tolo Harbour Trail');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.orange),
              title: const Text('Tai Mo Shan Challenge'),
              subtitle: const Text('22.5 km • Hard'),
              onTap: () {
                Navigator.pop(context);
                _shareRoute(userId, userName, 'route_3', 'Tai Mo Shan Challenge');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareRoute(String userId, String userName, String routeId, String routeName) async {
    try {
      final success = await _rewardsService.shareRoute(
        widget.currentUser.id,
        userId,
        routeId,
        routeName,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route shared with $userName successfully')),
        );
        
        // Open chat with the user to follow up
        _navigateToChat(userId, userName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing route: $e')),
        );
      }
    }
  }
  
  Future<void> _createGroup(String groupName) async {
    try {
      final result = await _rewardsService.createGroupChat(
        widget.currentUser.id, 
        groupName, 
        [],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$groupName" created successfully!')),
        );
      }
      
      // Refresh conversations to show the new group
      _loadConversations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }
}

// The individual chat detail screen
class ChatDetailScreen extends StatefulWidget {
  final User currentUser;
  final String otherUserId;
  final String otherUserName;
  
  const ChatDetailScreen({
    super.key, 
    required this.currentUser, 
    required this.otherUserId, 
    required this.otherUserName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final RewardsService _rewardsService = RewardsService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final messages = await _rewardsService.getMessageHistory(
        widget.currentUser.id, 
        widget.otherUserId,
      );
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Scroll to bottom of chat on load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    _messageController.clear();
    
    // Add message to local list immediately for UI responsiveness
    final newMessage = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': widget.currentUser.id,
      'receiverId': widget.otherUserId,
      'content': messageText,
      'timestamp': DateTime.now(),
      'read': false,
    };
    
    setState(() {
      _messages.add(newMessage);
    });
    
    // Scroll to the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    try {
      final success = await _rewardsService.sendMessage(
        widget.currentUser.id,
        widget.otherUserId,
        messageText,
      );
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () => _showShareRouteDialog(),
            tooltip: 'Share a route',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
            tooltip: 'User info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }
  
  Widget _buildMessageItem(Map<String, dynamic> message) {
    final isMe = message['senderId'] == widget.currentUser.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) 
            const CircleAvatar(
              child: Icon(Icons.person),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['content'],
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMe)
            const CircleAvatar(
              child: Icon(Icons.person),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: l10n.typeMessage,
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
  
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (today == messageDay) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (today.difference(messageDay).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  void _showShareRouteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share a Cycling Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.route, color: Colors.green),
              title: const Text('Victoria Peak Loop'),
              subtitle: const Text('8.5 km • Medium'),
              onTap: () => _shareRoute('route_1', 'Victoria Peak Loop'),
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.blue),
              title: const Text('Tolo Harbour Trail'),
              subtitle: const Text('12.2 km • Easy'),
              onTap: () => _shareRoute('route_2', 'Tolo Harbour Trail'),
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.orange),
              title: const Text('Tai Mo Shan Challenge'),
              subtitle: const Text('22.5 km • Hard'),
              onTap: () => _shareRoute('route_3', 'Tai Mo Shan Challenge'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareRoute(String routeId, String routeName) async {
    Navigator.pop(context);
    
    try {
      final success = await _rewardsService.shareRoute(
        widget.currentUser.id,
        widget.otherUserId,
        routeId,
        routeName,
      );
      
      if (success && mounted) {
        // Add a message to the chat about the shared route
        final newMessage = {
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'senderId': widget.currentUser.id,
          'receiverId': widget.otherUserId,
          'content': 'I\'ve shared the "$routeName" route with you!',
          'timestamp': DateTime.now(),
          'read': false,
        };
        
        setState(() {
          _messages.add(newMessage);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route shared successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share route')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing route: $e')),
        );
      }
    }
  }
}
