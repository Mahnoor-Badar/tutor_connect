import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, accepted, declined, completed, cancelled }

enum SessionType { runtime, monthly }


class Booking {
  final String id;
  final String studentId;
  final String studentName;
  final String tutorId;
  final String subject;
  final DateTime date;
  final String time;
  final SessionType sessionType;
  final BookingStatus status;
  final String studentMessage;
  final String tutorMessage;
  final bool isPaid;

  Booking({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.tutorId,
    required this.subject,
    required this.date,
    required this.time,
    required this.sessionType,
    required this.status,
    this.studentMessage = '',
    this.tutorMessage = '',
    this.isPaid = false,
  });

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      tutorId: map['tutorId'] ?? '',
      subject: map['subject'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      sessionType: (map['sessionType'] == 'monthly')
          ? SessionType.monthly
          : SessionType.runtime,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      studentMessage: map['studentMessage'] ?? '',
      tutorMessage: map['tutorMessage'] ?? '',
      isPaid: map['isPaid'] ?? false,
    );
  }
}