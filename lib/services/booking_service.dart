import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class BookingService {
  final _db = FirebaseFirestore.instance;

  Future<void> createBooking({
    required String tutorId,
    required String subject,
    required DateTime date,
    required String time,
    required String sessionType, // 'runtime' or 'monthly'
    String studentMessage = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser!;

    // Prevent booking a slot the tutor has already accepted elsewhere.
    final clash = await _db
        .collection('bookings')
        .where('tutorId', isEqualTo: tutorId)
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
        .where('time', isEqualTo: time)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (clash.docs.isNotEmpty) {
      throw Exception('This slot is already booked. Please pick another time.');
    }

    await _db.collection('bookings').add({
      'studentId': user.uid,
      'studentName': user.displayName ?? 'Student',
      'tutorId': tutorId,
      'subject': subject,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'time': time,
      'sessionType': sessionType,
      'status': 'pending',
      'studentMessage': studentMessage,
      'tutorMessage': '',
      'isPaid': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}