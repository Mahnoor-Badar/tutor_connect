import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ============================================================
  // TOTAL EARNINGS
  // ============================================================

  Future<double> getTotalEarnings() async {
    final snapshot = await _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .get();

    double total = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      total += (data['amount'] ?? 0).toDouble();
    }

    return total;
  }

  // ============================================================
  // CURRENT MONTH EARNINGS
  // ============================================================

  Future<double> getMonthlyEarnings() async {
    final now = DateTime.now();

    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final startTimestamp =
        Timestamp.fromDate(startOfMonth);

    final snapshot = await _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: startTimestamp,
        )
        .get();

    double total = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      total += (data['amount'] ?? 0).toDouble();
    }

    return total;
  }

  // ============================================================
  // TOTAL STUDENTS
  // ============================================================

  Future<int> getTotalStudents() async {
    final snapshot = await _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .get();

    final studentIds = <String>{};

    for (final doc in snapshot.docs) {
      final studentId = doc.data()['studentId'];

      if (studentId != null &&
          studentId.toString().isNotEmpty) {
        studentIds.add(studentId.toString());
      }
    }

    return studentIds.length;
  }

  // ============================================================
  // TOTAL COMPLETED SESSIONS
  // ============================================================

  Future<int> getCompletedSessions() async {
    final snapshot = await _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .get();

    return snapshot.docs.length;
  }

  // ============================================================
  // ACTIVE CONTRACTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveContracts() {
    return _db
        .collection('contracts')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // ============================================================
  // ALL TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchTransactions() {
    return _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}