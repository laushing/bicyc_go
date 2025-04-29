import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../models/forum_post_model.dart';
import '../services/forum_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

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
    
    try {
      if (!mounted) return; 

      // Create a callback with explicit void return type
      final callbacks = ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          // Just pop with the bytes, don't return anything
          Navigator.pop(context, bytes);
        },
      );

      final editedImageBytes = await Navigator.push<Uint8List?>(
        context,
        MaterialPageRoute(
          builder: (builderContext) => ProImageEditor.file(
            _selectedImage!,
            callbacks: callbacks,
          ),
        ),
      );

      // 3. Early return if no longer mounted or no bytes returned
      if (!mounted || editedImageBytes == null) {
        print('Image editing cancelled or failed.');
        return;
      }

      // Show loading indicator while processing the image
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing edited image...'), duration: Duration(seconds: 1)),
        );
      }

      // 4. Process the edited image
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
        final editedFile = await File(path).writeAsBytes(editedImageBytes); 
        
        // 5. Final mounted check before setState
        if (!mounted) return;
        
        // 6. Update the state
        setState(() {
          _selectedImage = editedFile;
        });
        
        // Add confirmation message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image edited successfully')),
          );
        }
        
        print('Image edited successfully. New path: ${_selectedImage?.path}');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save edited image: $e')),
          );
        }
      }
      
    } catch (e, s) {
      print('Error in image editor: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit image: $e')),
        );
      }
    }
  }
  
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createNewPost(String content) async {
    // Ensure content or image exists
    if (content.trim().isEmpty && _selectedImage == null) {
      print('Cannot create post: Both content and image are empty/null');
      // Show user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter text or select an image to post')),
        );
      }
      return;
    }

    // Store the image path *before* clearing _selectedImage later
    final String? imagePath = _selectedImage?.path; 
    print('--- _createNewPost ---');
    print('_selectedImage object: ${_selectedImage != null ? "exists" : "is null"}');
    print('Image path being sent to service: $imagePath');

    // Improved image handling for reliability
    String? finalImagePath;
    if (imagePath != null) {
      try {
        // First, check if the original file exists
        final originalFile = File(imagePath);
        if (!await originalFile.exists()) {
          print('Original image file does not exist: $imagePath');
          // Proceed without an image
        } else {
          // Read image into memory
          final imageBytes = await originalFile.readAsBytes();
          
          // Try multiple strategies to save the image persistently
          finalImagePath = await _saveImageWithFallbacks(imageBytes, imagePath);
          
          if (finalImagePath != null) {
            print('Final image path for post: $finalImagePath');
          } else {
            print('Failed to save image. Proceeding without image.');
          }
        }
      } catch (e) {
        print('Error preparing image for post: $e');
        // Continue without the image rather than failing the whole post
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use finalImagePath which is either null or a valid path to a saved image
      final newPost = await ForumService.createPost(
        content, 
        finalImagePath
      );
      
      print('Image URL received from service in newPost: ${newPost.imageUrl}');

      // Check if mounted before updating state after async gap
      if (!mounted) return; 

      // Ensure the image path is accessible in the post
      if (newPost.imageUrl != null) {
        // Verify the file exists at the path stored in newPost
        final exists = await File(newPost.imageUrl!).exists();
        print('Does post image file exist? $exists (path: ${newPost.imageUrl})');
      }

      setState(() {
        _posts.insert(0, newPost); // Add the new post
        _isLoading = false;
        _selectedImage = null; // Clear the selected image for the next post
      });
      _newPostController.clear(); // Clear the text field
      print('--- Post created and state updated ---');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      // Check if mounted before updating state or showing SnackBar
      if (!mounted) return; 
      setState(() {
        _isLoading = false;
      });
      print('Error creating post: $e');
      // Optionally show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    }
  }
  
  // Helper method to try multiple image saving strategies
  Future<String?> _saveImageWithFallbacks(Uint8List imageBytes, String originalPath) async {
    // Strategy 1: Save to application documents directory (most reliable)
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'post_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final destination = File('${appDir.path}/$fileName');
      
      await destination.writeAsBytes(imageBytes);
      print('Successfully saved image to app documents: ${destination.path}');
      return destination.path;
    } catch (e) {
      print('Strategy 1 failed: $e');
    }
    
    // Strategy 2: Save to cache directory (less reliable but still useful)
    try {
      final cacheDir = await getTemporaryDirectory();
      final fileName = 'post_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final destination = File('${cacheDir.path}/$fileName');
      
      await destination.writeAsBytes(imageBytes);
      print('Successfully saved image to cache: ${destination.path}');
      return destination.path;
    } catch (e) {
      print('Strategy 2 failed: $e');
    }
    
    // Strategy 3: Try to use the original path if it's still valid
    try {
      final originalFile = File(originalPath);
      if (await originalFile.exists()) {
        print('Using original file path: $originalPath');
        return originalPath;
      }
    } catch (e) {
      print('Strategy 3 failed: $e');
    }
    
    // All strategies failed
    return null;
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
                              child: Image.file(_selectedImage!),
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
    print('--- ForumPostCard Build ---'); 
    print('Building card for post by ${post.authorName}, imageUrl: ${post.imageUrl}'); 
    
    // Determine if the imageUrl is likely a local file path
    final bool isLocalPath = post.imageUrl != null && post.imageUrl!.startsWith('/'); 

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
                  // --- Updated Image Loading Logic ---
                  child: isLocalPath 
                    ? _buildLocalImage(post.imageUrl!) // Try loading as local file first
                    : Image.network( // Fallback to network image
                        post.imageUrl!,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image.network failed for ${post.imageUrl}. Error: $error'); 
                          // If network fails, maybe it was intended as local? (Less likely now)
                          return _buildLocalImage(post.imageUrl!); 
                        },
                      ),
                  // --- End of Updated Logic ---
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

  // Helper widget to load local image with existence check and error handling
  Widget _buildLocalImage(String path) {
    print('Attempting to load local image: $path');
    try {
      final file = File(path);
      if (file.existsSync()) {
        print('File exists. Loading Image.file: $path');
        return Image.file(file);
      } else {
        print('File does not exist at path: $path');
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey); 
      }
    } catch (e) {
      print('Error loading local image ($path): $e');
      return const Icon(Icons.error_outline, size: 50, color: Colors.red);
    }
  }
}
