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

    final startOfMonth = DateTime(now.year, now.month, 1);

    final startTimestamp = Timestamp.fromDate(startOfMonth);

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

      if (studentId != null && studentId.toString().isNotEmpty) {
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
        .collection('bookings')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .get();

    return snapshot.docs.length;
  }

  // ============================================================
  // STUDENT-WISE EARNINGS
  // ============================================================

  Future<List<Map<String, dynamic>>> getStudentEarnings() async {
    // ----------------------------------------------------------
    // 1. Get paid transactions for earnings
    // ----------------------------------------------------------

    final transactionSnapshot = await _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .get();

    // ----------------------------------------------------------
    // 2. Get completed bookings for session counts
    // ----------------------------------------------------------

    final bookingSnapshot = await _db
        .collection('bookings')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .get();

    final Map<String, Map<String, dynamic>> studentMap = {};

    // ----------------------------------------------------------
    // 3. Build earnings from transactions
    // ----------------------------------------------------------

    for (final doc in transactionSnapshot.docs) {
      final data = doc.data();

      final studentId = data['studentId']?.toString() ?? '';

      final studentName =
          data['studentName']?.toString() ?? 'Student';

      final amount = (data['amount'] ?? 0).toDouble();

      if (studentId.isEmpty) {
        continue;
      }

      if (!studentMap.containsKey(studentId)) {
        studentMap[studentId] = {
          'studentId': studentId,
          'studentName': studentName,
          'totalEarnings': 0.0,
          'sessions': 0,
        };
      }

      studentMap[studentId]!['totalEarnings'] =
          (studentMap[studentId]!['totalEarnings'] as double) + amount;
    }

    // ----------------------------------------------------------
    // 4. Add actual completed session counts
    // ----------------------------------------------------------

    for (final doc in bookingSnapshot.docs) {
      final data = doc.data();

      final studentId = data['studentId']?.toString() ?? '';

      if (studentId.isEmpty) {
        continue;
      }

      // A student may have completed sessions even if
      // the transaction was created only at contract completion.
      if (!studentMap.containsKey(studentId)) {
        studentMap[studentId] = {
          'studentId': studentId,
          'studentName':
              data['studentName']?.toString() ?? 'Student',
          'totalEarnings': 0.0,
          'sessions': 0,
        };
      }

      studentMap[studentId]!['sessions'] =
          (studentMap[studentId]!['sessions'] as int) + 1;
    }

    // ----------------------------------------------------------
    // 5. Sort highest earning students first
    // ----------------------------------------------------------

    final result = studentMap.values.toList();

    result.sort(
      (a, b) => (b['totalEarnings'] as double).compareTo(
        a['totalEarnings'] as double,
      ),
    );

    return result;
  }

  // ============================================================
  // ACTIVE CONTRACTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveContracts() {
    return _db
        .collection('contracts')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // ============================================================
  // ALL TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTransactions() {
    return _db
        .collection('transactions')
        .where('tutorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'paid')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}