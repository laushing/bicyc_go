import '../models/forum_post_model.dart';
import 'user_service.dart';

class ForumService {
  // Get mock forum posts for now - in a real app, this would fetch from a database
  static List<ForumPost> getMockPosts() {
    return [
      ForumPost(
        id: '1',
        authorId: 'user1',
        authorName: 'John Cyclist',
        content: 'Found a great new trail near Victoria Park yesterday. Perfect for morning rides!',
        timePosted: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 12,
        comments: 3,
        category: 'general',
      ),
      ForumPost(
        id: '2',
        authorId: 'user2',
        authorName: 'Sarah Rider',
        content: 'Anyone have recommendations for cycling gloves that work well in hot weather?',
        timePosted: DateTime.now().subtract(const Duration(hours: 8)),
        likes: 7,
        comments: 9,
        category: 'equipment',
      ),
      ForumPost(
        id: '3',
        authorId: 'user3',
        authorName: 'Mike Pedals',
        content: 'Planning a group ride this Saturday around Tolo Harbour. Anyone interested in joining?',
        timePosted: DateTime.now().subtract(const Duration(days: 1)),
        likes: 24,
        comments: 15,
        category: 'events',
      ),
      ForumPost(
        id: '4',
        authorId: 'user4',
        authorName: 'Lisa Wheeler',
        content: 'Tip for those cycling up to The Peak: take the road from Pokfulam for a more gradual climb.',
        timePosted: DateTime.now().subtract(const Duration(days: 2)),
        likes: 18,
        comments: 5,
        category: 'routeTips',
      ),
      ForumPost(
        id: '5',
        authorId: 'user5',
        authorName: 'David Spokes',
        content: 'Just got the new Giant TCR Advanced - absolute game changer for my daily commute!',
        timePosted: DateTime.now().subtract(const Duration(days: 3)),
        likes: 32,
        comments: 7,
        category: 'equipment',
      ),
    ];
  }

  // Create a new forum post - in a real app, this would save to a database
  static Future<ForumPost> createPost(String content) async {
    // Get current user for author details
    final currentUser = await UserService.getCurrentUser();
    
    // Generate a random ID - in a real app, this would be handled by the database
    final String postId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create and return a new post
    return ForumPost(
      id: postId,
      authorId: currentUser?.id ?? 'unknown',
      authorName: currentUser?.name ?? 'Anonymous Cyclist',
      authorPhotoUrl: currentUser?.photoUrl,
      content: content,
      timePosted: DateTime.now(),
      category: 'general', // Default category
    );
  }
}
