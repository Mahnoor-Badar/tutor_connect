import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String tutorId;
  final String studentId;
  final String studentName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.tutorId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookingId: map['bookingId'] ?? '',
      tutorId: map['tutorId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Student',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}