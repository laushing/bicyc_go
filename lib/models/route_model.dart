class CyclingRoute {
  final String id;
  final String name;
  final String description;
  final double distance;
  final int estimatedTimeMinutes;
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<List<double>> coordinates; // List of [lat, lng] points
  final String imageUrl;

  CyclingRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.distance,
    required this.estimatedTimeMinutes,
    required this.difficulty,
    required this.coordinates,
    this.imageUrl = '',
  });

  // Convert to/from JSON
  factory CyclingRoute.fromJson(Map<String, dynamic> json) {
    return CyclingRoute(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      distance: json['distance'].toDouble(),
      estimatedTimeMinutes: json['estimatedTimeMinutes'],
      difficulty: json['difficulty'],
      coordinates: List<List<double>>.from(
        json['coordinates'].map((point) => List<double>.from(point)),
      ),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'distance': distance,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'difficulty': difficulty,
      'coordinates': coordinates,
      'imageUrl': imageUrl,
    };
  }
}
