import 'package:cloud_firestore/cloud_firestore.dart';


class TutorProfile {
  final String uid;
  final String name;
  final String bio;
  final List<String> subjects;
  final String city;
  final String photoUrl;
  final double avgRating;
  final int reviewCount;

  TutorProfile({
    required this.uid,
    required this.name,
    required this.bio,
    required this.subjects,
    required this.city,
    required this.photoUrl,
    this.avgRating = 0.0,
    this.reviewCount = 0,
  });

  factory TutorProfile.fromMap(String uid, Map<String, dynamic> map) {
    return TutorProfile(
      uid: uid,
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      subjects: List<String>.from(map['subjects'] ?? []),
      city: map['city'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      avgRating: (map['avgRating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'subjects': subjects,
      'city': city,
      'photoUrl': photoUrl,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'role': 'tutor',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}