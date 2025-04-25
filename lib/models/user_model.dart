class User {
  final String id;
  String name;
  String? photoUrl;
  int totalDistance;
  int achievementCount;
  String favoriteRoute;
  late final int rewardPoints;

  User({
    required this.id,
    required this.name,
    this.photoUrl,
    this.totalDistance = 0,
    this.achievementCount = 0,
    this.favoriteRoute = 'None',
    required this.rewardPoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'totalDistance': totalDistance,
      'achievementCount': achievementCount,
      'favoriteRoute': favoriteRoute,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      totalDistance: json['totalDistance'] ?? 0,
      achievementCount: json['achievementCount'] ?? 0,
      favoriteRoute: json['favoriteRoute'] ?? 'None',
      rewardPoints: json['rewardPoints'] ?? 0,
    );
  }
}
