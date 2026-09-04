import 'package:cloud_firestore/cloud_firestore.dart';

class SessionNote {
  final String id;
  final String studentId;
  final String tutorId;
  final String bookingId;
  final String notes;
  final DateTime createdAt;

  SessionNote({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.bookingId,
    required this.notes,
    required this.createdAt,
  });

  factory SessionNote.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SessionNote(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      tutorId: data['tutorId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'tutorId': tutorId,
      'bookingId': bookingId,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}