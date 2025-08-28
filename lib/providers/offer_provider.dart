import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';

final activeOffersProvider = StreamProvider<List<OfferModel>>((ref) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('offers')
      .where('isActive', isEqualTo: true)
      .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc))
          .toList());
});

final restaurantOffersProvider = StreamProvider.family<List<OfferModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('offers')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc))
          .toList());
});

final offerProvider = StreamProvider.family<OfferModel?, String>((ref, offerId) {
  return FirebaseFirestore.instance
      .collection('offers')
      .doc(offerId)
      .snapshots()
      .map((doc) => doc.exists ? OfferModel.fromFirestore(doc) : null);
});

final offerManagementProvider = StateNotifierProvider<OfferManagementNotifier, AsyncValue<void>>((ref) {
  return OfferManagementNotifier();
});

class OfferManagementNotifier extends StateNotifier<AsyncValue<void>> {
  OfferManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOffer(OfferModel offer) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('offers')
          .add(offer.toFirestore());
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateOffer(String offerId, Map<String, dynamic> updates) async {
    try {
      state = const AsyncValue.loading();
      
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update(updates);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('offers')
          .doc(offerId)
          .delete();
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleOfferStatus(String offerId, bool isActive) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('offers').doc(offerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> incrementOfferUsage(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Don't throw error for usage tracking
    }
  }

  Future<List<OfferModel>> getValidOffersForOrder(
    String restaurantId,
    double orderTotal,
    List<String> itemIds,
  ) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('offers')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final offers = snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc))
          .where((offer) {
            // Check minimum order requirement
            if (orderTotal < offer.minimumOrder) return false;
            
            // Check usage limit
            if (offer.usageLimit > 0 && offer.usageCount >= offer.usageLimit) {
              return false;
            }
            
            // Check applicable items (if specified)
            if (offer.applicableItems.isNotEmpty) {
              return offer.applicableItems.any((itemId) => itemIds.contains(itemId));
            }
            
            return true;
          })
          .toList();

      return offers;
    } catch (e) {
      rethrow;
    }
  }
}