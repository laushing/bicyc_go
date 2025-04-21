class CyclingRoute {
  final String id;
  final String name;
  final String description;
  final double distance;
  final int estimatedTimeMinutes;
  final String difficulty;
  final List<List<double>> coordinates;
  final String imageUrl;

  CyclingRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.distance,
    required this.estimatedTimeMinutes,
    required this.difficulty,
    required this.coordinates,
    required this.imageUrl,
  });

  // Add methods for JSON serialization
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

  // Create a route from JSON
  factory CyclingRoute.fromJson(Map<String, dynamic> json) {
    return CyclingRoute(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      distance: json['distance'].toDouble(),
      estimatedTimeMinutes: json['estimatedTimeMinutes'],
      difficulty: json['difficulty'],
      coordinates: (json['coordinates'] as List)
          .map((coordList) => (coordList as List).cast<double>())
          .toList(),
      imageUrl: json['imageUrl'],
    );
  }
}
