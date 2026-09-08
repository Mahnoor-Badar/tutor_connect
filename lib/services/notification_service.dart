import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
  }) async {
    await _db.collection('notifications').add({
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> watchNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}