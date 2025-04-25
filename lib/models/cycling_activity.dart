import 'package:intl/intl.dart';

class CyclingActivity {
  final String id;
  final String userId;
  final double distance;
  final int pointsEarned;
  final DateTime date;
  
  CyclingActivity({
    required this.id,
    required this.userId,
    required this.distance,
    required this.pointsEarned,
    required this.date,
  });
  
  String get formattedDate {
    return DateFormat('MMM d, y').format(date);
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'distance': distance,
      'pointsEarned': pointsEarned,
      'date': date.toIso8601String(),
    };
  }
  
  factory CyclingActivity.fromMap(Map<String, dynamic> map) {
    return CyclingActivity(
      id: map['id'],
      userId: map['userId'],
      distance: map['distance'],
      pointsEarned: map['pointsEarned'],
      date: DateTime.parse(map['date']),
    );
  }
}
