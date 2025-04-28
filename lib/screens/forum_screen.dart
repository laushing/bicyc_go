import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../models/forum_post_model.dart';
import '../services/forum_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_filters/flutter_image_filters.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with TickerProviderStateMixin {
  final List<ForumPost> _posts = [];
  bool _isLoading = true;
  final TextEditingController _newPostController = TextEditingController();
  late TabController _tabController;
  File? _selectedImage;
  bool _isEditingImage = false;
  String? _editedImageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadForumPosts();
  }

  Future<void> _loadForumPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading forum posts
      await Future.delayed(const Duration(seconds: 1));
      
      // This would typically fetch from a real service
      final posts = ForumService.getMockPosts();
      
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading forum posts: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _editImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isEditingImage = true;
    });
    
    // This would be replaced with proper image editing implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate edited image URL (in a real app this would be the actual edited image)
    setState(() {
      _editedImageUrl = _selectedImage!.path;
      _isEditingImage = false;
    });
  }
  
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _editedImageUrl = null;
    });
  }

  Future<void> _createNewPost(String content) async {
    if (content.trim().isEmpty && _selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // This would typically create a post through a service
      final newPost = await ForumService.createPost(
        content, 
        _selectedImage != null ? _editedImageUrl ?? _selectedImage!.path : null
      );
      setState(() {
        _posts.insert(0, newPost);
        _isLoading = false;
        _selectedImage = null;
        _editedImageUrl = null;
      });
      _newPostController.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error creating post: $e');
    }
  }

  @override
  void dispose() {
    _newPostController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<ForumPost> _getFilteredPosts(String category) {
    if (category == 'all') {
      return _posts;
    }
    return _posts.where((post) => post.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cyclingForum),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.general),
            Tab(text: l10n.routeTips),
            Tab(text: l10n.equipment),
            Tab(text: l10n.events),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // New post input area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPostController,
                        decoration: InputDecoration(
                          hintText: l10n.writeNewPost,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _createNewPost(_newPostController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.post),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          tooltip: 'Add image from gallery',
                          color: Colors.green,
                        ),
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          tooltip: 'Take a photo',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Image preview and edit options
                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: _isEditingImage
                                  ? const Center(child: CircularProgressIndicator())
                                  : Image.file(_selectedImage!),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _removeImage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: Text('Edit Image'),
                              onPressed: _editImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Posts list inside TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // General tab
                _buildPostsList('general'),
                // Route Tips tab
                _buildPostsList('routeTips'),
                // Equipment tab
                _buildPostsList('equipment'),
                // Events tab
                _buildPostsList('events'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPostsList(String category) {
    final filteredPosts = _getFilteredPosts(category);
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (filteredPosts.isEmpty) {
      return Center(child: Text(l10n.noPostsYet));
    }
    
    return ListView.builder(
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return ForumPostCard(post: post);
      },
    );
  }
}

class ForumPostCard extends StatelessWidget {
  final ForumPost post;

  const ForumPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorPhotoUrl != null 
                      ? NetworkImage(post.authorPhotoUrl!) 
                      : null,
                  child: post.authorPhotoUrl == null 
                      ? Text(post.authorName[0]) 
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${post.timePosted.day}/${post.timePosted.month}/${post.timePosted.year} ${post.timePosted.hour}:${post.timePosted.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content),
            
            // Display post image if available
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    errorBuilder: (context, error, stackTrace) => 
                      Image.file(File(post.imageUrl!)),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('${post.likes} ${l10n.likes}'),
                  onPressed: () {},
                ),
                TextButton.icon(
                  icon: const Icon(Icons.comment_outlined, size: 16),
                  label: Text('${post.comments} ${l10n.comments}'),
                  onPressed: () {},
                ),
                TextButton.icon(
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: Text(l10n.share),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
