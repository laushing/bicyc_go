class User {
  final String id;
  String name;
  String? photoUrl;
  double totalDistance;
  int achievementCount;
  String? favoriteRoute;
  late final int rewardPoints;
  List<String>? connections; // IDs of connected users
  List<ConnectionRequest>? connectionRequests;

  User({
    required this.id,
    required this.name,
    this.photoUrl,
    this.totalDistance = 0,
    this.achievementCount = 0,
    this.favoriteRoute,
    required this.rewardPoints,
    this.connections,
    this.connectionRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'totalDistance': totalDistance,
      'achievementCount': achievementCount,
      'favoriteRoute': favoriteRoute,
      'connections': connections,
      'connectionRequests': connectionRequests?.map((request) => request.toJson()).toList(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      totalDistance: (json['totalDistance'] ?? 0).toDouble(), // Fix type error by explicit conversion to double
      achievementCount: json['achievementCount'] ?? 0,
      favoriteRoute: json['favoriteRoute'],
      rewardPoints: json['rewardPoints'] ?? 0,
      connections: (json['connections'] as List<dynamic>?)?.map((id) => id as String).toList(),
      connectionRequests: (json['connectionRequests'] as List<dynamic>?)
          ?.map((request) => ConnectionRequest.fromJson(request))
          .toList(),
    );
  }
}

class ConnectionRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhotoUrl;
  final DateTime requestDate;

  ConnectionRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhotoUrl,
    required this.requestDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'requestDate': requestDate.toIso8601String(),
    };
  }

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      id: json['id'],
      fromUserId: json['fromUserId'],
      fromUserName: json['fromUserName'],
      fromUserPhotoUrl: json['fromUserPhotoUrl'],
      requestDate: DateTime.parse(json['requestDate']),
    );
  }
}
