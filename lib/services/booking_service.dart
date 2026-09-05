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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // --------------------------------------------------
    // 1. GET STUDENT PROFILE
    // --------------------------------------------------

    final userSnapshot =
        await _db.collection('users').doc(user.uid).get();

    final userData =
        userSnapshot.data() ?? <String, dynamic>{};

    final studentName =
        userData['name'] ??
        user.displayName ??
        'Student';

    final studentEmail =
        userData['email'] ??
        user.email ??
        '';

    final studentContact =
        userData['contact'] ??
        '';

    // --------------------------------------------------
    // 2. CHECK TUTOR SLOT
    // --------------------------------------------------

    final bookingDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final clash = await _db
        .collection('bookings')
        .where(
          'tutorId',
          isEqualTo: tutorId,
        )
        .where(
          'date',
          isEqualTo: Timestamp.fromDate(bookingDate),
        )
        .where(
          'time',
          isEqualTo: time,
        )
        .where(
          'status',
          isEqualTo: 'accepted',
        )
        .get();

    if (clash.docs.isNotEmpty) {
      throw Exception(
        'This slot is already booked. Please pick another time.',
      );
    }

    // --------------------------------------------------
    // 3. CREATE BOOKING REQUEST
    // --------------------------------------------------

    await _db.collection('bookings').add({
      // Student information
      'studentId': user.uid,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentContact': studentContact,

      // Tutor
      'tutorId': tutorId,

      // Session information
      'subject': subject,
      'date': Timestamp.fromDate(bookingDate),
      'time': time,
      'sessionType': sessionType,

      // Booking status
      'status': 'pending',

      // Messages
      'studentMessage': studentMessage,
      'tutorMessage': '',

      // ------------------------------------------------
      // PAYMENT
      // ------------------------------------------------

      // Payment is optional when request is created.
      'paymentStatus': 'unpaid',
      'paymentType': 'none',
      'amount': 0.0,

      // ------------------------------------------------
      // SESSION / CONTRACT
      // ------------------------------------------------

      'sessionsExpected': 0,
      'sessionsCompleted': 0,

      'contractStartDate': null,
      'contractEndDate': null,

      // Timestamp
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}