import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

final notificationListProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.id, doc.data()))
          .toList());
});

final unreadCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> clearAllNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}