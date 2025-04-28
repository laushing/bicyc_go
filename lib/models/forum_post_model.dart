class ForumPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String? imageUrl;
  final DateTime timePosted;
  final int likes;
  final int comments;
  final String category;

  ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.imageUrl,
    required this.timePosted,
    this.likes = 0,
    this.comments = 0,
    required this.category,
  });

  ForumPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    String? imageUrl,
    DateTime? timePosted,
    int? likes,
    int? comments,
    String? category,
  }) {
    return ForumPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timePosted: timePosted ?? this.timePosted,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      category: category ?? this.category,
    );
  }
}
