import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_note.dart';

class SessionNoteService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveNote({
    required String bookingId,
    required String tutorId,
    required String notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    await _db.collection('session_notes').add({
      'studentId': user.uid,
      'tutorId': tutorId,
      'bookingId': bookingId,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SessionNote>> watchNotes(String bookingId) {
    return _db
        .collection('session_notes')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SessionNote.fromDoc(doc))
              .toList(),
        );
  }
}